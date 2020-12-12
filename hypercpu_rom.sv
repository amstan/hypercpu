module hypercpu_rom(
	input[31:0] mem_addr,
	output tri[31:0] mem_read,
	input mem_read_enabled // when low tristate read_data
);

// This code is old, this is why some instructions might be nonsensical
assign mem_read = (!mem_read_enabled) ? 32'bZ :
	(mem_addr == 'h_00) ? 'h_fc3100fa : // $3 = $1 + 'h_fa
	(mem_addr == 'h_01) ? 'h_9cf80002 : // $8 = mem[$pc+2] // 'h_01000000 (RAM)
	(mem_addr == 'h_02) ? 'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 'h_03) ? 'h_01000000 : // -----
	(mem_addr == 'h_04) ? 'h_9cf90002 : // $9 = mem[$pc+2] // 'h_90000000 (Input)
	(mem_addr == 'h_05) ? 'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 'h_06) ? 'h_90000000 : // -----
	(mem_addr == 'h_07) ? 'h_9cfa0002 : // $a = mem[$pc+2] // 'h_a0000000 (Display)
	(mem_addr == 'h_08) ? 'h_fcff0002 : // $pc = $pc + 2
	(mem_addr == 'h_09) ? 'h_a0000000 : // -----
	(mem_addr == 'h_0a) ? 'h_9c900011 : // $0 = mem[$9 + 11] // Input.Joystick.Y
	(mem_addr == 'h_0b) ? 'h_ec010000 : // $1 = $0 + $1
	(mem_addr == 'h_0c) ? 'h_bca10001 : // mem[$a + 1] = $1 // Display.Hex
	(mem_addr == 'h_0d) ? 'h_ac810000 : // mem[$8 + $1] = $1 // fills RAM with its own address depending on $1
	(mem_addr == 'h_0e) ? 'h_fc2f000a : // $pc = $2 + 'h_0a // goto 'h_0a
	32'h0; // NOOP

endmodule
