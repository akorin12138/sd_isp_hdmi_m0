module bayer2rgb #(
    parameter WIN_X = 11'd500,      //窗口x坐标
    parameter WIN_Y = 11'd500,      //窗口y坐标
    parameter HDMI_HPIXEL = 11'd640,
    parameter HDMI_VPIXEL = 11'd480,
    parameter RAW_HPIXEL = 11'd1936,
    parameter RAW_VPIXEL = 11'd1088
)(
    input  wire clk,
    input  wire rstn,

    input  wire         in_href,
    input  wire [7:0]   in_raw,

    output wire         out_href,
    output wire [23:0]  out_rgb 
);
// parameter RAW_HPIXEL = 11'd1920;
// parameter RAW_VPIXEL = 11'd1080;
//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(matrix_frame_clken == 1'b1)
        if(h_cnt == RAW_HPIXEL - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(matrix_frame_clken == 1'b1)
        if((v_cnt == RAW_VPIXEL - 1'd1) &&  (h_cnt == RAW_HPIXEL-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == RAW_HPIXEL - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

// outports wire
wire        	matrix_frame_vsync;
wire        	matrix_frame_href;
wire        	matrix_frame_clken;
wire [15:0]matrix_p11;
wire [15:0]matrix_p12;
wire [15:0]matrix_p13;
wire [15:0]matrix_p21;
wire [15:0]matrix_p22;
wire [15:0]matrix_p23;
wire [15:0]matrix_p31;
wire [15:0]matrix_p32;
wire [15:0]matrix_p33;

vip_matrix_generate_3x3_8bit u_vip_matrix_generate_3x3_8bit(
    .clk                	( clk                       ),
    .rst_n              	( rstn                      ),
    .per_frame_vsync    	( 1'b1                      ),
    .per_frame_href     	( 1'b1                      ),
    .per_frame_clken    	( in_href                   ),
    .per_img_y          	( in_raw                    ),
    .matrix_frame_vsync 	( matrix_frame_vsync        ),
    .matrix_frame_href  	( matrix_frame_href         ),
    .matrix_frame_clken 	( matrix_frame_clken        ),
    .matrix_p11( matrix_p11          ),.matrix_p12( matrix_p12          ),.matrix_p13( matrix_p13          ),
    .matrix_p21( matrix_p21          ),.matrix_p22( matrix_p22          ),.matrix_p23( matrix_p23          ),
    .matrix_p31( matrix_p31          ),.matrix_p32( matrix_p32          ),.matrix_p33( matrix_p33          )
);
//bayer2rgb算法
reg  [7:0]   RGB_R;
reg  [7:0]   RGB_G;
reg  [7:0]   RGB_B;
always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)begin
        RGB_R <= 8'd0;
        RGB_G <= 8'd0;
        RGB_B <= 8'd0;
    end
    else if(matrix_frame_clken == 1'b1)
        case ((2'b00^{v_cnt[0],h_cnt[0]}))
            2'b00:begin
                RGB_R <= (matrix_p12 + matrix_p32)>>1;
                RGB_G <= matrix_p22;
                RGB_B <= (matrix_p21 + matrix_p23)>>1;
            end
            2'b01:begin
                RGB_R <= (matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
                RGB_G <= (matrix_p21 + matrix_p23 + matrix_p12 + matrix_p32)>>2;
                RGB_B <= matrix_p22;
            end
            2'b10:begin
                RGB_R <= matrix_p22;
                RGB_G <= (matrix_p21 + matrix_p23 + matrix_p12 + matrix_p32)>>2;
                RGB_B <= (matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
            end
            2'b11:begin
                RGB_R <= (matrix_p21 + matrix_p23)>>1;
                RGB_G <= matrix_p22;
                RGB_B <= (matrix_p12 + matrix_p32)>>1;
            end
            default: begin
                RGB_R <= 8'd0;
                RGB_G <= 8'd0;
                RGB_B <= 8'd0;
            end
        endcase
end
wire windows_en = (h_cnt <= HDMI_HPIXEL-1 + WIN_X) && (v_cnt <= HDMI_VPIXEL-1 + WIN_Y) && 
    (h_cnt >= WIN_X) && (v_cnt >= WIN_Y) && 
    (matrix_frame_clken == 1'b1) ? 1'b1 : 1'b0;
reg matrix_frame_clken_r;
always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)begin
        matrix_frame_clken_r <= 1'b0;
    end
    else
        matrix_frame_clken_r <= matrix_frame_clken;
end
//取640x480窗
assign out_href = matrix_frame_clken_r;
// assign out_href = windows_en ;
assign out_rgb = {RGB_B,RGB_G,RGB_R};
// assign out_rgb = in_raw;

endmodule //bayer2rgb

// module bayer2rgb
// #(
// 	parameter BITS = 8,
// 	parameter WIDTH = 1936,
// 	parameter HEIGHT = 960,
// 	parameter BAYER = 2 //0:RGGB 1:GRBG 2:GBRG 3:BGGR
// )
// (
// 	input clk,
// 	input rstn,

// 	input in_href,
// 	input [BITS-1:0] in_raw,

// 	output out_href,
// 	output [23:0] out_rgb
// );

//     wire [BITS-1:0] out_r;
//     wire [BITS-1:0] out_g;
//     wire [BITS-1:0] out_b;
// 	assign out_rgb = {out_r,out_g,out_b};

// 	wire [BITS-1:0] shiftout;
// 	wire [BITS-1:0] tap1x, tap0x;
// 	shift_register #(BITS, WIDTH, 2) linebuffer(clk, in_href, in_raw, shiftout, {tap1x, tap0x});
	
// 	reg [BITS-1:0] in_raw_r;
// 	reg [BITS-1:0] p11,p12,p13;
// 	reg [BITS-1:0] p21,p22,p23;
// 	reg [BITS-1:0] p31,p32,p33;
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn) begin
// 			in_raw_r <= 0;
// 			p13 <= 0; p12 <= 0; p11 <= 0;
// 			p23 <= 0; p22 <= 0; p21 <= 0;
// 			p33 <= 0; p32 <= 0; p31 <= 0;
// 		end
// 		else begin
// 			in_raw_r <= in_raw;
// 			p11 <= p12; p12 <= p13; p13 <= tap1x;
// 			p21 <= p22; p22 <= p23; p23 <= tap0x;
// 			p31 <= p32; p32 <= p33; p33 <= in_raw_r;
// 		end
// 	end

// 	reg odd_pix;
// 	reg in_href_r1;
// 	reg in_href_r2;
// 	always @ (posedge clk or negedge rstn)
// 		if (!rstn)begin
// 			in_href_r1 <= 0;
// 			in_href_r2 <= 0;
// 		end
// 		else begin
// 			in_href_r1 <= in_href;
// 			in_href_r2 <= in_href_r1;
// 		end
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn)
// 			odd_pix <= 0;
// 		else if (in_href_r2)
// 			odd_pix <= ~odd_pix;
// 		else
// 			odd_pix <= odd_pix;
// 	end
// 	wire odd_pix_sync_shift = odd_pix;
	
// 	reg [11:0] herfcnt;
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn) 
// 			herfcnt <= 12'd0;
// 		else if(herfcnt != 12'd1935 && in_href_r2 == 1'b1)
// 			herfcnt <= herfcnt + 1'b1;
//         else if(herfcnt == 12'd1935 && in_href_r2 == 1'b1)
// 			herfcnt <= 12'd0;
//         else herfcnt <= herfcnt;
// 	end	
	
// 	reg odd_line;
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn) 
// 			odd_line <= 0;
// 		else if (herfcnt == 12'd1935 && in_href_r2 == 1'b1)
// 			odd_line <= ~odd_line;
// 		else
// 			odd_line <= odd_line;
// 	end
// 	wire odd_line_sync_shift = odd_line;

// 	wire [1:0] p22_fmt = {odd_line_sync_shift, odd_pix_sync_shift}; //pixel format 0:[R]GGB 1:R[G]GB 2:RG[G]B 3:RGG[B]

// 	reg [BITS-1:0] r_now, g_now, b_now;
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn) begin
// 			r_now <=  0;
// 			g_now <=  0;
// 			b_now <=  0;
// 		end
// 		else begin
// 			r_now <= raw2r(p22_fmt,p11,p12,p13,p21,p22,p23,p31,p32,p33);
// 			g_now <= raw2g(p22_fmt,p11,p12,p13,p21,p22,p23,p31,p32,p33);
// 			b_now <= raw2b(p22_fmt,p11,p12,p13,p21,p22,p23,p31,p32,p33);
// 		end
// 	end

// 	localparam DLY_CLK = 4;
// 	reg [DLY_CLK-1:0] href_dly;
// 	always @ (posedge clk or negedge rstn) begin
// 		if (!rstn) begin
// 			href_dly <= 0;
// 		end
// 		else begin
// 			href_dly <= {href_dly[DLY_CLK-2:0], in_href};
// 		end
// 	end
	
// 	assign out_href = href_dly[DLY_CLK-1];
// 	assign out_r = out_href ? r_now : {BITS{1'b0}};
// 	assign out_g = out_href ? g_now : {BITS{1'b0}};
// 	assign out_b = out_href ? b_now : {BITS{1'b0}};

// 	function [BITS-1:0] raw2r;
// 		input [1:0] format;//0:R 1:Gr 2:Gb 3:B
// 		input [BITS-1:0] p11,p12,p13;
// 		input [BITS-1:0] p21,p22,p23;
// 		input [BITS-1:0] p31,p32,p33;
// 		reg [BITS+1:0] r;
// 		begin
// 			case (format)
// 				2'b00: r = (p12 + p32) >> 1;
// 				2'b01: r = (p11 + p13 + p31 + p33) >> 2;
// 				2'b10: r = p22;
// 				2'b11: r = (p21 + p23) >> 1;
// 				default: r = {BITS{1'b0}};
// 			endcase
// 			raw2r = r > {BITS{1'b1}} ? {BITS{1'b1}} : r[BITS-1:0];
// 		end
// 	endfunction

// 	function [BITS-1:0] raw2g;
// 		input [1:0] format;//0:R 1:Gr 2:Gb 3:B
// 		input [BITS-1:0] p11,p12,p13;
// 		input [BITS-1:0] p21,p22,p23;
// 		input [BITS-1:0] p31,p32,p33;
// 		reg [BITS+1:0] g;
// 		begin
// 			case (format)
// 				2'b00: g = p22;
// 				2'b01: g = (p12 + p32 + p21 + p23) >> 2;
// 				2'b10: g = (p12 + p32 + p21 + p23) >> 2;
// 				2'b11: g = p22;
// 				default: g = {BITS{1'b0}};
// 			endcase
// 			raw2g = g > {BITS{1'b1}} ? {BITS{1'b1}} : g[BITS-1:0];
// 		end
// 	endfunction

// 	function [BITS-1:0] raw2b;
// 		input [1:0] format;//0:R 1:Gr 2:Gb 3:B
// 		input [BITS-1:0] p11,p12,p13;
// 		input [BITS-1:0] p21,p22,p23;
// 		input [BITS-1:0] p31,p32,p33;
// 		reg [BITS+1:0] b;
// 		begin
// 			case (format)
// 				2'b00: b = (p21 + p23) >> 1;
// 				2'b01: b = p22;
// 				2'b10: b = (p11 + p13 + p31 + p33) >> 2;
// 				2'b11: b = (p12 + p32) >> 1;
// 				default: b = {BITS{1'b0}};
// 			endcase
// 			raw2b = b > {BITS{1'b1}} ? {BITS{1'b1}} : b[BITS-1:0];
// 		end
// 	endfunction
// endmodule