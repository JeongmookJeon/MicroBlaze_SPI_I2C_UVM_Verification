`timescale 1ns / 1ps

// =======================================================
// Top Module: SPI Slave
// 동작: 스위치(sw_tx_data)값을 Master로 전송하고,
//       Master로부터 수신한 데이터를 FND에 십진수로 표시
// =======================================================
module slave_top (
    input  wire       clk,    // 100MHz System Clock (Basys3 W5)
    input  wire       reset,        // Active High Reset   (BTNC U18)

    // SPI Interface (JA 포트)
    input  wire       sclk,         // JA4 G2
    input  wire       cs_n,         // JA3 J2
    input  wire       mosi,         // JA1 J1
    output wire       miso,         // JA2 L2

    // 사용자 입력: 스위치 8개 (Slave가 Master에게 보낼 데이터)
    input  wire [7:0] tx_data   // SW[7:0] -> GPIOB

);

    wire [7:0] rx_data_sig;
    wire       done_sig;
    wire       busy_sig;

    // done 시점에 수신 데이터를 래치
    reg [7:0] rx_data_reg;

    // SPI Slave
    spi_slave U_SPI_SLAVE (
        .clk     (sys_clock),
        .rst     (reset),
        .sclk    (sclk),
        .cs_n    (cs_n),
        .mosi    (mosi),
        .tx_data (sw_tx_data),
        .rx_data (rx_data_sig),
        .miso    (miso),
        .done    (done_sig),
        .busy    (busy_sig)
    );

    // 수신 완료(done) 시 데이터 래치
    always @(posedge sys_clock or posedge reset) begin
        if (reset)
            rx_data_reg <= 8'd0;
        else if (done_sig)
            rx_data_reg <= rx_data_sig;
    end


endmodule


module spi_slave (
    input  wire       clk,
    input  wire       rst,
    input  wire       sclk,
    input  wire       cs_n,
    input  wire       mosi,
    input  wire [7:0] tx_data,
    output reg  [7:0] rx_data,
    output reg        miso,
    output reg        done,
    output reg        busy
);

    localparam IDLE    = 3'd0;
    localparam START   = 3'd1;
    localparam DATA_RX = 3'd2;
    localparam DATA_TX = 3'd3;
    localparam STOP    = 3'd4;

    reg [2:0] c_state, n_state;

    reg [7:0] rx_data_next;
    reg [7:0] tx_shift_reg, tx_shift_next;
    reg [7:0] rx_shift_reg, rx_shift_next;
    reg [3:0] bit_cnt_reg,  bit_cnt_next;
    reg       miso_next;
    reg       done_next, busy_next;

    wire sclk_pedge, sclk_nedge;

    edge_detector U_EDGE_DETECTOR (
        .clk     (clk),
        .rst     (rst),
        .data_in (sclk),
        .pedge   (sclk_pedge),
        .nedge   (sclk_nedge)
    );

    // Sequential Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            rx_data      <= 8'd0;
            tx_shift_reg <= 8'd0;
            rx_shift_reg <= 8'd0;
            miso         <= 1'b0;
            done         <= 1'b0;
            busy         <= 1'b0;
            bit_cnt_reg  <= 4'd0;
        end else begin
            c_state      <= n_state;
            rx_data      <= rx_data_next;
            tx_shift_reg <= tx_shift_next;
            rx_shift_reg <= rx_shift_next;
            miso         <= miso_next;
            done         <= done_next;
            busy         <= busy_next;
            bit_cnt_reg  <= bit_cnt_next;
        end
    end

    // Combinational Logic (FSM)
    always @(*) begin
        // 기본값 (래치 방지)
        n_state       = c_state;
        rx_data_next  = rx_data;
        tx_shift_next = tx_shift_reg;
        rx_shift_next = rx_shift_reg;
        miso_next     = miso;
        done_next     = 1'b0;       // done은 1클럭 펄스
        busy_next     = busy;
        bit_cnt_next  = bit_cnt_reg;

        case (c_state)
            // ---------------------------------------------------
            IDLE: begin
                miso_next = 1'b0;
                busy_next = 1'b0;
                if (!cs_n) begin
                    tx_shift_next = tx_data;    // 전송할 데이터 로드
                    rx_shift_next = 8'd0;
                    bit_cnt_next  = 4'd0;
                    busy_next     = 1'b1;
                    n_state       = START;
                end
            end
            // ---------------------------------------------------
            // START: 첫 번째 비트를 MISO에 출력 (하강엣지 전 준비)
            START: begin
                miso_next = tx_shift_reg[7];    // MSB 먼저 출력
                if (sclk_pedge) begin
                    // 첫 번째 상승엣지: MOSI 샘플링 후 DATA_RX로
                    rx_shift_next = {rx_shift_reg[6:0], mosi};
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    bit_cnt_next  = 4'd1;
                    n_state       = DATA_TX;
                end
            end
            // ---------------------------------------------------
            // DATA_TX: 하강엣지에서 다음 비트 MISO 출력
            DATA_TX: begin
                if (sclk_nedge) begin
                    miso_next = tx_shift_reg[7];
                    n_state   = DATA_RX;
                end
                // cs_n이 해제되면 강제 종료
                if (cs_n) begin
                    n_state = IDLE;
                end
            end
            // ---------------------------------------------------
            // DATA_RX: 상승엣지에서 MOSI 샘플링
            DATA_RX: begin
                if (sclk_pedge) begin
                    rx_shift_next = {rx_shift_reg[6:0], mosi};
                    tx_shift_next = {tx_shift_reg[6:0], 1'b0};
                    bit_cnt_next  = bit_cnt_reg + 4'd1;
                    if (bit_cnt_reg == 4'd7) begin
                        n_state = STOP;
                    end else begin
                        n_state = DATA_TX;
                    end
                end
                if (cs_n) begin
                    n_state = IDLE;
                end
            end
            // ---------------------------------------------------
            STOP: begin
                rx_data_next = rx_shift_reg;
                done_next    = 1'b1;
                busy_next    = 1'b0;
                miso_next    = 1'b0;
                n_state      = IDLE;
            end
            // ---------------------------------------------------
            default: n_state = IDLE;
        endcase
    end

endmodule


module edge_detector (
    input  wire clk,
    input  wire rst,
    input  wire data_in,
    output wire pedge,
    output wire nedge
);
    reg ff;

    always @(posedge clk or posedge rst) begin
        if (rst) ff <= 1'b0;
        else     ff <= data_in;
    end

    assign pedge = ~ff &  data_in;  // 0→1
    assign nedge =  ff & ~data_in;  // 1→0
endmodule

