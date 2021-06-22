module calc_w (Round, WArray, WOut);
    input       [ 5:0]        Round;
    input       [15:0] [31:0] WArray;
    output reg  [31:0]        WOut;

    wire [31:0]  I, J, K, P, Q, R, S0, S1;
    assign I  = {WArray[ 1][ 6:0], WArray[ 1][31: 7]}; // 循环右移7位
    assign J  = {WArray[ 1][17:0], WArray[ 1][31:18]}; // 循环右移18位
    assign K  =  WArray[ 1] >> 3;                      // 右移3位
    assign P  = {WArray[14][16:0], WArray[14][31:17]}; // 循环右移17位
    assign Q  = {WArray[14][18:0], WArray[14][31:19]}; // 循环右移19位
    assign R  =  WArray[14] >> 10;                     // 右移10位
    assign S0 = (I ^ J ^ K);
    assign S1 = (P ^ Q ^ R);
    // 生成w
    always @(*) begin
        if (Round < 16) begin                          // 还没达到足够计算W的周期
            WOut <= WArray[Round];                     // 前16个周期进行用户数据输入
        end else begin
            WOut <= (WArray[0] + S0) + (WArray[9] + S1);
        end
    end
endmodule
