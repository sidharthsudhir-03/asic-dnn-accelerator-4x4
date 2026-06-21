module multiplier(CLK, EN, IN0, IN1, OUT, OUT_VALID);

	input logic CLK, EN;
	input logic [15:0] IN0, IN1;
	output logic OUT_VALID;
	output logic [31:0] OUT;
	
	// 1st stage
	logic STAGE1;
	logic [7:0] partials_4bmult [15:0];
	logic [7:0] stage1_regs [15:0];
	
	assign partials_4bmult[0] = IN0[3:0] * IN1[3:0];
	assign partials_4bmult[1] = IN0[3:0] * IN1[7:4];
	assign partials_4bmult[2] = IN0[3:0] * IN1[11:8];
	assign partials_4bmult[3] = IN0[3:0] * IN1[15:12];

	assign partials_4bmult[4] = IN0[7:4] * IN1[3:0];
	assign partials_4bmult[5] = IN0[7:4] * IN1[7:4];
	assign partials_4bmult[6] = IN0[7:4] * IN1[11:8];
	assign partials_4bmult[7] = IN0[7:4] * IN1[15:12];

	assign partials_4bmult[8] = IN0[11:8] * IN1[3:0];
	assign partials_4bmult[9] = IN0[11:8] * IN1[7:4];
	assign partials_4bmult[10] = IN0[11:8] * IN1[11:8];
	assign partials_4bmult[11] = IN0[11:8] * IN1[15:12];

	assign partials_4bmult[12] = IN0[15:12] * IN1[3:0];
	assign partials_4bmult[13] = IN0[15:12] * IN1[7:4];
	assign partials_4bmult[14] = IN0[15:12] * IN1[11:8];
	assign partials_4bmult[15] = IN0[15:12] * IN1[15:12];
	
	always @(posedge CLK) begin
        STAGE1 <= EN;
        stage1_regs[0] <= partials_4bmult[0];
        stage1_regs[1] <= partials_4bmult[1];
        stage1_regs[2] <= partials_4bmult[2];
        stage1_regs[3] <= partials_4bmult[3];
        stage1_regs[4] <= partials_4bmult[4];
        stage1_regs[5] <= partials_4bmult[5];
        stage1_regs[6] <= partials_4bmult[6];
        stage1_regs[7] <= partials_4bmult[7];
        stage1_regs[8] <= partials_4bmult[8];
        stage1_regs[9] <= partials_4bmult[9];
        stage1_regs[10] <= partials_4bmult[10];
        stage1_regs[11] <= partials_4bmult[11];
        stage1_regs[12] <= partials_4bmult[12];
        stage1_regs[13] <= partials_4bmult[13];
        stage1_regs[14] <= partials_4bmult[14];
        stage1_regs[15] <= partials_4bmult[15];
	end
	
	// 2nd stage
	logic STAGE2;
	logic [19:0] partials_add0, stage2_regs0;
	logic [31:0] partials_add1, stage2_regs1;

	assign partials_add0 = {12'd0, stage1_regs[0]} + {8'd0, stage1_regs[1], 4'd0} + {4'd0, stage1_regs[2], 8'd0} + {4'd0, stage1_regs[8], 8'd0} 
						   + {8'd0, stage1_regs[4], 4'd0} + {4'd0, stage1_regs[5], 8'd0};

	assign partials_add1 = {12'd0, stage1_regs[9], 12'd0} + {8'd0, stage1_regs[10], 16'd0} + {4'd0, stage1_regs[11], 20'd0} + {12'd0, stage1_regs[12], 12'd0} 
						    + {8'd0, stage1_regs[13], 16'd0} + {4'd0, stage1_regs[14], 20'd0} + {stage1_regs[15], 24'd0} + {4'd0, stage1_regs[6], 12'd0} 
							+ {stage1_regs[7], 16'd0} + {4'd0, stage1_regs[3], 12'd0};

	
	always @(posedge CLK) begin
        STAGE2 <= STAGE1;
        stage2_regs1 <= partials_add1;
        stage2_regs0 <= partials_add0;
	end
	
	// 3rd stage
	logic STAGE3;
	logic [31:0] final_sum;
	logic [31:0] output_val_reg;

	assign final_sum = stage2_regs0 + stage2_regs1;

	always @(posedge CLK) begin
		STAGE3 <= STAGE2;
		output_val_reg <= final_sum;
	end
	
	assign OUT_VALID = STAGE3;
	assign OUT = output_val_reg;
	
endmodule

 
