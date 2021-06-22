module tx_shift_reg (Clk, Reset, DataIn, TxOut, Empty
    );   // 单字节发送，发送下一个字节需要复位此模块
    input Clk, Reset;            // 时钟、复位
    input [7:0] DataIn;          // 待发送数据
    output reg TxOut;            // 串行输出
    output reg Empty;            // 移位寄存器空标志

    reg [7:0] tmp;
    reg [3:0] counter;           // 计数变量

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            {tmp, counter, Empty} <= 0;          // 复位寄存器
            TxOut <= 1'b1;
        end else begin
            if (counter == 0) begin
                tmp     <= DataIn[7:0];
                TxOut   <= 1'b0;
                counter <= counter + 1'b1;
            end else if (counter < 10) begin
                TxOut   <= tmp[0];
                tmp     <= {1'b1, tmp[7:1]};
                counter <= counter + 1'b1;
            end else begin
                Empty   <= 1'b1;
            end
        end
    end
endmodule
