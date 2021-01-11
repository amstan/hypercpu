module hypercpu_rom(
	input[31:0] mem_addr,
	output tri[31:0] mem_read,
	input mem_read_enabled // when low tristate read_data
);

// This code is old, this is why some instructions might be nonsensical
assign mem_read = (!mem_read_enabled) ? 32'bZ : // allow other devices on the bus
	`include "build/rom.verilog_trenary"
	32'h0; // NOOP in the unitialized ROM region

endmodule
