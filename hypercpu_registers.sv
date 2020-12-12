localparam REG_COUNT = 16;
localparam REG_BITS = $clog2(REG_COUNT);
typedef bit[REG_BITS-1:0] register_addr;

localparam FIRST_SPECIAL_REG_ADDR = REG_COUNT - 2;
localparam SP_ADDR                = REG_COUNT - 2;
localparam PC_ADDR                = REG_COUNT - 1;

module hypercpu_registers(
	// Put something in read_*_addr, get it back via read_*_data
	input register_addr read_a_addr,
	input register_addr read_b_addr,
	output[31:0] read_a_data,
	output[31:0] read_b_data,

	// If you want to write a register, set write_en and provide the addr and data
	input register_addr write_addr,
	input[31:0] write_data,
	input write_enable,

	// Backdoor way to access these special registers for normal (not register read/set) cpu operation
	input[31:0] next_sp,
	input[31:0] next_pc,
	output[31:0] read_sp,
	output[31:0] read_pc,

	// Meta
	input mclk,  // TODO: Why doesn't the (.*) syntax work here?
	input reset
);

reg[31:0] registers[REG_COUNT-1:0];

assign read_a_data = registers[read_a_addr];
assign read_b_data = registers[read_b_addr];
assign read_sp     = registers[SP_ADDR];
assign read_pc     = registers[PC_ADDR];

// This is normally next_*, but sometimes we must overwrite them via a write request
wire overwrite_sp = write_enable && (write_addr != SP_ADDR) ? write_data : next_sp;
wire overwrite_pc = write_enable && (write_addr != PC_ADDR) ? write_data : next_pc;
// TODO: is there a simpler way to do this so I don't have to special case the assignment with an if later on?

always @ (negedge mclk, negedge reset) begin
	if (!reset) begin
		integer i;
		for (i = 0; i < REG_COUNT; i++) begin
			registers[i] <= 0;
		end
	end else begin
		if (write_enable) begin
			if (write_addr < FIRST_SPECIAL_REG_ADDR) begin // special registers happen anyway later
				registers[write_addr] = write_data;
				//TODO: Can i rewrite this so it overwrites the special registers if needed so i don't need the FIRST_SPECIAL_REG_ADDR condition?
			end
		end

		// Special registers always get updated
		registers[SP_ADDR] <= overwrite_sp;
		registers[PC_ADDR] <= overwrite_pc;
	end
end

endmodule
