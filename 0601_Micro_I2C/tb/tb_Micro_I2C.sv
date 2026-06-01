`include "uvm_macros.svh"
import uvm_pkg::*;


interface axi_i2c_if (
    input bit clk,
    input bit rst_n
);
    logic [3:0] awaddr;
    logic [2:0] awprot;
    logic awvalid;
    logic awready;
    logic [31:0] wdata;
    logic [3:0] wstrb;
    logic wvalid;
    logic wready;
    logic [1:0] bresp;
    logic bvalid;
    logic bready;
    logic [3:0] araddr;
    logic [2:0] arprot;
    logic arvalid;
    logic arready;
    logic [31:0] rdata;
    logic [1:0] rresp;
    logic rvalid;
    logic rready;

    logic [7:0] slave_tx_data;  // Slave가 마스터로 보낼 데이터
    logic [7:0] slave_rx_data;  // Master가 보낸 데이터
endinterface


class axi_i2c_seq_item extends uvm_sequence_item;
    rand logic [7:0] tx_data_m;  // Master TX
    rand logic [7:0] tx_data_s;  // Slave TX

    logic      [7:0] rx_data_m;  // Master RX
    logic      [7:0] rx_data_s;  // Slave RX

    `uvm_object_utils_begin(axi_i2c_seq_item)
        `uvm_field_int(tx_data_m, UVM_ALL_ON)
        `uvm_field_int(tx_data_s, UVM_ALL_ON)
        `uvm_field_int(rx_data_m, UVM_ALL_ON)
        `uvm_field_int(rx_data_s, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_i2c_seq_item");
        super.new(name);
    endfunction
endclass


class axi_i2c_seq extends uvm_sequence #(axi_i2c_seq_item);
    `uvm_object_utils(axi_i2c_seq)
    int num_trans = 1000;

    function new(string name = "axi_i2c_seq");
        super.new(name);
    endfunction

    task body();
        axi_i2c_seq_item item;
        repeat (num_trans) begin
            item = axi_i2c_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize()) `uvm_fatal("SEQ", "Randomize failed")
            finish_item(item);
        end
    endtask
endclass

class axi_i2c_driver extends uvm_driver #(axi_i2c_seq_item);
    `uvm_component_utils(axi_i2c_driver)
    virtual axi_i2c_if vif;

    function new(string name = "axi_i2c_drv", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Cannot access interface")
    endfunction

    task axi_write(input [3:0] addr, input [31:0] data);
        @(posedge vif.clk);
        vif.awaddr  <= addr;
        vif.awvalid <= 1;
        vif.wdata   <= data;
        vif.wstrb   <= 4'hF;
        vif.wvalid  <= 1;
        wait (vif.awready && vif.wready);
        @(posedge vif.clk);
        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.bready  <= 1;
        wait (vif.bvalid);
        @(posedge vif.clk);
        vif.bready <= 0;
    endtask

    task axi_read(input [3:0] addr, output [31:0] data);
        @(posedge vif.clk);
        vif.araddr  <= addr;
        vif.arvalid <= 1;
        wait (vif.arready);
        @(posedge vif.clk);
        vif.arvalid <= 0;
        vif.rready  <= 1;
        wait (vif.rvalid);
        data = vif.rdata;
        @(posedge vif.clk);
        vif.rready <= 0;
    endtask

    // 이중 실행을 막기 위한 펄스 형태의 명령어 인가
    task execute_cmd(input [4:0] cmd, input [7:0] tx_val = 0,
                     input bit has_tx = 0);
        logic [31:0] rdata;

        if (has_tx) begin
            axi_write(4'h4, {24'h0, tx_val});
        end

        // 1. 명령어 쓰기
        axi_write(4'h0, {27'h0, cmd});

        // 2. 즉시 명령어 지우기 (RTL의 이중 실행 방지)
        // AXI write가 수 사이클 걸리므로, Master(RTL)는 WAIT_CMD 상태에서 이 명령을 
        // 1클럭 이상 감지하여 정상 동작을 시작하고, 이후 0으로 지워져서 두 번 실행되지 않습니다.
        axi_write(4'h0, 32'h0);

        // 3. 명령이 완료될 때까지 대기
        do begin
            axi_read(4'hC, rdata);
        end while ((rdata & 2'b10) == 0);

        repeat (5) @(posedge vif.clk);
    endtask

    virtual task run_phase(uvm_phase phase);
        axi_i2c_seq_item item;
        logic [31:0] rdata;

        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.bready  <= 0;
        vif.arvalid <= 0;
        vif.rready  <= 0;
        wait (vif.rst_n == 1);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(item);
            vif.slave_tx_data <= item.tx_data_s;


            // [Master Write 통신]

            execute_cmd(5'b00001);  // 1. START
            execute_cmd(5'b00010, 8'h24, 1);  // 2. WRITE: Slave Addr
            execute_cmd(5'b00010, item.tx_data_m,
                        1);  // 3. WRITE: 데이터 페이로드 (has_tx=1)
            execute_cmd(5'b01000);  // 4. STOP

            repeat (50) @(posedge vif.clk);


            // [Master Read 통신]

            execute_cmd(5'b00001);  // 5. START
            execute_cmd(5'b00010, 8'h25,
                        1);  // 6. WRITE: Slave Addr + Read 모드

            //  [핵심 수정] 5'b00100 -> 5'b10100 (Bit 4를 1로 설정하여 NACK 전송)
            execute_cmd(
                5'b10100);                            // 7. READ : 데이터 수신 후 슬레이브에게 NACK 전송

            execute_cmd(5'b01000);  // 8. STOP
            repeat (50) @(posedge vif.clk);

            // 최종 수신 데이터 캡처
            axi_read(4'h8, rdata);
            item.rx_data_m = rdata[7:0];
            item.rx_data_s = vif.slave_rx_data;

            seq_item_port.item_done();
        end
    endtask
endclass


class axi_i2c_monitor extends uvm_monitor;
    `uvm_component_utils(axi_i2c_monitor)
    virtual axi_i2c_if vif;
    uvm_analysis_port #(axi_i2c_seq_item) ap;

    function new(string name = "axi_i2c_mon", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_i2c_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Cannot access interface")
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [7:0] current_reg4;
        logic [7:0] tx_m_tracker;
        bit after_start = 0; // START 명령어 직후인지 추적하는 플래그

        forever begin
            @(posedge vif.clk);

            // 1. 0x4 레지스터에 기록되는 값은 무조건 업데이트 해둠
            if (vif.awvalid && vif.awready && vif.awaddr == 4'h4 && vif.wvalid && vif.wready) begin
                current_reg4 = vif.wdata[7:0];
            end

            // 2. 0x0 레지스터에 명령어가 쓰일 때, I2C 통신 순서를 바탕으로 데이터 성격 파악
            if (vif.awvalid && vif.awready && vif.awaddr == 4'h0 && vif.wvalid && vif.wready) begin
                logic [4:0] cmd = vif.wdata[4:0];

                if (cmd == 5'b00001) begin
                    // START 명령어 실행됨
                    after_start = 1;
                end else if (cmd == 5'b00010) begin
                    // WRITE 명령어 실행됨
                    if (after_start == 1) begin
                        // START 직후의 첫 번째 WRITE는 "Slave Address" 이므로 무시
                        after_start = 0;
                    end else begin
                        // 그 다음 이어지는 WRITE는 무조건 진짜 "Payload Data" 이므로 캡처!
                        tx_m_tracker = current_reg4;
                    end
                end
            end

            // 3. 트랜잭션 종료 시점(0x8 Read)에서 최종 데이터 스코어보드로 전송
            if (vif.rvalid && vif.rready && vif.araddr == 4'h8) begin
                axi_i2c_seq_item item = axi_i2c_seq_item::type_id::create(
                    "item"
                );
                item.tx_data_m = tx_m_tracker;
                item.tx_data_s = vif.slave_tx_data;
                item.rx_data_m = vif.rdata[7:0];
                item.rx_data_s = vif.slave_rx_data;
                ap.write(item);
            end
        end
    endtask
endclass


class axi_i2c_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_i2c_scoreboard)
    uvm_analysis_imp #(axi_i2c_seq_item, axi_i2c_scoreboard) ap_imp;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(string name = "axi_i2c_scb", uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(axi_i2c_seq_item item);
        bit tx_match = (item.tx_data_m == item.rx_data_s);
        bit rx_match = (item.tx_data_s == item.rx_data_m);

        `uvm_info("SCB_DATA_CHECK", $sformatf(
                  "\n--------------------------------------------------\n [Master TX] 0x%0h  ==>  [Slave  RX] 0x%0h  (%s)\n [Slave  TX] 0x%0h  ==>  [Master RX] 0x%0h  (%s)\n--------------------------------------------------",
                  item.tx_data_m,
                  item.rx_data_s,
                  tx_match ? "PASS" : "FAIL",
                  item.tx_data_s,
                  item.rx_data_m,
                  rx_match ? "PASS" : "FAIL"
                  ), UVM_MEDIUM)

        if (tx_match && rx_match) begin
            pass_cnt++;
        end else begin
            fail_cnt++;
            `uvm_error("SCB_MISMATCH",
                       "데이터 불일치가 발생하였습니다.")
        end
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCB_FINAL",
                  "\n\n================ 전체 검증 요약 ================",
                  UVM_LOW)
        `uvm_info("SCB_FINAL", $sformatf(
                  "  총 테스트 횟수 : %0d 회", pass_cnt + fail_cnt),
                  UVM_LOW)
        `uvm_info("SCB_FINAL", $sformatf(
                  "  성공(MATCH)    : %0d 회", pass_cnt), UVM_LOW)
        `uvm_info("SCB_FINAL", $sformatf(
                  "  실패(MISMATCH) : %0d 회", fail_cnt), UVM_LOW)
        `uvm_info("SCB_FINAL",
                  "================================================\n", UVM_LOW)
    endfunction
endclass

class axi_i2c_coverage extends uvm_subscriber #(axi_i2c_seq_item);
    `uvm_component_utils(axi_i2c_coverage)

    logic [7:0] cov_tx_data_m, cov_tx_data_s;

    covergroup cg_data;
        cp_tx_data_m: coverpoint cov_tx_data_m {
            bins zero = {8'h00};
            bins alt_01 = {8'h55};
            bins alt_10 = {8'haa};
            bins lsb_only = {8'h01};
            bins msb_only = {8'h80};
            bins range0 = {[8'h00 : 8'h0f]};
            bins range1 = {[8'h10 : 8'h1f]};
            bins range2 = {[8'h20 : 8'h2f]};
            bins range3 = {[8'h30 : 8'h3f]};
            bins range4 = {[8'h40 : 8'h4f]};
            bins range5 = {[8'h50 : 8'h5f]};
            bins range6 = {[8'h60 : 8'h6f]};
            bins range7 = {[8'h70 : 8'h7f]};
            bins range8 = {[8'h80 : 8'h8f]};
            bins range9 = {[8'h90 : 8'h9f]};
            bins rangea = {[8'ha0 : 8'haf]};
            bins rangeb = {[8'hb0 : 8'hbf]};
            bins rangec = {[8'hc0 : 8'hcf]};
            bins ranged = {[8'hd0 : 8'hdf]};
            bins rangee = {[8'he0 : 8'hef]};
            bins rangef = {[8'hf0 : 8'hff]};
        }
        cp_tx_data_s: coverpoint cov_tx_data_s {
            bins zero = {8'h00};
            bins alt_01 = {8'h55};
            bins alt_10 = {8'haa};
            bins lsb_only = {8'h01};
            bins msb_only = {8'h80};
            bins range0 = {[8'h00 : 8'h0f]};
            bins range1 = {[8'h10 : 8'h1f]};
            bins range2 = {[8'h20 : 8'h2f]};
            bins range3 = {[8'h30 : 8'h3f]};
            bins range4 = {[8'h40 : 8'h4f]};
            bins range5 = {[8'h50 : 8'h5f]};
            bins range6 = {[8'h60 : 8'h6f]};
            bins range7 = {[8'h70 : 8'h7f]};
            bins range8 = {[8'h80 : 8'h8f]};
            bins range9 = {[8'h90 : 8'h9f]};
            bins rangea = {[8'ha0 : 8'haf]};
            bins rangeb = {[8'hb0 : 8'hbf]};
            bins rangec = {[8'hc0 : 8'hcf]};
            bins ranged = {[8'hd0 : 8'hdf]};
            bins rangee = {[8'he0 : 8'hef]};
            bins rangef = {[8'hf0 : 8'hff]};
        }
    endgroup

    function new(string name = "axi_i2c_coverage", uvm_component parent);
        super.new(name, parent);
        cg_data = new();
    endfunction

    function void write(axi_i2c_seq_item item);
        cov_tx_data_m = item.tx_data_m;
        cov_tx_data_s = item.tx_data_s;
        cg_data.sample();
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("COV", "\n\n ===== COVERAGE REPORT ===== ", UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " Total Coverage = %.1f%%", cg_data.get_coverage()), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " TX Data (M) Coverage = %.1f%%",
                  cg_data.cp_tx_data_m.get_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", $sformatf(
                  " TX Data (S) Coverage = %.1f%%",
                  cg_data.cp_tx_data_s.get_coverage()
                  ), UVM_LOW)
        `uvm_info("COV", " =========================== \n\n", UVM_LOW)
    endfunction
endclass


class axi_i2c_agent extends uvm_agent;
    `uvm_component_utils(axi_i2c_agent)
    axi_i2c_driver    drv;
    axi_i2c_monitor   mon;
    uvm_sequencer #(axi_i2c_seq_item) sqr;

    function new(string name = "axi_i2c_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = axi_i2c_driver::type_id::create("drv", this);
        mon = axi_i2c_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(axi_i2c_seq_item)::type_id::create("sqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass

class axi_i2c_env extends uvm_env;
    `uvm_component_utils(axi_i2c_env)
    axi_i2c_agent      agt;
    axi_i2c_scoreboard scb;
    axi_i2c_coverage   cov;

    function new(string name = "axi_i2c_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = axi_i2c_agent::type_id::create("agt", this);
        scb = axi_i2c_scoreboard::type_id::create("scb", this);
        cov = axi_i2c_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass

class axi_i2c_test extends uvm_test;
    `uvm_component_utils(axi_i2c_test)
    axi_i2c_env env;

    function new(string name = "axi_i2c_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_i2c_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_i2c_seq seq;
        phase.raise_objection(this);
        seq = axi_i2c_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass

module tb_axi_i2c_uvm ();
    bit clk;
    bit rst_n;
    axi_i2c_if vif (
        clk,
        rst_n
    );

    // DUT (I2C Master)
    i2c_system_top DUT (
        .sys_clock(clk),
        .reset_n(rst_n),
        .s_axi_awaddr(vif.awaddr),
        .s_axi_awprot(vif.awprot),
        .s_axi_awvalid(vif.awvalid),
        .s_axi_awready(vif.awready),
        .s_axi_wdata(vif.wdata),
        .s_axi_wstrb(vif.wstrb),
        .s_axi_wvalid(vif.wvalid),
        .s_axi_wready(vif.wready),
        .s_axi_bresp(vif.bresp),
        .s_axi_bvalid(vif.bvalid),
        .s_axi_bready(vif.bready),
        .s_axi_araddr(vif.araddr),
        .s_axi_arprot(vif.arprot),
        .s_axi_arvalid(vif.arvalid),
        .s_axi_arready(vif.arready),
        .s_axi_rdata(vif.rdata),
        .s_axi_rresp(vif.rresp),
        .s_axi_rvalid(vif.rvalid),
        .s_axi_rready(vif.rready),
        .slave_sw(vif.slave_tx_data),
        .slave_led(vif.slave_rx_data)
    );

    //  DUT 내부 선으로 직접 Pull-up 연결
    pullup (DUT.scl);
    pullup (DUT.sda);

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        #25 rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual axi_i2c_if)::set(null, "*", "vif", vif);
        run_test("axi_i2c_test");
    end
endmodule
