module mkMACBuff (
    CLK, RST_N,
    //
    EN_mac, RDY_mac,
    mac_vectA_0, mac_vectB_0,
    mac_vectA_1, mac_vectB_1,
    mac_vectA_2, mac_vectB_2,
    mac_vectA_3, mac_vectB_3,
    //
    EN_writeMem, writeMem_addr, writeMem_val,
    //
    EN_blockRead, RDY_blockRead,
    //
    EN_readMem, readMem_addr, readMem_val,
    //
    VALID_memVal, memVal_data
);

    // ==================== PARAMETERS ====================
    parameter WIDTH      = 16;
    parameter DEPTH      = 64;
    parameter ADDR_WIDTH = 6;
    localparam int HALF          = WIDTH / 2;
    localparam int RESULT_WIDTH  = 2 * WIDTH;  // 32-bit results from 16x16 mult

    // ==================== PORT DECLARATIONS ====================
    input  logic CLK, RST_N;

    // MAC Input Interface (2x2 = 4 multiply operations)
    input  logic EN_mac;
    output logic RDY_mac;
    input  logic [WIDTH-1:0] mac_vectA_0, mac_vectB_0;
    input  logic [WIDTH-1:0] mac_vectA_1, mac_vectB_1;
    input  logic [WIDTH-1:0] mac_vectA_2, mac_vectB_2;
    input  logic [WIDTH-1:0] mac_vectA_3, mac_vectB_3;

    // Write Memory Interface
    output logic                  EN_writeMem;
    output logic [ADDR_WIDTH-1:0] writeMem_addr;
    output logic [RESULT_WIDTH+1:0] writeMem_val;

    // Block Read Interface
    input  logic EN_blockRead;
    output logic RDY_blockRead;

    // Read Memory Interface
    output logic                  EN_readMem;
    output logic [ADDR_WIDTH-1:0] readMem_addr;
    input  logic [RESULT_WIDTH+1:0] readMem_val;

    // Output Data
    output logic                    VALID_memVal;
    output logic [RESULT_WIDTH+1:0] memVal_data;

    // ==================== SIGNAL DECLARATIONS ====================

    // FSM States
    typedef enum logic [1:0] {
        MULTIPLY_STATE = 2'b00,
        FULL_STATE     = 2'b01,
        READ_STATE     = 2'b10
    } state_t;

    state_t current_state, next_state;

    // Multiplier outputs (4 parallel multipliers for 2x2 MAC)
    logic [RESULT_WIDTH-1:0] mult_out_0, mult_out_1, mult_out_2, mult_out_3;
    logic mult_valid_0, mult_valid_1, mult_valid_2, mult_valid_3;
    logic all_mult_valid;

    // Accumulator output (sum of 4 multiplier results)
    logic [RESULT_WIDTH+1:0] partial_result0, partial_result1;
    logic partial_valid;

    // Memory control signals
    logic [ADDR_WIDTH-1:0] write_addr_counter;
    logic memory_full;
    logic read_done;

    // Read pipeline signals
    logic                  EN_blockRead_read1, EN_blockRead_read2;
    logic [ADDR_WIDTH:0] read_addr_r1, read_addr_r2;


    // ==================== FSM FOR STATE MANAGEMENT ====================

    // FSM: State Register (synchronous reset)
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            current_state <= MULTIPLY_STATE;
				RDY_mac <= 1'b1;
				RDY_blockRead <= 1'b0;
        end else begin
            case(current_state)
				MULTIPLY_STATE: begin
		            if (memory_full) begin
							current_state <= FULL_STATE;
							RDY_mac <= 1'b0;
							RDY_blockRead <= 1'b1;
		            end else if (write_addr_counter <= DEPTH - 6)begin
							current_state <= MULTIPLY_STATE;
							RDY_mac <= 1'b1;
							RDY_blockRead <= 1'b0;
						end
						else begin
							current_state <= MULTIPLY_STATE;
							RDY_mac <= 1'b0;
							RDY_blockRead <= 1'b0;		
						end
		        end

		        FULL_STATE: begin
		            if (EN_blockRead) begin
		                current_state <= READ_STATE;
						RDY_mac <= 1'b0;
						RDY_blockRead <= 1'b0;
		            end else begin
		                current_state <= FULL_STATE;
						RDY_mac <= 1'b0;
						RDY_blockRead <= 1'b1;
						end
					end

		        READ_STATE: begin
		            if (read_done) begin
		               current_state <= MULTIPLY_STATE;
							RDY_mac <= 1'b1;
							RDY_blockRead <= 1'b0;
		            end else begin
		               current_state <= READ_STATE;
							RDY_mac <= 1'b0;
							RDY_blockRead <= 1'b0;
						end
		        end
				
				default: begin
					current_state <= MULTIPLY_STATE;
					RDY_mac <= 1'b1;
					RDY_blockRead <= 1'b0;
				end
			endcase
		end	
    end

    // ==================== INSTANTIATE 4 MULTIPLIERS (2x2 MAC) ====================

    multiplier mult_0 (
        .CLK (CLK),
        .EN  (EN_mac),
        .IN0 (mac_vectA_0),
        .IN1 (mac_vectB_0),
        .OUT (mult_out_0),
        .OUT_VALID (mult_valid_0)
    );

    multiplier mult_1 (
        .CLK (CLK),
        .EN  (EN_mac),
        .IN0 (mac_vectA_1),
        .IN1 (mac_vectB_1),
        .OUT (mult_out_1),
        .OUT_VALID (mult_valid_1)
    );

    multiplier mult_2 (
        .CLK (CLK),
        .EN  (EN_mac),
        .IN0 (mac_vectA_2),
        .IN1 (mac_vectB_2),
        .OUT (mult_out_2),
        .OUT_VALID (mult_valid_2)
    );

    multiplier mult_3 (
        .CLK (CLK),
        .EN  (EN_mac),
        .IN0 (mac_vectA_3),
        .IN1 (mac_vectB_3),
        .OUT (mult_out_3),
        .OUT_VALID (mult_valid_3)
    );

    // All multipliers are synchronized, so check any one for validity
    assign all_mult_valid = mult_valid_0 && mult_valid_1 && mult_valid_2 && mult_valid_3;

    // ==================== ACCUMULATE (2x2 MAC = dot product) ====================

    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            partial_result0 <= '0;
            partial_result1 <= '0;
            partial_valid   <= 1'b0;
        end else begin
            partial_result0 <= mult_out_0 + mult_out_1;
            partial_result1 <= mult_out_2 + mult_out_3;
            partial_valid   <= all_mult_valid;
        end
    end

    // ==================== MEMORY WRITE INTERFACE ====================

    // Write address counter
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            write_addr_counter <= '0;
			memory_full <= 1'b0;
        end else if (partial_valid) begin
            if (write_addr_counter == DEPTH - 1) begin
                write_addr_counter <= '0;
				memory_full <= 1'b1;
            end else begin
                write_addr_counter <= write_addr_counter + 1;
				memory_full <= 1'b0;
			end
        end else begin
			write_addr_counter <= '0;
			memory_full <= 1'b0;
		end
    end

    // Write memory interface outputs
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            EN_writeMem   <= 1'b0;
            writeMem_addr <= '0;
            writeMem_val  <= '0;
        end else begin
            EN_writeMem   <= partial_valid;
            writeMem_addr <= write_addr_counter;
            writeMem_val  <= partial_result0 + partial_result1;
        end
    end

    // ==================== READ PATH PIPELINE ====================

    // Stage 1: D/R1 - Initiate block read, generate addresses
    always_ff @(posedge CLK) begin
		 if (!RST_N) begin
			  EN_blockRead_read1 <= 1'b0;
			  EN_readMem         <= 1'b0;
			  read_addr_r1       <= '0;
			  readMem_addr       <= '0;
		 end else if (current_state == READ_STATE) begin
			  readMem_addr <= read_addr_r1;
			  if (read_addr_r1 == DEPTH) begin
					read_addr_r1       <= '0;
					EN_blockRead_read1 <= 1'b0;
					EN_readMem         <= 1'b0;
			  end else begin
					read_addr_r1       <= read_addr_r1 + 1;
					EN_blockRead_read1 <= 1'b1;
					EN_readMem         <= 1'b1;
			  end
		 end else begin
			  EN_blockRead_read1 <= 1'b0;
			  EN_readMem         <= 1'b0;
			  read_addr_r1       <= '0;
			  readMem_addr       <= '0;
		 end
	end

    // Stage 2: R1/R2 - Capture read data and output
    always_ff @(posedge CLK) begin
        if (!RST_N) begin
            EN_blockRead_read2 <= 1'b0;
            read_addr_r2       <= '0;
            VALID_memVal       <= 1'b0;
            memVal_data        <= '0;
        end else begin
            EN_blockRead_read2 <= EN_blockRead_read1;
            read_addr_r2       <= read_addr_r1;
            if (EN_blockRead_read2) begin
					VALID_memVal <= EN_blockRead_read2;
					memVal_data <= readMem_val;
            end else begin                
					VALID_memVal <= 1'b0;
               memVal_data  <= '0;
            end
        end
    end

    // Read done signal - asserts when all DEPTH items have been read
    always_comb begin
        read_done = (EN_blockRead_read2 && (read_addr_r2 == DEPTH - 1));
    end

endmodule : mkMACBuff
