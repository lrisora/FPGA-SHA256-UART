`include "define.v"
module hash_algorithm (Clk, Reset, Win, Kin, Ain, Bin, Cin, Din, Ein, Fin, Gin, Hin, Aout, Bout, Cout, Dout, Eout, Fout, Gout, Hout);
    // I/O
    input             Clk, Reset;
    input      [31:0] Win, Kin, Ain, Bin, Cin, Din, Ein, Fin, Gin, Hin;
    output reg [31:0] Aout, Bout, Cout, Dout, Eout, Fout, Gout, Hout;

    // 用于哈希算法压缩组合逻辑的连线
    wire [31:0] ch_out;
    wire [31:0] E1_out;
    wire [31:0] ma_out;
    wire [31:0] E0_out;
    // 用于32位加法器的组合逻辑连线
    wire [31:0] add_d;
    wire [31:0] add_step_0;
    wire [31:0] add_step_1;
    wire [31:0] add_step_2;
    wire [31:0] add_step_3;
    wire [31:0] add_step_4;
    wire [31:0] add_step_5;

    // 用于哈希算法的32位加法器
`ifdef DSP_FOR_ADD
    c_add_32 add_h0 (.A(Hin       ), .B(Win       ), .S(add_step_0));
    c_add_32 add_h1 (.A(E1_out    ), .B(ch_out    ), .S(add_step_1));
    c_add_32 add_h2 (.A(add_step_0), .B(add_step_1), .S(add_step_2));
    c_add_32 add_h3 (.A(add_step_2), .B(Kin       ), .S(add_step_3));
    c_add_32 add_h4 (.A(add_step_3), .B(Din       ), .S(add_d     ));
    c_add_32 add_h5 (.A(ma_out    ), .B(E0_out    ), .S(add_step_4));
    c_add_32 add_h6 (.A(add_step_3), .B(add_step_4), .S(add_step_5));
`else
    assign add_step_0 = Hin        + Win;
    assign add_step_1 = E1_out     + ch_out;
    assign add_step_2 = add_step_0 + add_step_1;
    assign add_step_3 = add_step_2 + Kin;
    assign add_d      = add_step_3 + Din;
    assign add_step_4 = ma_out     + E0_out;
    assign add_step_5 = add_step_3 + add_step_4;
`endif

    // 例化压缩函数模块
    choose_function   ch (Ein, Fin, Gin, ch_out);
    E1_function       E1 (Ein, E1_out);
    majority_function ma (Ain, Bin, Cin, ma_out);
    E0_function       E0 (Ain, E0_out);
    // 上升沿进行进行一次运算
    always @ (posedge Clk ,negedge Reset) begin
        if (!Reset) begin
            {Aout, Bout, Cout, Dout, Eout, Fout, Gout, Hout} <= {8{32'b0}};
        end else begin
            Aout <= add_step_5; // A <- E0 + Ma + E1 + w + k + H + Ch
            Bout <= Ain;        // B <- A
            Cout <= Bin;        // C <- B
            Dout <= Cin;        // D <- C
            Eout <= add_d;      // E <- D + E1 + w + k + H + Ch
            Fout <= Ein;        // F <- E
            Gout <= Fin;        // G <- F
            Hout <= Gin;        // H <- G
        end
    end
endmodule

// A，B，C按位多数表决
module majority_function (A, B, C, MaOut);
    // I/O
    input [31:0] A, B, C;
    output [31:0] MaOut;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : Bitwise_Majority
            ma_1_bit ma (A[i], B[i], C[i], MaOut[i]);
        end
    endgenerate
endmodule

// A，B，C多数表决
module ma_1_bit (A, B, C, MaOut);
    // I/O
    input A, B, C;
    output MaOut;
    assign MaOut = (A & B) ^ (A & C) ^ (B & C);
endmodule

// 对A进行循环移位及异或
module E0_function (A, E0Out);
    input [31:0] A;
    output [31:0] E0Out;
    // 临时变量
    wire [31:0] rr_2;
    wire [31:0] rr_13;
    wire [31:0] rr_22;
    // 对A循环移位
    assign rr_2  = {A[ 1:0], A[31: 2]}; // 循环右移2位
    assign rr_13 = {A[12:0], A[31:13]}; // 循环右移13位
    assign rr_22 = {A[21:0], A[31:22]}; // 循环右移22位
    // 异或中间变量
    assign E0Out = (rr_2 ^ rr_13 ^ rr_22);
endmodule

// 对E进行循环移位及异或
module E1_function (E, E1Out);
    // I/O
    input  [31:0] E;
    output [31:0] E1Out;
    // 临时变量
    wire [31:0] rr_6;
    wire [31:0] rr_11;
    wire [31:0] rr_25;
    // 对E进行循环右移
    assign rr_6  = {E[ 5:0], E[31: 6]}; // 循环右移6位
    assign rr_11 = {E[10:0], E[31:11]}; // 循环右移11位
    assign rr_25 = {E[24:0], E[31:25]}; // 循环右移25位
    // 按位异或结果
    assign E1Out = (rr_6 ^ rr_11 ^ rr_25);
endmodule

// 根据E按位选择F、G
module choose_function (E, F, G, ChOut);
    // I/O
    input [31:0] E, F, G;
    output [31:0] ChOut;
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : Bitwise_Mux
            mux_1_bit m (E[i], {F[i], G[i]}, ChOut[i]);
        end
    endgenerate
endmodule

// MUX
module mux_1_bit (s, in, out);
    // I/O
    input s;
    input [1:0] in;
    output out;
    assign out = in[s];
endmodule
