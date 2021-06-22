/**
 * 无状态接收模块+512位移位寄存器
 * 如果收到的字节可以按ASCII码解释为HEX值则将HEX值存入ChunkOut低四位
 * 否则将此字节在Command输出一个Clk
 */
`include "define.v"
module uart_rx (Clk, Reset, RxIn, ChunkOut, Command, RxError
`ifdef _DEBUG
    , D_hex_in, D_rx_band, D_Q_rx
`endif
    );
    // 状态定义
    parameter   WAIT_START = 4'b0001,
                WAIT_BYTE  = 4'b0010,
                COMMAND    = 4'b0100,
                ERROR      = 4'b1000;

    // I/O
    input Clk, Reset, RxIn;
    output reg [511:0] ChunkOut;
    output reg [7:0] Command;
    output reg RxError;

    // 状态寄存器
    reg [3:0] Q_present, Q_next;

    parameter   ERROR_DALEY = 24'hFFFFFF;  // 一些延时
    reg [23:0] ERROR_DALEY_cnt;
    reg [7:0] Byte_tmp;

    reg reset_sr,is_hex;
    wire [7:0] Byte;
    reg [3:0] hex;
    wire baud_rate, Byte_Ok, Byte_Error;

    // test
`ifdef _DEBUG
    output [3:0] D_hex_in; assign D_hex_in  = hex;
    output D_rx_band;      assign D_rx_band = baud_rate;
    output [3:0] D_Q_rx;   assign D_Q_rx = Q_present;
`endif

    // 例化模块
    baud_generate brg (Clk, reset_sr, baud_rate);
    rx_shift_reg  sr  (baud_rate, reset_sr, RxIn, Byte, Byte_Ok, Byte_Error);

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            Q_present <= WAIT_START;
        end else begin
            Q_present <= Q_next;
        end
    end

    always @(*) begin
        case (Q_present)
            WAIT_START : if (!RxIn) Q_next <= WAIT_BYTE; else Q_next <= WAIT_START;
            WAIT_BYTE  : begin
                if (Byte_Ok)
                    Q_next <= COMMAND;
                else if (Byte_Error)
                    Q_next <= ERROR;
                else
                    Q_next <= WAIT_BYTE;
            end
            COMMAND    : Q_next <= WAIT_START;
            ERROR      : if (ERROR_DALEY_cnt == 0) Q_next <= WAIT_START; else Q_next <= ERROR;
            default    : Q_next <= WAIT_START;
        endcase
    end

    always @(*) begin    // 将0-9，A-F，a-f的ASCII码转换为HEX
        case (Byte_tmp)
            8'h30:begin hex<=4'h0;is_hex<=1'b1;end 8'h31:begin hex<=4'h1;is_hex<=1'b1;end
            8'h32:begin hex<=4'h2;is_hex<=1'b1;end 8'h33:begin hex<=4'h3;is_hex<=1'b1;end
            8'h34:begin hex<=4'h4;is_hex<=1'b1;end 8'h35:begin hex<=4'h5;is_hex<=1'b1;end
            8'h36:begin hex<=4'h6;is_hex<=1'b1;end 8'h37:begin hex<=4'h7;is_hex<=1'b1;end
            8'h38:begin hex<=4'h8;is_hex<=1'b1;end 8'h39:begin hex<=4'h9;is_hex<=1'b1;end
            8'h41:begin hex<=4'hA;is_hex<=1'b1;end 8'h42:begin hex<=4'hB;is_hex<=1'b1;end
            8'h43:begin hex<=4'hC;is_hex<=1'b1;end 8'h44:begin hex<=4'hD;is_hex<=1'b1;end
            8'h45:begin hex<=4'hE;is_hex<=1'b1;end 8'h46:begin hex<=4'hF;is_hex<=1'b1;end
            8'h61:begin hex<=4'hA;is_hex<=1'b1;end 8'h62:begin hex<=4'hB;is_hex<=1'b1;end
            8'h63:begin hex<=4'hC;is_hex<=1'b1;end 8'h64:begin hex<=4'hD;is_hex<=1'b1;end
            8'h65:begin hex<=4'hE;is_hex<=1'b1;end 8'h66:begin hex<=4'hF;is_hex<=1'b1;end
            default : begin hex <= 4'h0; is_hex <= 1'b0; end
        endcase
    end

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            {reset_sr, ChunkOut, Byte_tmp, Command, RxError, ERROR_DALEY_cnt} <= 0;
        end else begin
            case (Q_present)
                WAIT_START: begin            // 用高频时钟Clk(建议至少为16倍波特率)去感知起始位RxIn下降沿启动字节接收，有利于对齐
                    if (!RxIn) begin         // RxIn起始位下降沿开启字节接收与接收时钟产生，与异步的UART对齐
                        reset_sr <= 1'b1;    // 此时baud_rate的上升沿刚好在UART信号一位的中间，这样处理连续大量接收时不会出错
                    end else begin
                        reset_sr <= 1'b0;
                    end
                    {Command, RxError} <= 0; // 命令只输出一个时钟
                end
                WAIT_BYTE: begin             // 若开始位检测为高则Byte_Error变为1，停止位中间时会给出Byte_Ok或Byte_Error
                    if (Byte_Ok) begin       // 接收到一字节
                        reset_sr <= 1'b0;
                        Byte_tmp <= Byte;
                    end else if (Byte_Error) begin    // 接收出错
                        reset_sr <= 1'b0;
                        RxError  <= 1'b1;
                        ERROR_DALEY_cnt <= ERROR_DALEY;
                    end
                end
                COMMAND : begin
                    if (is_hex) begin        // 如果接收到的是hex则存入Chunk
                        ChunkOut <= {ChunkOut[512 - 4:0], hex};
                    end else begin           // 接收到的不是hex则按指令处理(向上层模块输出此字节一个时钟)
                        Command  <= Byte_tmp;
                    end
                end
                ERROR: begin                 // 出错后在足够时间的高电平后再重启接收
                    if (RxIn) begin
                        ERROR_DALEY_cnt <= ERROR_DALEY_cnt - 1;
                    end else begin
                        ERROR_DALEY_cnt <= ERROR_DALEY;
                    end
                end
            endcase
        end
    end
endmodule
