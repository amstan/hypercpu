module hypercpu_rom(
	input[31:0] mem_addr,
	output tri[31:0] mem_read,
	input mem_read_enabled // when low tristate read_data
);

// This code is old, this is why some instructions might be nonsensical
assign mem_read = (!mem_read_enabled) ? 32'bZ : // allow other devices on the bus
	(mem_addr == 32'h_00) ? 32'h_fc210000 : // $2 = $1 + 'h_00
	(mem_addr == 32'h_01) ? 32'h_9cf80002 : // $8 = mem[$pc+2] // 'h_01000000 (RAM)
	(mem_addr == 32'h_02) ? 32'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 32'h_03) ? 32'h_01000000 : // -----
	(mem_addr == 32'h_04) ? 32'h_9cf90002 : // $9 = mem[$pc+2] // 'h_90000000 (Input)
	(mem_addr == 32'h_05) ? 32'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 32'h_06) ? 32'h_90000000 : // -----
	(mem_addr == 32'h_07) ? 32'h_9cfa0002 : // $a = mem[$pc+2] // 'h_a0000000 (Display)
	(mem_addr == 32'h_08) ? 32'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 32'h_09) ? 32'h_a0000000 : // -----
	(mem_addr == 32'h_0a) ? 32'h_9c900011 : // $0 = mem[$9 + 0x11] // Input.Joystick.Y
	(mem_addr == 32'h_0b) ? 32'h_ec010000 : // $1 = $0 + $1
	(mem_addr == 32'h_0c) ? 32'h_bca10001 : // mem[$a + 1] = $1 // Display.Hex
	(mem_addr == 32'h_0d) ? 32'h_ac810000 : // mem[$8 + $1] = $1 // fills RAM with its own address depending on $1
	(mem_addr == 32'h_0e) ? 32'h_fc2f000a : // $pc = $2 + 'h_0a // goto 'h_0a
	32'h0; // NOOP in the unitialized ROM region

endmodule
