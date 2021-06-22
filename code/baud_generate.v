module baud_generate (Clk, Reset, ClkOut);
    parameter MAX_CNT = 9'd346; //  80MHz时钟 115200 波特率，346
                                // 100Mhz时钟 115200 波特率，325
    // I/O
    input Clk, Reset;
    // 复位输出低电平
    output reg ClkOut;

    reg [8:0] counter;

    always @(posedge Clk, negedge Reset) begin
        if (!Reset) begin
            counter <= MAX_CNT;       // 重置计数
            ClkOut  <= 1'b0;          // 复位输出
        end else begin
            if (counter == 0) begin
                counter <= MAX_CNT;
                ClkOut  <= ~ClkOut;
            end else begin
                counter <= counter - 1;
            end
        end
    end
endmodule
