`timescale 1ns/1ps
`include "define.v"
module testbench_sha256();

    localparam DELAY = 10;
    localparam NUM   = 8;    // 数据个数

    reg Clk, Reset, Start;

    reg [511:0] Chunk;
    wire [255:0] Digest;
    wire DigestReady;

`ifdef _DEBUG
    wire [2:0] D_Q_sha;
    wire [5:0] D_sha_round;
    wire [31:0] D_w;
    wire [31:0] D_k;
    wire [512:0] D_warray;
    wire [255:0] D_hash_in;
`endif

    reg [511:0] data [0:NUM - 1];
    reg [255:0] hash_result [0:NUM - 1];

    // clock
    always #DELAY Clk = !Clk;

    // initial
    initial begin
        Reset = 1'b1;
        Clk   = 1'b1;
        Start = 1'b0;
        Chunk = 512'b0;
        # DELAY;
        # DELAY;
        Reset = 1'b0;
        # DELAY;
        # DELAY;
        Reset = 1'b1;
    end


    // main
    integer i, file;
    initial begin
        $readmemh("./data/sha256block.txt", data);  //read data
        $readmemh("./data/sha256result.txt", hash_result); //read hash
        file = $fopen("./data/result1.txt", "w+");
        # DELAY;
        # DELAY;
        # DELAY;
        # DELAY;
        for(i = 0; i < NUM; i = i + 1) begin
            Chunk = data[i];
            Start = 1'b1;
            # DELAY;
            # DELAY;
            Start = 0;
            # DELAY;
            # DELAY;
            while (!DigestReady) begin
                # DELAY;
                # DELAY;
            end
            $fwrite(file, "%h\n", Digest);
            if (Digest == hash_result[i])
                $display("data %d is pass", i + 1);
            else
                $display("data %d is fail", i + 1);
            // #100;
        end
        $fclose(file);
        $display("test over");
        $finish;
    end

    // Instantiation
    sha256 t (Clk, Reset, Start, Chunk, Digest, DigestReady
`ifdef _DEBUG
    , D_Q_sha, D_sha_round, D_w, D_k, D_warray, D_hash_in
`endif
    );

endmodule
