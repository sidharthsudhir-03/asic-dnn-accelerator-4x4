`timescale 1ns / 1ps
`define CLK_DELAY #2;
`define HALF_CLK_DELAY #1;

module mkMACBuff_TB;

    // ==================== PARAMETERS ====================
    parameter WIDTH      = 16;
    parameter DEPTH      = 64;
    parameter ADDR_WIDTH = 6;
    parameter MEMTYPE    = 0;
    parameter TECHNODE   = 0;
    parameter COL_MUX    = 1;

    // ==================== DUT / MEM SIGNALS ====================
    reg  CLK;
    reg  RESET;
    wire RST_N;
    assign RST_N = ~RESET;

    // MAC interface
    reg  EN_mac;
    wire RDY_mac;
    reg  [WIDTH-1:0] mac_vectA_0, mac_vectB_0;
    reg  [WIDTH-1:0] mac_vectA_1, mac_vectB_1;
    reg  [WIDTH-1:0] mac_vectA_2, mac_vectB_2;
    reg  [WIDTH-1:0] mac_vectA_3, mac_vectB_3;

    // Memory interface
    wire                     EN_writeMem;
    wire [ADDR_WIDTH-1:0]    writeMem_addr;
    wire [2*WIDTH+1:0]       writeMem_val;

    reg                      EN_blockRead;
    wire                     RDY_blockRead;

    wire                     EN_readMem;
    wire [ADDR_WIDTH-1:0]    readMem_addr;
    wire [2*WIDTH+1:0]       readMem_val;

    wire                     VALID_memVal;
    wire [2*WIDTH+1:0]       memVal_data;

    // ==================== DUT INSTANTIATION ====================
    mkMACBuff mkMACBuff(
        .CLK(CLK), .RST_N(RST_N),

        .EN_mac(EN_mac), .RDY_mac(RDY_mac),
        .mac_vectA_0(mac_vectA_0), .mac_vectB_0(mac_vectB_0),
        .mac_vectA_1(mac_vectA_1), .mac_vectB_1(mac_vectB_1),
        .mac_vectA_2(mac_vectA_2), .mac_vectB_2(mac_vectB_2),
        .mac_vectA_3(mac_vectA_3), .mac_vectB_3(mac_vectB_3),

        .EN_writeMem(EN_writeMem), .writeMem_addr(writeMem_addr), .writeMem_val(writeMem_val),

        .EN_blockRead(EN_blockRead), .RDY_blockRead(RDY_blockRead),

        .EN_readMem(EN_readMem), .readMem_addr(readMem_addr), .readMem_val(readMem_val),

        .VALID_memVal(VALID_memVal), .memVal_data(memVal_data)
    );

    // Memory wrapper
    memory_wrapper_2port #(
        .DEPTH(DEPTH),
        .LOGDEPTH(ADDR_WIDTH),
        .WIDTH(2*WIDTH+2),
        .MEMTYPE(MEMTYPE),
        .TECHNODE(TECHNODE),
        .COL_MUX(COL_MUX)
    ) memory_2port (
        .clkA(CLK), .aA(readMem_addr), .cenA(~EN_readMem), .q(readMem_val),
        .clkB(CLK), .aB(writeMem_addr), .cenB(~EN_writeMem), .d(writeMem_val)
    );

    // ==================== CLOCK GEN ====================
    always #1 CLK = ~CLK;

    // ==================== TASKS ====================

    // Initialization
    task TASK_init;
    begin
        CLK        = 1'b0;
        RESET      = 1'b1;
        EN_mac     = 1'b0;
        EN_blockRead = 1'b0;
        mac_vectA_0 = '0; mac_vectB_0 = '0;
        mac_vectA_1 = '0; mac_vectB_1 = '0;
        mac_vectA_2 = '0; mac_vectB_2 = '0;
        mac_vectA_3 = '0; mac_vectB_3 = '0;
    end
    endtask

    // reset
    task TASK_reset;
    begin
        RESET = 1'b1;
        `CLK_DELAY;
        RESET = 1'b0;
        `CLK_DELAY;
    end
    endtask

    // testing DUT
    task TASK_DUT;
        // reference data
        reg [WIDTH-1:0] rand_input0_0_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input1_0_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input0_1_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input1_1_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input0_2_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input1_2_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input0_3_array [0:DEPTH-1];
        reg [WIDTH-1:0] rand_input1_3_array [0:DEPTH-1];

        reg [2*WIDTH-1:0] product_0, product_1, product_2, product_3;
        reg [2*WIDTH+1:0] expected_mac_result;
        integer write_count, read_count, iteration;
        integer error_count;
        integer total_reads, total_writes;
    begin
        error_count  = 0;
        total_reads  = 0;
        total_writes = 0;

        // wait a few cycles after reset deassert
        repeat(5) @(posedge CLK);

        $display("\n========================================");
        $display("  MAC Buffer Top-Level Testbench");
        $display("  WIDTH=%0d, DEPTH=%0d", WIDTH, DEPTH);
        $display("========================================\n");

        // 8 iterations of fill + read
        for (iteration = 0; iteration < 8; iteration = iteration + 1) begin
            $display("--- Iteration %0d ---", iteration);
            $display("  Phase 1: Memory Fill (2x2 MAC ops)");

            // generate random inputs
            for (int k = 0; k < DEPTH; k++) begin
                rand_input0_0_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input1_0_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input0_1_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input1_1_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input0_2_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input1_2_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input0_3_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
                rand_input1_3_array[k] = $urandom_range(0, (1 << WIDTH) - 1);
            end

            // write phase
            write_count = 0;
            while (write_count <= DEPTH) begin
                @(posedge CLK);
                if (RDY_mac) begin
                    mac_vectA_0 <= rand_input0_0_array[write_count];
                    mac_vectB_0 <= rand_input1_0_array[write_count];
                    mac_vectA_1 <= rand_input0_1_array[write_count];
                    mac_vectB_1 <= rand_input1_1_array[write_count];
                    mac_vectA_2 <= rand_input0_2_array[write_count];
                    mac_vectB_2 <= rand_input1_2_array[write_count];
                    mac_vectA_3 <= rand_input0_3_array[write_count];
                    mac_vectB_3 <= rand_input1_3_array[write_count];
                    EN_mac      <= 1'b1;
                    write_count = write_count + 1;
                end
                else begin
                    EN_mac      <= 1'b0;
                    mac_vectA_0 <= '0; mac_vectB_0 <= '0;
                    mac_vectA_1 <= '0; mac_vectB_1 <= '0;
                    mac_vectA_2 <= '0; mac_vectB_2 <= '0;
                    mac_vectA_3 <= '0; mac_vectB_3 <= '0;
                end
            end

            EN_mac      <= 1'b0;
            total_writes = total_writes + DEPTH;
            $display("  Wrote %0d MAC results to memory", DEPTH);

            // wait for memory full
            wait(~EN_writeMem);
            $display("  RDY_mac went LOW - memory FULL");
            repeat(3) @(posedge CLK);

            // read phase
            $display("  Phase 2: Block Read");
            EN_blockRead <= 1'b1;
            @(posedge CLK);
            EN_blockRead <= 1'b0;

            read_count = 0;
            while (read_count < DEPTH) begin
                @(posedge CLK);
                if (VALID_memVal) begin
                    product_0 = rand_input0_0_array[read_count] * rand_input1_0_array[read_count];
                    product_1 = rand_input0_1_array[read_count] * rand_input1_1_array[read_count];
                    product_2 = rand_input0_2_array[read_count] * rand_input1_2_array[read_count];
                    product_3 = rand_input0_3_array[read_count] * rand_input1_3_array[read_count];
                    expected_mac_result = product_0 + product_1 + product_2 + product_3;

                    if (memVal_data === expected_mac_result) begin
                        if (read_count < 3 || read_count >= DEPTH-2) begin
                            $display("    [%0d] MAC: 0x%08h (Exp: 0x%08h)",
                                     read_count, memVal_data, expected_mac_result);
                        end
                        else if (read_count == 3) begin
                            $display("    ...");
                        end
                    end
                    else begin
                        $display("    [%0d] MAC: 0x%08h (Exp: 0x%08h) ERROR!",
                                 read_count, memVal_data, expected_mac_result);
                        error_count = error_count + 1;
                    end

                    read_count  = read_count + 1;
                    total_reads = total_reads + 1;
                end
            end

            $display("  Read %0d MAC results from memory", DEPTH);

            // wait until ready again
            wait(RDY_mac);
            $display("  RDY_mac HIGH - ready for next iteration");
            repeat(5) @(posedge CLK);

            $display("  Iteration %0d COMPLETE\n", iteration);
        end

        // summary
        $display("========================================");
        $display("  Test Summary");
        $display("========================================");
        $display("  Total Iterations:   %0d", 8);
        $display("  Total Writes:       %0d", total_writes);
        $display("  Total Reads:        %0d", total_reads);
        $display("  Expected Total:     %0d", DEPTH * 8);
        $display("  Verification Errors:%0d", error_count);
        $display("========================================");
    end
    endtask

    // ==================== TOP-LEVEL SEQUENCE ====================
    initial begin
        TASK_init;
        TASK_reset;
        TASK_DUT;
		  $stop;
    end

endmodule: mkMACBuff_TB
