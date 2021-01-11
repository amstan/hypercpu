typedef bit[3:0] register_addr;

module hypercpu_registers #(
	parameter REG_COUNT = 16,
	parameter REG_BITS = $clog2(REG_COUNT -1),
	//parameter type  = bit[32:0],

	parameter register_addr SP_ADDR = REG_BITS'(REG_COUNT - 2),
	parameter register_addr PC_ADDR = REG_BITS'(REG_COUNT - 1)
) (
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

always @ (negedge mclk, negedge reset) begin
	if (!reset) begin
		integer i;
		for (i = 0; i < REG_COUNT; i++) begin
			registers[i] <= 0;
		end
	end else begin
		// Special registers always get updated through the backdoor
		registers[SP_ADDR] <= next_sp;
		registers[PC_ADDR] <= next_pc;
		// but they could get overridden later by a write

		if (write_enable) begin
			registers[write_addr] <= write_data;
		end
	end
end

endmodule
