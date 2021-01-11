/*
 * Allows the user to control clock speed or single step the cpu.
 */

`default_nettype none

module user_clock(
	input source_clock,

	input step,
	input[1:0] mode,

	output reg out_clock
);

localparam OUT_CLOCK_DIVIDER_SLOW    = 25000000;
localparam OUT_CLOCK_DIVIDER_FAST    = 2000000;
localparam OUT_CLOCK_DIVIDER_FASTEST = 100000;

localparam MODE_SLOW       = 2'b00;
localparam MODE_FAST       = 2'b10;
localparam MODE_FASTEST    = 2'b11;
localparam MODE_SINGLEstep = 2'b01;

wire[31:0] out_clock_divider;
wire is_single_step;
reg[31:0] i;

assign out_clock_divider =
	(mode == MODE_SLOW) ? OUT_CLOCK_DIVIDER_SLOW :
	(mode == MODE_FAST) ? OUT_CLOCK_DIVIDER_FAST :
	(mode == MODE_FASTEST) ? OUT_CLOCK_DIVIDER_FASTEST :
	OUT_CLOCK_DIVIDER_SLOW;
assign is_single_step = (mode == MODE_SINGLEstep);

always @ (negedge source_clock) begin
	if (is_single_step) begin
		out_clock <= step;
	end else begin
		if (i >= out_clock_divider) begin
			i <= 32'b0;
			out_clock <= ~out_clock;
		end else begin
			i <= i + 32'b1;
			out_clock <= out_clock;
		end
	end
end



endmodule
