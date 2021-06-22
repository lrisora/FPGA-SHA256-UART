module uart_tx (Clk, Reset, Start, Digest, TxOut, TxDone);
    // 状态定义
    parameter   WAIT_START = 3'h0,
                SEND_BYTE  = 3'h1,
                WAIT_OK    = 3'h2,
                SEND_CR    = 3'h3,
                WAIT_CR    = 3'h4,
                SEND_LF    = 3'h5,
                WAIT_LF    = 3'h6;

    // I/O
    input Clk, Reset, Start;
    input [255:0] Digest;
    output TxOut;
    output reg TxDone;

    // 状态变量
    reg [2:0] Q_present, Q_next;

    reg reset_sr;                    // 字节发送复位，取消复位即开始发送
    wire baud_rate;                  // 发送时钟
    wire Byte_Ok;                    // 字节发送完成

    reg [255:0] tmp;
    reg [7:0] ascii;
    reg [7:0] Byte;
    reg [7:0] cnt;

    // 例化模块
    baud_generate brg (Clk, reset_sr, baud_rate);
    tx_shift_reg  sr  (baud_rate, reset_sr, Byte, TxOut, Byte_Ok);

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            Q_present <= WAIT_START;
        end else begin
            Q_present <= Q_next;
        end
    end

    always @ (*) begin
        case (Q_present)
            WAIT_START : begin if (Start) Q_next <= SEND_BYTE; else Q_next <= WAIT_START; end
            SEND_BYTE  : begin Q_next <= WAIT_OK; end
            WAIT_OK    : begin
                if (Byte_Ok) begin
                    if (cnt == 0) begin
                        Q_next <= SEND_CR;
                    end else begin
                        Q_next <= SEND_BYTE;
                    end
                end else begin
                    Q_next <= WAIT_OK;
                end
            end
            SEND_CR : begin Q_next <= WAIT_CR;    end
            WAIT_CR : begin if (Byte_Ok) Q_next <= SEND_LF;    else Q_next <= WAIT_CR; end
            SEND_LF : begin Q_next <= WAIT_LF;    end
            WAIT_LF : begin if (Byte_Ok) Q_next <= WAIT_START; else Q_next <= WAIT_LF; end
            default : begin Q_next <= WAIT_START; end
        endcase
    end

    always @(*) begin
        case (tmp[255:252])
            4'h0:ascii<=8'h30; 4'h1:ascii<=8'h31; 4'h2:ascii<=8'h32; 4'h3:ascii<=8'h33;
            4'h4:ascii<=8'h34; 4'h5:ascii<=8'h35; 4'h6:ascii<=8'h36; 4'h7:ascii<=8'h37;
            4'h8:ascii<=8'h38; 4'h9:ascii<=8'h39; 4'hA:ascii<=8'h41; 4'hB:ascii<=8'h42;
            4'hC:ascii<=8'h43; 4'hD:ascii<=8'h44; 4'hE:ascii<=8'h45; 4'hF:ascii<=8'h46;
        endcase
    end

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            {Byte, tmp, cnt, reset_sr, TxDone} <= 0;
        end else begin
            case (Q_present)
                WAIT_START : begin
                    if (Start) begin
                        tmp <= Digest;
                    end
                    cnt <= 8'd64;
                    TxDone <= 0;
                end
                SEND_BYTE : begin
                    Byte <= ascii;
                    reset_sr <= 1'b1;
                    cnt <= cnt - 1;
                end
                WAIT_OK : begin
                    if (Byte_Ok) begin
                        tmp <= {tmp[251:0], 4'b0};
                        reset_sr <= 1'b0;
                    end
                end
                SEND_CR : begin Byte <= 8'h0D; reset_sr <= 1'b1; end
                WAIT_CR : begin if (Byte_Ok)   reset_sr <= 1'b0; end
                SEND_LF : begin Byte <= 8'h0A; reset_sr <= 1'b1; end
                WAIT_LF : begin
                    if (Byte_Ok) begin
                        reset_sr <= 1'b0;
                        TxDone <= 1'b1;
                    end
                end
            endcase
        end
    end
endmodule
