/*************************************************************************
    > File Name: isp_wb.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/
`timescale 1 ns / 1 ps

/*
 * ISP - White Balance Gain
 */

module isp_wb
#(
	parameter WIDTH = 1936,
	parameter HEIGHT = 1080
)
(
	input clk,
	input rst_n,

    input [23:0] per_img_data,
	input [38:0] gain_r,//含31位小数
	input [38:0] gain_g,//含31位小数
	input [38:0] gain_b,//含31位小数

	input in_href,
	input in_vsync,
    input per_img_clken,

    output post_img_clken,
    output [23:0] post_img_data 
);
wire [7:0] post0_img_R;
wire [7:0] post0_img_G;
wire [7:0] post0_img_B;

reg [46:0] post1_img_R;
reg [46:0] post1_img_G;
reg [46:0] post1_img_B;

reg [7:0] post2_img_R;
reg [7:0] post2_img_G;
reg [7:0] post2_img_B;

assign  post0_img_R = {per_img_data[23:16]};
assign  post0_img_G = {per_img_data[15:8]};
assign  post0_img_B = {per_img_data[7:0]};

wire [7:0] testR;
wire [7:0] testG;
wire [7:0] testB;
assign testR = gain_r[38:31];
assign testG = gain_g[38:31];
assign testB = gain_b[38:31];

//----------------------------------------
//      CLORK 0 乘以增益系数  
//----------------------------------------
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		post1_img_R <= 0;
		post1_img_G <= 0;
		post1_img_B <= 0;
	end
	else begin
		post1_img_R <= post0_img_R * gain_r;
		post1_img_G <= post0_img_G * gain_g;
		post1_img_B <= post0_img_B * gain_b;
	end
end
//----------------------------------------
//      CLORK 1 阈值判断  
//----------------------------------------
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
		post2_img_R <= 0;
		post2_img_G <= 0;
		post2_img_B <= 0;
	end
	else begin
		post2_img_R <= post1_img_R[46:39] > 0 ? {8{1'b1}} : post1_img_R[38:31];
		post2_img_G <= post1_img_G[46:39] > 0 ? {8{1'b1}} : post1_img_G[38:31];
		post2_img_B <= post1_img_B[46:39] > 0 ? {8{1'b1}} : post1_img_B[38:31];
	end
end

//----------------------------------------
//      同步时钟   延迟两个时钟  
//----------------------------------------
localparam DLY_CLK = 2;
reg [DLY_CLK-1:0] clken_dly;
always @ (posedge clk or negedge rst_n) begin
	if (!rst_n) begin
        clken_dly <= 0;
	end
	else begin
        clken_dly <= {clken_dly[DLY_CLK-2:0],per_img_clken};
	end
end

localparam HDMI_HPIXEL = 11'd640;
localparam HDMI_VPIXEL = 11'd480;
localparam RAW_HPIXEL = 11'd1936;
localparam RAW_VPIXEL = 11'd1088;
localparam WIN_X = 11'd500;     //窗口x坐标
localparam WIN_Y = 11'd500;     //窗口y坐标

reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(clken_dly[DLY_CLK-1] == 1'b1)
        if(h_cnt == RAW_HPIXEL - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(clken_dly[DLY_CLK-1] == 1'b1)
        if((v_cnt == RAW_VPIXEL - 1'd1) &&  (h_cnt == RAW_HPIXEL-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == RAW_HPIXEL - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

//----------------------------------------
//      输出结果
//----------------------------------------
assign post_img_clken = clken_dly[DLY_CLK-1];
assign post_img_data = {post2_img_R,post2_img_G,post2_img_B};
endmodule
