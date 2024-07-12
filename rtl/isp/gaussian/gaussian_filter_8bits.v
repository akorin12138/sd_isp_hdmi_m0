module gaussian_top(
    input  wire         pclk,
    input  wire         rst_n,

    input  wire [7:0]   per_raw_data,
    input  wire         per_raw_clken, 
    output wire [7:0]   post_raw_data,
    output wire         post_raw_clken

);

//  [p1,p2,p3]   [109,115,109]
//  [p4,p5,p6]   [115,122,115]
//  [p7,p8,p9] * [109,115,109]  sigma=3

//  [p1,p2,p3]   [104,118,104]
//  [p4,p5,p6]   [118,133,118]
//  [p7,p8,p9] * [104,118,104]  sigma=2

//  [p1,p2,p3]   [76 ,126,76 ]
//  [p4,p5,p6]   [126,209,126]
//  [p7,p8,p9] * [76 ,126,76 ]  sigma=1

`define sigma1
`ifdef sigma3
parameter gaup11 = 'd109;
parameter gaup12 = 'd115;
parameter gaup13 = 'd109;
parameter gaup21 = 'd115;
parameter gaup22 = 'd122;
parameter gaup23 = 'd115;
parameter gaup31 = 'd109;
parameter gaup32 = 'd115;
parameter gaup33 = 'd109;
parameter DWIDTH = 'd7;
`endif 

`ifdef sigma2
parameter gaup11 = 'd104;
parameter gaup12 = 'd118;
parameter gaup13 = 'd104;
parameter gaup21 = 'd118;
parameter gaup22 = 'd133;
parameter gaup23 = 'd118;
parameter gaup31 = 'd104;
parameter gaup32 = 'd118;
parameter gaup33 = 'd104;
parameter DWIDTH = 'd8;
`endif 

`ifdef sigma1
parameter gaup11 = 'd76	;
parameter gaup12 = 'd126;
parameter gaup13 = 'd76	;
parameter gaup21 = 'd126;
parameter gaup22 = 'd209;
parameter gaup23 = 'd126;
parameter gaup31 = 'd76	;
parameter gaup32 = 'd126;
parameter gaup33 = 'd76	;
parameter DWIDTH = 'd8;
`endif 

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

	reg odd_pix;
	reg [5:0]in_href_r;
	always @ (posedge pclk or negedge rst_n)
		if (!rst_n)begin
			in_href_r <= 4'd0;
		end
		else begin
			in_href_r <= {in_href_r[4:0],per_raw_clken};
		end
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n)
			odd_pix <= 0;
		else if (in_href_r[3])
			odd_pix <= ~odd_pix;
		else
			odd_pix <= odd_pix;
	end
	wire odd_pix_sync_shift = odd_pix;
	
	reg [11:0] herfcnt;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) 
			herfcnt <= 12'd0;
		else if(herfcnt != 12'd1935 && in_href_r[3] == 1'b1)
			herfcnt <= herfcnt + 1'b1;
        else if(herfcnt == 12'd1935 && in_href_r[3] == 1'b1)
			herfcnt <= 12'd0;
        else herfcnt <= herfcnt;
	end	
	
	reg odd_line;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) 
			odd_line <= 0;
		else if (herfcnt == 12'd1935 && in_href_r[3] == 1'b1)
			odd_line <= ~odd_line;
		else
			odd_line <= odd_line;
	end
	wire odd_line_sync_shift = odd_line;

	wire [1:0] p33_fmt = {odd_line_sync_shift, odd_pix_sync_shift}; //pixel format 0:[R]GGB 1:R[G]GB 2:RG[G]B 3:RGG[B]

	reg [BITS-1:0] t1_p1, t1_p2, t1_p3;
	reg [BITS-1:0] t1_p4, t1_p5, t1_p6;
	reg [BITS-1:0] t1_p7, t1_p8, t1_p9;
	always @ (posedge pclk or negedge rst_n) begin
		if (!rst_n) begin
			t1_p1 <= 0; t1_p2 <= 0; t1_p3 <= 0;
			t1_p4 <= 0; t1_p5 <= 0; t1_p6 <= 0;
			t1_p7 <= 0; t1_p8 <= 0; t1_p9 <= 0;
		end
		else begin
			case (p33_fmt)
				2'd1,2'd2: begin //R/B
					t1_p1 <= p11; t1_p2 <= p13; t1_p3 <= p15;
					t1_p4 <= p31; t1_p5 <= p33; t1_p6 <= p35;
					t1_p7 <= p51; t1_p8 <= p53; t1_p9 <= p55;
				end
				2'd3,2'd0: begin //Gr/Gb
					t1_p1 <= p22; t1_p2 <= p13; t1_p3 <= p24;
					t1_p4 <= p31; t1_p5 <= p33; t1_p6 <= p35;
					t1_p7 <= p42; t1_p8 <= p53; t1_p9 <= p44;
				end
				default: begin
					t1_p1 <= 0; t1_p2 <= 0; t1_p3 <= 0;
					t1_p4 <= 0; t1_p5 <= 0; t1_p6 <= 0;
					t1_p7 <= 0; t1_p8 <= 0; t1_p9 <= 0;
				end
			endcase
		end
	end

//----------------------------------------------------------------------

reg             [DWIDTH+8-1:0]          mult_result11;
reg             [DWIDTH+8-1:0]          mult_result12;
reg             [DWIDTH+8-1:0]          mult_result13;
reg             [DWIDTH+8-1:0]          mult_result21;
reg             [DWIDTH+8-1:0]          mult_result22;
reg             [DWIDTH+8-1:0]          mult_result23;
reg             [DWIDTH+8-1:0]          mult_result31;
reg             [DWIDTH+8-1:0]          mult_result32;
reg             [DWIDTH+8-1:0]          mult_result33;

always @(posedge pclk)
begin
    mult_result11 <= t1_p1 * gaup11;
    mult_result12 <= t1_p2 * gaup12;
    mult_result13 <= t1_p3 * gaup13;
    mult_result21 <= t1_p4 * gaup21;
    mult_result22 <= t1_p5 * gaup22;
    mult_result23 <= t1_p6 * gaup23;
    mult_result31 <= t1_p7 * gaup31;
    mult_result32 <= t1_p8 * gaup32;
    mult_result33 <= t1_p9 * gaup33;
end

reg             [DWIDTH+8+2-1:0]          sum_result1;
reg             [DWIDTH+8+2-1:0]          sum_result2;
reg             [DWIDTH+8+2-1:0]          sum_result3;


always @(posedge pclk)
begin
    sum_result1 <= mult_result11 + mult_result12 + mult_result13 ;
    sum_result2 <= mult_result21 + mult_result22 + mult_result23 ;
    sum_result3 <= mult_result31 + mult_result32 + mult_result33 ;
end

reg             [DWIDTH+8+4-1:0]          sum_result;

always @(posedge pclk)
begin
    sum_result <= sum_result1 + sum_result2 + sum_result3 ;
end

reg             [7:0]           pixel_data;

always @(posedge pclk)
begin
    pixel_data <= sum_result[DWIDTH+8+4-1:18] == 'd0 ? sum_result[17:10] + sum_result[9] : 'd255;
end

//----------------------------------------------------------------------
	localparam DLY_CLK = 9;
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