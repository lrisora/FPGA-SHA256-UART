/**
 * 连接哈希模块与串口收发模块
 * 处理串口模块接收的Command做流程控制
 */
`include "define.v"
module sha256_cu (Clk, Reset, Rx, Tx, RxError, Test
`ifdef _DEBUG
    // rx
    , D_Q_rx, D_hex_in, D_rx_band, D_Command, D_chunk
    // tx
    // sha256
    , D_Q_sha, D_sha_round, D_w, D_k, D_warray, D_hash_in, D_digest
`endif
    );

    // I/O
    input Clk, Reset, Rx;
    output Tx;
    output RxError;
    output [7:0] Test;

    // 模块控制信号
    reg hash_start, transmit_start;
    // 模块输出信号
    wire DigestReady, DigestTransmitted;

    // 用于输入区块与结果的连线
    wire [511:0] chunk;
    wire [7:0] Command;
    wire [255:0] digest;
    // 发送缓存
    reg [255:0] send;
    // 上个时钟的哈希就绪标志
    reg DigestReady_last;

    assign Test = chunk[7:0];

    // test
`ifdef _DEBUG
    // rx
    output [3:0] D_hex_in;
    output D_rx_band;
    output [7:0] D_Command;   assign D_Command = Command;
    output [511:0] D_chunk;   assign D_chunk = chunk;
    output [3:0] D_Q_rx;
    // tx
    // sha256
    output [2:0] D_Q_sha;
    output [5:0] D_sha_round;
    output [31:0] D_w;
    output [31:0] D_k;
    output [512:0] D_warray;
    output [255:0] D_hash_in;
    output [255:0] D_digest;  assign D_digest = digest;
`endif

    // 例化收发模块与哈希256模块
    uart_rx rx     (Clk, Reset , Rx, chunk, Command, RxError
`ifdef _DEBUG
        , D_hex_in, D_rx_band, D_Q_rx
`endif
        );
    uart_tx tx     (Clk, Reset , transmit_start, send, Tx, DigestTransmitted);
    sha256  sha256 (Clk, Reset, hash_start, chunk, digest, DigestReady
`ifdef _DEBUG
        , D_Q_sha, D_sha_round, D_w, D_k, D_warray, D_hash_in
`endif
        );

    // 可以将这个always换成一个状态机进行完全的流程控制自动化
    always @(posedge Clk or negedge Reset) begin
        if(~Reset) begin
            {transmit_start,hash_start, send} <= 0;
        end else begin

            if (Command == 8'h01) begin
                hash_start <= 1;
            end else begin
                hash_start <= 0;
            end

            DigestReady_last <= DigestReady; // 上升沿检测用
            if (Command == 8'h02 | (!DigestReady_last & DigestReady)) begin
                transmit_start <= 1;
                send <= digest;
            end else if (Command == 8'h03) begin
                transmit_start <= 1;
                send <= chunk[511:256];
            end else if (Command == 8'h04) begin
                transmit_start <= 1;
                send <= chunk[255:0];
            end else begin
                transmit_start <= 0;
            end

        end
    end
endmodule
