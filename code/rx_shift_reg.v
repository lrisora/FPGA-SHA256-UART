module rx_shift_reg (Clk, Reset, Rx, Byte, Ok, Error
    );  // 单字节接收，接收下一个字节需要复位此模块
    // 状态定义
    parameter   START_BIT    = 4'b0001,
                RECEIVE_BYTE = 4'b0010,
                STOP_BIT     = 4'b0100,
                WAIT         = 4'b1000;
    // I/O
    input Clk, Reset, Rx;
    output reg [7:0] Byte;
    output reg Ok, Error;

    reg [4:0] Q_present, Q_next;    // 状态寄存器
    reg [2:0] bit_cnt;              // 当前字节内的位计数

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            Q_present <= START_BIT;
        end else begin
            Q_present <= Q_next;
        end
    end

    always @(*) begin
        case (Q_present)
            START_BIT    : begin if (Rx)       Q_next <= WAIT;     else Q_next <= RECEIVE_BYTE; end
            RECEIVE_BYTE : begin if (&bit_cnt) Q_next <= STOP_BIT; else Q_next <= RECEIVE_BYTE; end
            STOP_BIT     : begin Q_next <= WAIT;      end
            WAIT         : begin Q_next <= WAIT;      end
            default      : begin Q_next <= START_BIT; end
        endcase
    end

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            {Byte, bit_cnt, Ok, Error} <= 0;
        end else begin
            case (Q_present)
                START_BIT   : begin if (Rx) Error <= 1'b1; end
                RECEIVE_BYTE: begin       // 接收数据位，完成后进入停止位接收
                    bit_cnt <= bit_cnt + 4'd1;
                    Byte    <= {Rx, Byte[7:1]};
                end
                STOP_BIT    : begin if (Rx) Ok <= 1'b1; else Error <= 1'b1; end
                WAIT        : begin {Ok, Error} <= {Ok, Error};             end
            endcase
        end
    end
endmodule
