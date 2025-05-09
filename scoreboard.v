`ifndef SCOREBOARD_H
`define SCOREBOARD_H

`include "hvsync_generator.v"
`include "digits10.v"

/*
* player_stats - Holds two-digit score and one-digit lives counter
* scoreboard_generator - Outputs video signal with score/lives digits
*/
module player_stats(reset, score0, score1, lives, inscore, declives);

input reset;
output reg [3:0] score0;
output reg [3:0] score1;
input inscore;
output reg [3:0] lives;
input declives;

always @(posedge inscore or posedge reset) begin
	if (reset) begin
		score0 <= 0;
		score1 <= 0;
	end else if (score0 == 9) begin
		score0 <= 0;
		score1 <= score1 + 1;
	end else begin
		score0 <= score0 + 1;
	end
end

always @(posedge declives or posedge reset) begin
	if (reset) begin
		lives <= 3;
	end else if (lives != 0) begin
		lives <= lives - 1;
	end
end
endmodule

module scoreboard_generator(score0, score1, lives, vpos, hpos, board_gfx);

input [3:0] score0;
input [3:0] score1;
input [3:0] lives;
input [8:0] vpos;
input [8:0] hpos;
output board_gfx;

reg [3:0] score_digit;
reg [4:0] score_bits;

always @(*) begin
	case (hpos[7:5])
		1: score_digit = score1;
		2: score_digit = score0;
		6: score_digit = lives;
		default: score_digit = 15; // no digit
	endcase
end

digits10_array digits(
	.digit(score_digit),
	.yofs(vpos[4:2]),
	.bits(score_bits)
);

assign board_gfx = score_bits[hpos[4:2] ^ 3'b111];
endmodule
`endif
