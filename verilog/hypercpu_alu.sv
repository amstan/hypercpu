module hypercpu_alu(
	// Operands
	input[31:0] a,
	input[31:0] b,

	// Operation
	input[3:0] op,

	// Result
	output[31:0] r
);

assign r =
	(op == 4'h_0) ? ~b :
	(op == 4'h_1) ? a & b :
	(op == 4'h_2) ? a | b :
	(op == 4'h_3) ? a ^ b :

	(op == 4'h_4) ? a < b :
	(op == 4'h_5) ? a > b :
	(op == 4'h_6) ? a == b :
	(op == 4'h_7) ? a != b :

	(op == 4'h_8) ? a << b :
	(op == 4'h_9) ? a >> b :
	//(op == 'h_a) ? :
	//(op == 'h_b) ? :

	(op == 4'h_c) ? a + b :
	(op == 4'h_d) ? a - b :
	(op == 4'h_e) ? a * b :
	(op == 4'h_f) ? a / b :
	0;

endmodule
