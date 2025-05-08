`include "hvsync_generator.v"
`include "digits10.v"
`include "scoreboard.v"

/*
* A brick-smashing ball-and-paddle game
*/

module ball_paddle_top(clk, reset, hpaddle, hsync, vsync, rgb);

input clk, reset;
input hpaddle;
output hsync, vsync;
output [2:0] rgb;

wire display_on;
wire [8:0] hpos;
wire [8:0] vpos;

wire [3:0] score0; 	// score right digit
wire [3:0] score1; 	// score left digit
wire [3:0] lives; 	// # lives remaining
reg incscore;
reg declives = 0; 	// TODO

hvsync_generator hvysnc_gen(
	.clk(clk),
	.reset(reset),
	.hsync(hsync),
	.vsync(vsync),
	.display_on(display_on),
	.hpos(hpos),
	.vpos(vpos)
);

// scoreboard
wire score_gfx; // output from score generator
player_stats stats(
	.reset(reset),
	.score0(score0),
	.score1(score1),
	.incscore(incscore),
	.lives(lives),
	.declives(declives)
);

scoreboard_generator score_gen(
	.score0(score0),
	.score1(score1),
	.lives(lives),
	.vpos(vpos),
	.hpos(hpos),
	.board_gfx(score_gfx)
);

reg [8:0] paddle_pos; // paddle X position

reg [8:0] ball_x; 		// ball X position
reg [8:0] ball_y;			// ball Y position
reg ball_dir_x;				// ball X direction (0=left, 1=right)
reg ball_speed_x;			// ball speed (0=1 pixel/frame, 1=2 pixels/frame)
reg ball_dir_y;				// ball Y direction (0=up, 1=down)

reg brick_array [0:BRICKS_H*BRICKS_V-1]; // 16*8 = 128 bits

localparam BRICKS_H = 16;	// # of bricks across
localparam BRICKS_V = 8;	// # of bricks down

localparam BALL_DIR_LEFT = 0;
localparam BALL_DIR_RIGHT = 1;
localparam BALL_DIR_DOWN = 1;
localparam BALL_DIR_UP = 0;

localparam PADDLE_WIDTH = 31;	// horizontal paddle size
localparam BALL_SIZE = 6;			// square ball size

wire [5:0] hcell = hpos[8:3];	// horizontal brick index
wire [5:0] vcell = vpos[8:3];	// vertical brick index
wire lr_border = hcell == 0 || hcell == 31;	// along horizontal border?

// TODO: unsigned compare doesn't work in JS
wire [8:0] paddle_rel_x = ((hpos-paddle_pos) & 9'h1ff);

// player paddle graphics signal
wire paddle_gfx = (vcell == 28) && (paddle_rel_x < PADDLE_WIDTH);

// difference between ball position and video beam
wire [8:0] ball_rel_x = (hpos - ball_x);
wire [8:0] ball_rel_y = (vpos - ball_y);

// ball graphics signal
wire ball_gfx = ball_rel_x < BALL_SIZE && ball_rel_y < BALL_SIZE;

reg main_gfx;				// main graphics signal (bricks and borders)
reg brick_present;	// 1 when we are drawing a brick
reg [6:0] brick_index;	// index into array of current brick
// brick graphics signal
wire brick_gfx = lr_border || (brick_present && vpos[2:0] != 0 && hpos[3:1] != 4);

// scan bricks: compute brick_index and brick_present flag
always @(posedge clk)
	// see if we are scanning brick area
	if (vpos[8:6] == 1 && !lr_border) begin
		// every 16th pixel, starting at 8
		if (hpos[3:0] == 8) begin
			brick_index <= {vpos[5:3], hpos[7:4]};
		end
	end

// combine signals to RGB output
wire grid_gfx = (((hpos&7)==0) || ((vpos&7)==0));
wire r = display_on && 0;
wire g = display_on && 0;
wire b = display_on && grid_gfx;

assign rgb = {b,g,r};
endmodule
