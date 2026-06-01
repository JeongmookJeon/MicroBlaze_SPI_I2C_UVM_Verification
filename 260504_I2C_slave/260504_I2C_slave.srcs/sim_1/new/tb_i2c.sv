`timescale 1ns / 1ps

module tb_i2c_system ();

    // --- 신호 선언 ---
    logic        clk;
    logic        rst_n;

    // AXI Lite Signals
    logic [ 3:0] awaddr;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [ 3:0] wstrb;
    logic        wvalid;
    logic        wready;
    logic [ 3:0] araddr;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic        rvalid;
    logic        rready;
    logic        bready;
    logic        bvalid;

    // Slave I/O
    logic [ 7:0] slave_sw;
    logic [ 7:0] slave_led;

    // --- DUT Instantiate ---
    // 포트를 명시적으로 매핑하여 이름 불일치로 인한 오류를 차단합니다.
    i2c_system_top dut (
        .sys_clock(clk),
        .reset_n(rst_n),  // ◀ 핵심 해결 부분: 원본의 reset_n 핀에 TB의 rst_n 신호를 연결

        // AXI Lite 포트 연결 (.* 대신 하나씩 확실하게 매핑)
        .s_axi_awaddr (awaddr),
        .s_axi_awprot (3'b0),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata  (wdata),
        .s_axi_wstrb  (wstrb),
        .s_axi_wvalid (wvalid),
        .s_axi_wready (wready),
        .s_axi_bresp  (),
        .s_axi_bvalid (bvalid),
        .s_axi_bready (bready),
        .s_axi_araddr (araddr),
        .s_axi_arprot (3'b0),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rdata  (rdata),
        .s_axi_rresp  (),
        .s_axi_rvalid (rvalid),
        .s_axi_rready (rready),

        // Slave 외부 입출력 연결
        .slave_sw (slave_sw),
        .slave_led(slave_led)
    );

    // 100MHz 클럭 생성
    always #5 clk = ~clk;

   // --- 완벽하게 동기화된 AXI Write Task ---
    task axi_write(input [3:0] addr, input [31:0] data);
        begin
            @(posedge clk); // ◀ [핵심] 클럭 상승 에지에 완벽히 맞춤
            awaddr  <= addr; // ◀ [핵심] '=' 대신 '<=' 를 사용하여 Race Condition 방지
            awvalid <= 1;
            wdata   <= data;
            wstrb   <= 4'hf;
            wvalid  <= 1;
            bready  <= 1;

            // Slave가 주소와 데이터를 받을 때까지(High) 대기
            wait (awready && wready);

            @(posedge clk); // 다음 클럭 에지까지 안전하게 1클럭 유지
            awvalid <= 0;
            wvalid  <= 0;

            // Slave의 B 채널 응답 대기
            wait (bvalid);
            @(posedge clk);
            bready <= 0;
        end
    endtask

    // --- 완벽하게 동기화된 AXI Read Task ---
    task axi_read(input [3:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr  <= addr;
            arvalid <= 1;
            rready  <= 1;
            
            wait (arready);
            @(posedge clk);
            arvalid <= 0;
            
            wait (rvalid);
            data = rdata; // 읽은 데이터 저장 (소프트웨어 변수이므로 = 허용)
            @(posedge clk);
            rready <= 0;
        end
    endtask
    // --- I2C 통신 완료 대기 Task (Polling) ---
    // C 코드의 while (STATUS & BUSY) 와 동일한 역할
    task wait_i2c_done();
        logic [31:0] stat_val;
        begin
            stat_val = 0;
            // 주소 4'hC (slv_reg3)의 1번 비트가 done_real 입니다.
            // done_real이 1이 될 때까지 AXI Read를 반복합니다.
            while ((stat_val & 32'h0000_0002) == 0) begin
                axi_read(4'hC, stat_val);
                #100;  // 버스 과부하 방지용 딜레이
            end
        end
    endtask

    // --- Test Scenario ---
    initial begin
        logic [31:0] read_val;

        // 1. 초기화
        clk = 0;
        rst_n = 0;
        awaddr = 0;
        awvalid = 0;
        wdata = 0;
        wstrb = 0;
        wvalid = 0;
        araddr = 0;
        arvalid = 0;
        rready = 0;
        bready = 0;
        slave_sw = 8'hA5;  // 슬레이브 스위치 값을 0xA5 로 고정

        #100 rst_n = 1;
        #100;

        // ==========================================
        // 시나리오 1: Master -> Slave Write (LED 켜기)
        // ==========================================
        $display("--------------------------------");
        $display("[TB] Start I2C Write Test (Data: 0x55)");

        // (1) START
        axi_write(4'h0, 32'h01);
        wait_i2c_done();

        // (2) Slave Address 전송 (Write 모드, 주소: 0x24)
        axi_write(4'h4, 32'h24);  // tx_data (주소 0x4)에 기록
        axi_write(4'h0, 32'h02);  // WRITE 명령
        wait_i2c_done();

        // (3) Data 전송 (0x55)
        axi_write(4'h4, 32'h55);  // tx_data (주소 0x4)에 기록
        axi_write(4'h0, 32'h02);  // WRITE 명령
        wait_i2c_done();

        // (4) STOP
        axi_write(4'h0, 32'h08);
        wait_i2c_done();

        #100000;
        $display("[TB] Slave LED Output: %h", slave_led);

        // ==========================================
        // 시나리오 2: Slave -> Master Read (SW 값 읽기)
        // ==========================================
        $display("--------------------------------");
        $display("[TB] Start I2C Read Test (Expected: 0xA5)");

        // (1) START
        axi_write(4'h0, 32'h01);
        wait_i2c_done();

        // (2) Slave Address 전송 (Read 모드, 주소: 0x25)
        axi_write(4'h4, 32'h25);  // tx_data (주소 0x4)에 기록
        axi_write(4'h0,
                  32'h02); // WRITE 명령 (주소를 먼저 써야하므로 Write 수행)
        wait_i2c_done();

        // (3) READ 수행
        axi_write(4'h0, 32'h04);  // READ 명령 전송
        wait_i2c_done();

        // (4) rx_data 읽어오기 (주소 0x8)
        axi_read(4'h8, read_val);
        $display("[TB] Master Read Data from Slave: %h", read_val[7:0]);

        // (5) STOP
        axi_write(4'h0, 32'h08);
        wait_i2c_done();

        $display("--------------------------------");
        $finish;
    end

endmodule
