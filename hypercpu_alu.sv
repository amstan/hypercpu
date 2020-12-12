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
	(op == 'h_0) ? ~a :
	(op == 'h_1) ? a & b :
	(op == 'h_2) ? a | b :
	(op == 'h_3) ? a ^ b :

	(op == 'h_4) ? a < b :
	(op == 'h_5) ? a > b :
	(op == 'h_6) ? a == b :
	(op == 'h_7) ? a != b :

	(op == 'h_8) ? a << b :
	(op == 'h_9) ? a >> b :
	//(op == 'h_a) ? :
	//(op == 'h_b) ? :

	(op == 'h_c) ? a + b :
	(op == 'h_d) ? a - b :
	(op == 'h_e) ? a * b :
	(op == 'h_f) ? a / b :
	0;

endmodule
