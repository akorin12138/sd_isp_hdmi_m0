module gaussian_top(
    input  wire         pclk,
    input  wire         rst_n,

    input  wire [7:0]   per_raw_data,
    input  wire         per_raw_clken, 
    output wire [7:0]   post_raw_data,
    output wire         post_raw_clken

);

parameter BITS = 8;
parameter WIDTH = 1936;

	wire [BITS-1:0] shiftout;
	wire [BITS-1:0] tap3x, tap2x, tap1x, tap0x;
	shift_register #(BITS, WIDTH, 4) linebuffer(pclk, per_raw_clken, per_raw_data, shiftout, {tap3x, tap2x, tap1x, tap0x});
	
	reg [BITS-1:0] in_raw_r;
	reg [BITS-1:0] p11,p12,p13,p14,p15;
	reg [BITS-1:0] p21,p22,p23,p24,p25;
	reg [BITS-1:0] p31,p32,p33,p34,p35;
	reg [BITS-1:0] p41,p42,p43,p44,p45;
	reg [BITS-1:0] p51,p52,p53,p54,p55;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			in_raw_r <= 0;
			p11 <= 0; p12 <= 0; p13 <= 0; p14 <= 0; p15 <= 0;
			p21 <= 0; p22 <= 0; p23 <= 0; p24 <= 0; p25 <= 0;
			p31 <= 0; p32 <= 0; p33 <= 0; p34 <= 0; p35 <= 0;
			p41 <= 0; p42 <= 0; p43 <= 0; p44 <= 0; p45 <= 0;
			p51 <= 0; p52 <= 0; p53 <= 0; p54 <= 0; p55 <= 0;
		end
		else begin
			in_raw_r <= per_raw_data;
			p11 <= p12; p12 <= p13; p13 <= p14; p14 <= p15; p15 <= tap3x;
			p21 <= p22; p22 <= p23; p23 <= p24; p24 <= p25; p25 <= tap2x;
			p31 <= p32; p32 <= p33; p33 <= p34; p34 <= p35; p35 <= tap1x;
			p41 <= p42; p42 <= p43; p43 <= p44; p44 <= p45; p45 <= tap0x;
			p51 <= p52; p52 <= p53; p53 <= p54; p54 <= p55; p55 <= in_raw_r;
		end
	end

//----------------------------------------------------------------------
//  [p11,p12,p13,p14,p15]   [32,38,40,38,32]
//  [p21,p22,p23,p24,p25]   [38,45,47,45,38]
//  [p31,p32,p33,p34,p35] * [40,47,50,47,40]
//  [p41,p42,p43,p44,p45]   [38,45,47,45,38]
//  [p51,p52,p53,p54,p55]   [32,38,40,38,32]
reg             [13:0]          mult_result11;
reg             [13:0]          mult_result12;
reg             [13:0]          mult_result13;
reg             [13:0]          mult_result14;
reg             [13:0]          mult_result15;
reg             [13:0]          mult_result21;
reg             [13:0]          mult_result22;
reg             [13:0]          mult_result23;
reg             [13:0]          mult_result24;
reg             [13:0]          mult_result25;
reg             [13:0]          mult_result31;
reg             [13:0]          mult_result32;
reg             [13:0]          mult_result33;
reg             [13:0]          mult_result34;
reg             [13:0]          mult_result35;
reg             [13:0]          mult_result41;
reg             [13:0]          mult_result42;
reg             [13:0]          mult_result43;
reg             [13:0]          mult_result44;
reg             [13:0]          mult_result45;
reg             [13:0]          mult_result51;
reg             [13:0]          mult_result52;
reg             [13:0]          mult_result53;
reg             [13:0]          mult_result54;
reg             [13:0]          mult_result55;

always @(posedge pclk)
begin
    mult_result11 <= p11 * 6'd32;
    mult_result12 <= p12 * 6'd38;
    mult_result13 <= p13 * 6'd40;
    mult_result14 <= p14 * 6'd38;
    mult_result15 <= p15 * 6'd32;
    mult_result21 <= p21 * 6'd38;
    mult_result22 <= p22 * 6'd45;
    mult_result23 <= p23 * 6'd47;
    mult_result24 <= p24 * 6'd45;
    mult_result25 <= p25 * 6'd38;
    mult_result31 <= p31 * 6'd40;
    mult_result32 <= p32 * 6'd47;
    mult_result33 <= p33 * 6'd50;
    mult_result34 <= p34 * 6'd47;
    mult_result35 <= p35 * 6'd40;
    mult_result41 <= p41 * 6'd38;
    mult_result42 <= p42 * 6'd45;
    mult_result43 <= p43 * 6'd47;
    mult_result44 <= p44 * 6'd45;
    mult_result45 <= p45 * 6'd38;
    mult_result51 <= p51 * 6'd32;
    mult_result52 <= p52 * 6'd38;
    mult_result53 <= p53 * 6'd40;
    mult_result54 <= p54 * 6'd38;
    mult_result55 <= p55 * 6'd32;
end

reg             [15:0]          sum_result1;
reg             [15:0]          sum_result2;
reg             [15:0]          sum_result3;
reg             [15:0]          sum_result4;
reg             [15:0]          sum_result5;

always @(posedge pclk)
begin
    sum_result1 <= mult_result11 + mult_result12 + mult_result13 + mult_result14 + mult_result15;
    sum_result2 <= mult_result21 + mult_result22 + mult_result23 + mult_result24 + mult_result25;
    sum_result3 <= mult_result31 + mult_result32 + mult_result33 + mult_result34 + mult_result35;
    sum_result4 <= mult_result41 + mult_result42 + mult_result43 + mult_result44 + mult_result45;
    sum_result5 <= mult_result51 + mult_result52 + mult_result53 + mult_result54 + mult_result55;
end

reg             [17:0]          sum_result;

always @(posedge pclk)
begin
    sum_result <= sum_result1 + sum_result2 + sum_result3 + sum_result4 + sum_result5;
end

reg             [7:0]           pixel_data;

always @(posedge pclk)
begin
    pixel_data <= sum_result[17:10] + sum_result[9];
end

//----------------------------------------------------------------------
	localparam DLY_CLK = 8;
	reg [DLY_CLK-1:0] href_dly;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			href_dly <= 0;
		end
		else begin
			href_dly <= {href_dly[DLY_CLK-2:0], per_raw_clken};
		end
	end

assign post_raw_data = pixel_data;
assign post_raw_clken = href_dly[DLY_CLK-1];

endmodule