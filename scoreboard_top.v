`include "scoreboard.v"
`include "hvsync_generator.v"
`include "digits10.v"

module scoreboard_top(clk, reset, hsync, vsync, rgb);
input clk, reset;
output hsync, vsync;
output [2:0] rgb;

wire display_on;
wire [8:0] hpos;
wire [8:0] vpos;

wire board_gfx;

hvsync_generator hvsync_gen(
	.clk(clk),
	.reset(reset),
	.hsync(hsync),
	.vsync(vsync),
	.disdplay_on(display_on),
	.hpos(hpos),
	.vpos(vpos)
);

scoreboard_generator scoreboard_gen(
	.score0(0),
	.score1(1),
	.lives(3),
	.vpos(vpos),
	.hpos(hpos),
	.board_gfx(board_gfx)
);

wire r = display_on && board_gfx;
wire g = display_on && board_gfx;
wire b = display_on && board_gfx;
assign rgb = {b,g,r};
endmodule
