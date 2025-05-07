`include "digits10.v"
`include "hvsync_generator.v"

// test module
module test_numbers_top(clk, reset, hsync, vsync, rgb);
input clk, reset; 		// clock and reset signals (input)
output hsync, vsync; 	// H/V sync signals (output)
output [2:0] rgb;			// RGB output (BGR order)

wire display_on;
wire [8:0] hpos;			// 9-bit horizontal position
wire [8:0] vpos;			// 9-bit vertical position

// Include the H-V Sync Generator module and
// wire it to inputs, outputs, and wires
hvsync_generator hvsync_gen(
	.clk(clk),
	.reset(reset),
	.hsync(hsync),
	.vsync(vsync),
	.display_on(display_on),
	.hpos(hpos),
	.vpos(vpos)
);

wire [3:0] digit = hpos[7:4];
wire [2:0] xofs = hpos[3:1];
wire [2:0] yofs = vpos[3:1];
wire [4:0] bits;

digits10_array numbers(
	.digit(digit),
	.yofs(yofs),
	.bits(bits)
);

// Assign each color bit to individual wires
wire g = display_on && bits[xofs ^ 3'b111];
wire b = display_on && 0;

wire r = display_on & (((hpos&7)==0) | ((vpos&7)==0));
wire g = display_on & vpos[4];
wire b = display_on & hpos[4];
assign rgb = {b,g,r};
endmodule
