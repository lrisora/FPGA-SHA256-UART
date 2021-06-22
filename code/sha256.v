`include "define.v"
module sha256 (Clk, Reset, Start, Chunk, Digest, DigestReady
`ifdef _DEBUG
    , D_Q_sha, D_sha_round, D_w, D_k, D_warray, D_hash_in
`endif
    );
    // 初始常数，由SHA256标准定义
    parameter   SHA256_A0       =   32'h6a09e667;
    parameter   SHA256_B0       =   32'hbb67ae85;
    parameter   SHA256_C0       =   32'h3c6ef372;
    parameter   SHA256_D0       =   32'ha54ff53a;
    parameter   SHA256_E0       =   32'h510e527f;
    parameter   SHA256_F0       =   32'h9b05688c;
    parameter   SHA256_G0       =   32'h1f83d9ab;
    parameter   SHA256_H0       =   32'h5be0cd19;
    // 状态
    parameter   READY           =   3'b001,
                HASHING         =   3'b010,
                DIGEST_READY    =   3'b100;
    // I/O
    input              Clk;                     // 哈希时钟
    input              Reset;                   // 低电平复位
    input              Start;                   // 开始信号
    input      [511:0] Chunk;                   // 哈希区块输入
    output reg         DigestReady;             // 结果就绪
    output reg [255:0] Digest;                  // 哈希结果

    // 状态变量
    reg [2:0] Q_present, Q_next;
    // 此次哈希运算初值
    reg  [31:0] a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in;
    // 此次哈希运算结果
    wire [31:0] a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out;

    reg [5:0] round;                            // 计数变量，用于记录计算次数
    reg [15:0] [31:0] w_array;                  // 用于存储w过去16轮中的W的数组
    wire [31:0] k, w;                           // 用于传递变量k、w的连线
    reg update_en;                              // 指示下降沿时更新hash输入为输出，为0时复位为哈希初值

`ifdef _DEBUG
    output [2:0] D_Q_sha;      assign D_Q_sha = Q_present;
    output [5:0] D_sha_round;  assign D_sha_round = round;
    output [31:0] D_w;         assign D_w = w;
    output [31:0] D_k;         assign D_k = k;
    output [512:0] D_warray;   assign D_warray = w_array;
    output [255:0] D_hash_in;  assign D_hash_in = {a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in};
`endif

    // 例化k查找表模块，w计算模块，哈希算法逻辑模块
    k_constants    kc (round, k);
    calc_w         cw (round, w_array, w);
    hash_algorithm ha (Clk, Reset, w, k, a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in,
                       a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out);

    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            Q_present <= READY;
        end else begin
            Q_present <= Q_next;
        end
    end

    always @(*) begin
        case (Q_present)
            READY        : if (Start)          Q_next <= HASHING;      else Q_next <= READY;
            HASHING      : if (round == 6'd63) Q_next <= DIGEST_READY; else Q_next <= HASHING;
            DIGEST_READY : Q_next <= READY;
            default      : Q_next <= READY;
        endcase
    end

    always @(*) begin
        if (update_en) begin
            {a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in}
            <= {a_out, b_out, c_out, d_out, e_out, f_out, g_out, h_out};
        end else begin
            {a_in, b_in, c_in, d_in, e_in, f_in, g_in, h_in}
            <= {SHA256_A0, SHA256_B0, SHA256_C0, SHA256_D0, SHA256_E0, SHA256_F0, SHA256_G0, SHA256_H0};
        end
    end

    // 上升沿更新其他数据
    always @ (posedge Clk, negedge Reset) begin
        if (!Reset) begin
            {w_array, round, Digest, DigestReady, update_en} <= 0;
        end else begin
            case (Q_present)
                READY : begin
                    round <= 6'd0;
                    if (Start) begin
                        DigestReady <= 1'b0;            // 上次完成标志复位，防止上层误读本次已结束
                        // 如果Start为1将待处理的块数据加载到中间数组
                        w_array[00] <= Chunk[511:480];    w_array[01] <= Chunk[479:448];
                        w_array[02] <= Chunk[447:416];    w_array[03] <= Chunk[415:384];
                        w_array[04] <= Chunk[383:352];    w_array[05] <= Chunk[351:320];
                        w_array[06] <= Chunk[319:288];    w_array[07] <= Chunk[287:256];
                        w_array[08] <= Chunk[255:224];    w_array[09] <= Chunk[223:192];
                        w_array[10] <= Chunk[191:160];    w_array[11] <= Chunk[159:128];
                        w_array[12] <= Chunk[127:096];    w_array[13] <= Chunk[095:064];
                        w_array[14] <= Chunk[063:032];    w_array[15] <= Chunk[031:000];
                    end
                end
                HASHING : begin
                    update_en <= (round != 63);         // 0时控制哈希输入为初值，1时哈希输入为上次结果
                    round     <= round + 6'd1;          // 自增计数变量
                    if (round > 15)                     // 输入已进入哈希算法后开始更新w数组，w只需保留最近16次即可
                        w_array[15:0] <= {w, w_array[15:1]};
                end
                DIGEST_READY : begin                    // 将输出与初始常数求和并赋值到一个摘要寄存器中来计算哈希
                    Digest <= {(a_out + SHA256_A0), (b_out + SHA256_B0), (c_out + SHA256_C0), (d_out + SHA256_D0),
                               (e_out + SHA256_E0), (f_out + SHA256_F0), (g_out + SHA256_G0), (h_out + SHA256_H0)};
                    DigestReady <= 1'b1;                // 结果就绪标志, 保持到下次开始信号到来
                end
            endcase
        end
    end
endmodule
