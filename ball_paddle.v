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
reg inscore;
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
	.inscore(inscore),
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

// Paddle Graphic

wire [5:0] hcell = hpos[8:3];	// horizontal brick index
wire [5:0] vcell = vpos[8:3];	// vertical brick index
wire lr_border = hcell == 0 || hcell == 31;	// along horizontal border?

always @(posedge hsync)
	// hpaddle = 0 (paddle di chuyen)
  // hpaddle = 1 (paddle khong di chuyen)
	if (!hpaddle)
		// biên vi trí doc thành vi trí ngang cua paddle,
		// tao hiêu ưng paddle di chuyên theo chiêu ngang khi vpos thay đôi
		paddle_pos <= vpos;

// TODO: unsigned compare doesn't work in JS
// hpos < paddle_pos, operator AND change value from negative into postive
wire [8:0] paddle_rel_x = ((hpos-paddle_pos) & 9'h1ff);

// player paddle graphics signal
// Check vcell has in row 28
// vcell duoc tinh tu vpos[8:3] (chia toa do doc cho 8 de giam do phan giai)
// 240/8 = 30 vcell
// hpos - paddle_pos < PADDLE_WIDTH thi paddle_gfx = 1 (hien thi mau vang)
wire paddle_gfx = (vcell == 28) && (paddle_rel_x < PADDLE_WIDTH);

// Brick GRAPHIC
reg brick_present;	// 1 when we are drawing a brick
reg [6:0] brick_index;	// index into array of current brick
// brick graphics signal
wire brick_gfx = lr_border || (brick_present && vpos[2:0] != 0 && hpos[3:1] != 4);

// scan bricks: compute brick_index and brick_present flag
always @(posedge clk)
	// see if we are scanning brick area
	// 240/64 = 3, chia khung hinh thanh 4 phan theo chieu doc
	// lay phan thu 2
	if (vpos[8:6] == 1 && !lr_border) begin
		// every 16th pixel, starting at 8
		// brick 16x8, lay o giua khoi gach
		if (hpos[3:0] == 8) begin
			// compute brick index
			// vpos[5:3] - chia khung hinh thanh 30 phan theo chieu doc
			// 					 - lay chieu cao khoi gach la 8
			// hpos[7:4] - chia khung hinh thanh 15 phan theo chieu ngang
			// 					 - lay chieu dai khoi gach la 16
			brick_index <= {vpos[5:3], hpos[7:4]};
			brick_present <= !brick_array[brick_index];
		end
		// // every 17th pixel
		// else if (hpos[3:0] == 9) begin
		// 	// load brick bit from array
		// 	brick_present <= !brick_array[brick_index];
		end
	end else begin
		brick_present <= 0;
	end

// always @(posedge clk)
// 	if (brick_present)
// 		brick_array[brick_index] <= 0;

// Hoa van tren brick
// reg [63:0] brick_patterns [0:3];
// initial begin
// 	// Pattern 0: Gạch caro
//   brick_patterns[0] = 64'b01010101_10101010_01010101_10101010_01010101_10101010_01010101_10101010;
//      
// 	// Pattern 1: Gạch chấm bi
//   brick_patterns[1] = 64'b00000000_00100100_00000000_01000010_00000000_00100100_00000000_00000000;
//            
// 	// Pattern 2: Gạch solid color
//  	brick_patterns[2] = 64'b11111111_11111111_11111111_11111111_11111111_11111111_11111111_11111111;
//                  
// 	// Pattern 3: Gạch gradient
//  	brick_patterns[3] = 64'b00000000_00011000_00111100_01111110_01111110_00111100_00011000_00000000;
// end
// 
// wire [1:0] pattern_id = brick_index[6:5]; // Chon 1 trong 4 hoa van (tuy chinh)
// wire [2:0] row_in_pattern = vpos[2:0];		// Hang trong mau 8x8 (0-7)
// wire [2:0] col_in_pattern = hpos[2:0];		// Cot trong mau 8x8 (0-7)
// wire pattern_bit = brick_patterns[pattern_id][row_in_pattern * 8 + col_in_pattern];

// BALL GRAPHIC
// difference between ball position and video beam
wire [8:0] ball_rel_x = (hpos - ball_x);
wire [8:0] ball_rel_y = (vpos - ball_y);

// ball graphics signal
wire ball_gfx = ball_rel_x < BALL_SIZE && ball_rel_y < BALL_SIZE;

always @(posedge vsycn or posedge reset) begin
	if (reset) begin
		ball_x <= 128;
		ball_y <= 180;
	end else begin
		// move ball horizontal and vertical position
		if (ball_dir_x == BALL_DIR_RIGHT)
			ball_x <= ball_x + (ball_speed_x?1:0) + 1;
		else
			ball_x <= ball_x - (ball_speed_x?1:0) - 1;
		ball_y <= ball_y + (ball_dir_y==BALL_DIR_DOWN?1:-1);
	end
end

reg main_gfx;				// main graphics signal (bricks and borders)
// 1 when ball signal intersects main (brick + border) signal
wire ball_pixel_collide = main_gfx & ball_gfx;

reg ball_collide_paddle = 0; // Ghi nhan va cham voi paddle
reg [3:0] ball_collide_bits = 0; // Ghi nhan goc va cham

// compute ball collisions with paddle and playfield
always @(posedge clk)
	// clear all collide bits for frame
	if (vysnc) begin // reset trang thai moi frame
		ball_collide_bits <= 0;
		ball_collide_paddle <= 0;
	end else begin
		if (ball_pixel_collide) begin
			// did we collide w/ paddle? - Va cham voi paddle
			if (paddle_gfx) begin
				ball_collide_paddle <= 1;
			end
			// ball has 4 collision quadrants - Xac dinh 4 goc va cham
			// Bit[2]: chia bong thanh 4 phan (vi bong co kich thuoc 6x6 pixel, moi
			// goc ~3x3 pixel)
			// Bong cham tren-trai
			if (!ball_rel_x[2] & !ball_rel_y[2]) ball_collide_bits[0] <= 1;
			// Bong cham tren-phai
			if (ball_rel_x[2] & !ball_rel_y[2]) ball_collide_bits[1] <= 1;
			// Bong cham duoi-trai
			if (!ball_rel_x[2] & ball_rel_y[2]) ball_collide_bits[2] <= 1;
			// Bong cham duoi-phai
			if (ball_rel_x[2] & ball_rel_y[2]) ball_collide_bits[3] <= 1;
		end
	end

// compute ball collisions with brick and increment score
always @(posedge clk)
	if (ball_pixel_collide && brick_present) begin
		brick_array[brick_index] <= 1;
		inscore <= 1; // increment score
	end else begin
		inscore <= 0; // reset inscore
	end

// computes position of ball in relation to center of paddle
wire signed [8:0] ball_paddle_dx = ball_x - paddle_pos + 8;

// ball bounce: determine new velocity/direction
always @(posedge vsync or posedge reset) begin
	if (reset) begin
		ball_dir_y <= BALL_DIR_DOWN;
	end else if (ball_collide_paddle) begin // ball collided with paddle?
		// bounces upward off of paddle
		ball_dir_y <= BALL_DIR_UP;
		// which side of paddle, left/right?
		ball_dir_x <= (ball_paddle_dx < 20) ? BALL_DIR_LEFT : BALL_DIR_RIGHT;
		// hitting with edge of paddle makes it fast
		ball_speed_x <= ball_collide_bits[3:0] != 4'b1100;
	end else begin
		// collided with playfield
		// TODO: can still slip through corners
		// compute left/right bounce
		casez	(ball_collide_bits[3:0])
			4'b01?1: ball_dir_x <= BALL_DIR_RIGHT; 	// left edge/corner
			4'b1101: ball_dir_x <= BALL_DIR_RIGHT;	// left corner
			4'b101?: ball_dir_x <= BALL_DIR_LEFT;		// right edge/corner
			4'b1110: ball_dir_x <= BALL_DIR_LEFT; 	// right corner
			default: ;
		endcase
		// compute top/bottom bounce
		casez (ball_collide_bits[3:0])
			4'b1011: ball_dir_y <= BALL_DIR_DOWN;
			4'b0111: ball_dir_y <= BALL_DIR_DOWN;
			4'b001?: ball_dir_y <= BALL_DIR_DOWN;
			4'b0001: ball_dir_y <= BALL_DIR_DOWN;
			4'b0100: ball_dir_y <= BALL_DIR_UP;
			4'b1?00: ball_dir_y <= BALL_DIR_UP;
			4'b1101: ball_dir_y <= BALL_DIR_UP;
			4'b1110: ball_dir_y <= BALL_DIR_UP;
			default: ;
		endcase
	end
end


// compute main_gfx
always @(*) begin
	case (vpos[8:3])
		0,1,2: main_gfx = score_gfx; // scoreboard
		3: main_gfx = 0;
		4: main_gfx = 1;
		8,9,10,11,12,13,14,15: main_gfx = brick_gfx; // brick rows 1-8
		28: main_gfx = paddle_gfx | lr_border; // paddle
		29: main_gfx = hpos[0] ^ vpos[0]; // bottom border
		default: main_gfx = lr_border; // left/right borders
	endcase
end

// combine signals to RGB output
wire grid_gfx = (((hpos&7)==0) || ((vpos&7)==0));
wire r = display_on && (ball_gfx | paddle_gfx);
wire g = display_on && (ball_gfx | main_gfx);
wire b = display_on && (ball_gfx | grid_gfx | brick_present);

assign rgb = {b,g,r};
endmodule
