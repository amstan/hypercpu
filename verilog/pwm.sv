module pwm(
	input[11:0] value,
	input clock,

	output out
);

reg[11:0] i;

always @ (negedge clock) begin
	i <= i + 1'b1;
end

assign out = i < value;

endmodule
