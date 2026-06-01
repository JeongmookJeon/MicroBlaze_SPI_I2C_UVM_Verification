`include "uvm_macros.svh"
import uvm_pkg::*;

// ====================================================================
// 1. AXI & SPI Interface
// ====================================================================
interface axi_spi_if (
    input bit clk,
    input bit rst_n
);
    logic [ 3:0] awaddr;
    logic [ 2:0] awprot;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [ 3:0] wstrb;
    logic        wvalid;
    logic        wready;
    logic [ 1:0] bresp;
    logic        bvalid;
    logic        bready;
    logic [ 3:0] araddr;
    logic [ 2:0] arprot;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [ 1:0] rresp;
    logic        rvalid;
    logic        rready;

    logic [ 7:0] slave_tx_data;
    logic [ 7:0] slave_rx_data;
    logic        slave_done;
endinterface

// ====================================================================
// 2. Sequence Item
// ====================================================================
class axi_spi_seq_item extends uvm_sequence_item;
    rand logic [7:0] tx_data_m;
    rand logic [7:0] tx_data_s;

    logic [7:0] rx_data_m;
    logic [7:0] rx_data_s;

    `uvm_object_utils_begin(axi_spi_seq_item)
        `uvm_field_int(tx_data_m, UVM_ALL_ON)
        `uvm_field_int(tx_data_s, UVM_ALL_ON)
        `uvm_field_int(rx_data_m, UVM_ALL_ON)
        `uvm_field_int(rx_data_s, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_spi_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "[Master] TX:0x%0h, RX:0x%0h | [Slave] TX:0x%0h, RX:0x%0h",
            tx_data_m,
            rx_data_m,
            tx_data_s,
            rx_data_s,
            UVM_LOW
        );
    endfunction
endclass

// ====================================================================
// 3. Sequence
// ====================================================================
class axi_spi_seq extends uvm_sequence #(axi_spi_seq_item);
    `uvm_object_utils(axi_spi_seq)
    // 커버리지를 높이기 위해 트랜잭션 횟수 500회로 증가
    int num_trans = 1000;

    function new(string name = "axi_spi_seq");
        super.new(name);
    endfunction

    task body();
        axi_spi_seq_item item;
        repeat (num_trans) begin
            item = axi_spi_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal(get_type_name(), "Randomize failed")
            finish_item(item);
        end
    endtask
endclass

// ====================================================================
// 4. Driver (AXI Master 역할)
// ====================================================================
class axi_spi_driver extends uvm_driver #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_driver)
    virtual axi_spi_if vif;

    function new(string name = "axi_spi_drv", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Cannot access interface")
    endfunction

    task axi_write(input [3:0] addr, input [31:0] data);
        @(posedge vif.clk);
        vif.awaddr  <= addr;
        vif.awvalid <= 1;
        vif.wdata   <= data;
        vif.wstrb   <= 4'hF;
        vif.wvalid  <= 1;
        fork
            begin
                wait (vif.awready);
                @(posedge vif.clk);
                vif.awvalid <= 0;
            end
            begin
                wait (vif.wready);
                @(posedge vif.clk);
                vif.wvalid <= 0;
            end
        join
        vif.bready <= 1;
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

    virtual task run_phase(uvm_phase phase);
        axi_spi_seq_item item;
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
            axi_write(4'h4, {24'h0, item.tx_data_m});
            axi_write(4'h0, 32'h0000_0404);
            axi_write(4'h0, 32'h0000_0004);
            // Busy(bit 8) 폴링: 통신 완료 대기
            do begin
                axi_read(4'h8, rdata);
            end while ((rdata & (1 << 8)) != 0);
            item.rx_data_m = rdata[7:0];
            item.rx_data_s = vif.slave_rx_data;
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
endclass

// ====================================================================
// 5. Monitor 
// ====================================================================
class axi_spi_monitor extends uvm_monitor;
    `uvm_component_utils(axi_spi_monitor)
    virtual axi_spi_if vif;
    uvm_analysis_port #(axi_spi_seq_item) ap;

    function new(string name = "axi_spi_mon", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_spi_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Cannot access interface")
        ap = new("ap", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        logic [7:0] tx_m_tracker;
        logic busy_prev = 0;

        forever begin
            @(posedge vif.clk);
            if (vif.awvalid && vif.awready && vif.awaddr == 4'h4 && vif.wvalid && vif.wready) begin
                tx_m_tracker = vif.wdata[7:0];
            end

            if (vif.rvalid && vif.rready && vif.araddr == 4'h8) begin
                logic current_busy = (vif.rdata & (1 << 8)) ? 1 : 0;
                if (busy_prev == 1 && current_busy == 0) begin
                    axi_spi_seq_item item = axi_spi_seq_item::type_id::create(
                        "item"
                    );
                    item.tx_data_m = tx_m_tracker;
                    item.tx_data_s = vif.slave_tx_data;
                    item.rx_data_m = vif.rdata[7:0];
                    item.rx_data_s = vif.slave_rx_data;

                    ap.write(item);
                end
                busy_prev = current_busy;
            end
        end
    endtask
endclass

// ====================================================================
// 6. Scoreboard
// ====================================================================
class axi_spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_spi_scoreboard)
    uvm_analysis_imp #(axi_spi_seq_item, axi_spi_scoreboard) ap_imp;

    int pass_cnt = 0;
    int fail_cnt = 0;

    function new(string name = "axi_spi_scb", uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    // Monitor로부터 아이템을 받을 때마다 실행되는 함수
    function void write(axi_spi_seq_item item);
        bit tx_match = (item.tx_data_m == item.rx_data_s);
        bit rx_match = (item.tx_data_s == item.rx_data_m);

        // [수정된 부분] 문자열들을 콤마(,)로 나누지 않고 하나의 큰 따옴표 안에 모두 넣습니다.
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

// ====================================================================
// 7. [NEW] Coverage Subscriber
// ====================================================================
class axi_spi_coverage extends uvm_subscriber #(axi_spi_seq_item);
    `uvm_component_utils(axi_spi_coverage)

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

    function new(string name = "axi_spi_coverage", uvm_component parent);
        super.new(name, parent);
        cg_data = new();
    endfunction

    // Monitor에서 ap.write()를 호출하면 이 함수가 자동으로 실행됨
    function void write(axi_spi_seq_item item);
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

// ====================================================================
// 8. Agent & Env & Test
// ====================================================================
class axi_spi_agent extends uvm_agent;
    `uvm_component_utils(axi_spi_agent)
    axi_spi_driver    drv;
    axi_spi_monitor   mon;
    uvm_sequencer #(axi_spi_seq_item) sqr;

    function new(string name = "axi_spi_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = axi_spi_driver::type_id::create("drv", this);
        mon = axi_spi_monitor::type_id::create("mon", this);
        sqr = uvm_sequencer#(axi_spi_seq_item)::type_id::create("sqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass

class axi_spi_env extends uvm_env;
    `uvm_component_utils(axi_spi_env)
    axi_spi_agent      agt;
    axi_spi_scoreboard scb;
    axi_spi_coverage   cov;

    function new(string name = "axi_spi_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt = axi_spi_agent::type_id::create("agt", this);
        scb = axi_spi_scoreboard::type_id::create("scb", this);
        cov = axi_spi_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // Monitor의 analysis_port를 Scoreboard와 Coverage에 동시 연결
        agt.mon.ap.connect(scb.ap_imp);
        agt.mon.ap.connect(cov.analysis_export);
    endfunction
endclass

class axi_spi_test extends uvm_test;
    `uvm_component_utils(axi_spi_test)
    axi_spi_env env;

    function new(string name = "axi_spi_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_spi_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_spi_seq seq;
        phase.raise_objection(this);
        seq = axi_spi_seq::type_id::create("seq");
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass

// ====================================================================
// 9. Top Module
// ====================================================================
module tb_axi_spi_uvm ();
    bit clk;
    bit rst_n;

    axi_spi_if vif (
        clk,
        rst_n
    );
    wire mosi, miso, sclk, cs_n;

    SPI_v1_0 #(
        .C_S00_AXI_DATA_WIDTH(32),
        .C_S00_AXI_ADDR_WIDTH(4)
    ) DUT_AXI_SPI_MASTER (
        .s00_axi_aclk   (clk),
        .s00_axi_aresetn(rst_n),
        .s00_axi_awaddr (vif.awaddr),
        .s00_axi_awprot (3'b000),
        .s00_axi_awvalid(vif.awvalid),
        .s00_axi_awready(vif.awready),
        .s00_axi_wdata  (vif.wdata),
        .s00_axi_wstrb  (vif.wstrb),
        .s00_axi_wvalid (vif.wvalid),
        .s00_axi_wready (vif.wready),
        .s00_axi_bresp  (vif.bresp),
        .s00_axi_bvalid (vif.bvalid),
        .s00_axi_bready (vif.bready),
        .s00_axi_araddr (vif.araddr),
        .s00_axi_arprot (3'b000),
        .s00_axi_arvalid(vif.arvalid),
        .s00_axi_arready(vif.arready),
        .s00_axi_rdata  (vif.rdata),
        .s00_axi_rresp  (vif.rresp),
        .s00_axi_rvalid (vif.rvalid),
        .s00_axi_rready (vif.rready),
        .mosi           (mosi),
        .miso           (miso),
        .sclk           (sclk),
        .cs_n           (cs_n)
    );

    spi_slave TARGET_SPI_SLAVE (
        .clk    (clk),
        .rst    (~rst_n),
        .sclk   (sclk),
        .cs_n   (cs_n),
        .mosi   (mosi),
        .tx_data(vif.slave_tx_data),
        .rx_data(vif.slave_rx_data),
        .miso   (miso),
        .done   (vif.slave_done),
        .busy   ()
    );

    always #5 clk = ~clk;

    initial begin
        clk   = 0;
        rst_n = 0;
        #25 rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual axi_spi_if)::set(null, "*", "vif", vif);
        run_test("axi_spi_test");
    end
endmodule
