/*************************************************************************
    > File Name: isp_blc.v
    > Author: bxq
    > Mail: 544177215@qq.com
    > Created Time: Thu 21 Jan 2021 21:50:04 GMT
 ************************************************************************/
`timescale 1 ns / 1 ps

/*
 * ISP - Black Level Correction
 */

module isp_blc
#(
	parameter BITS = 8,
	parameter WIDTH = 1936,
	parameter HEIGHT = 1088
)(
	input wire  clk,
	input wire  rst_n,

    input wire [7:0]    black_gb,
    input wire [7:0]    black_b ,
    input wire [7:0]    black_r ,
    input wire [7:0]    black_gr,

	input   [BITS-1:0]  per_raw_data,
    input               per_raw_data_en,

	output  [BITS-1:0]  post_raw_data,
	output              post_raw_data_en
);

reg [7:0]  raw_nowtime;
// parameter RAW_HPIXEL = 11'd1920;
// parameter RAW_VPIXEL = 11'd1080;
//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(per_raw_data_en == 1'b1)
        if(h_cnt == WIDTH - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(per_raw_data_en == 1'b1)
        if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == WIDTH - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

    wire [1:0] format;
    assign format = {v_cnt[0],h_cnt[0]};

reg [BITS-1:0] blc_sub;
always @ (posedge clk or negedge rst_n) 
begin
    if (rst_n == 1'b0) 
        blc_sub <= 8'd0;
    else case (format)
        2'b00: blc_sub <= per_raw_data > black_gb ? per_raw_data - black_gb : {BITS{1'b0}};
        2'b01: blc_sub <= per_raw_data > black_b ? per_raw_data - black_b : {BITS{1'b0}};
        2'b10: blc_sub <= per_raw_data > black_r ? per_raw_data - black_r : {BITS{1'b0}};
        2'b11: blc_sub <= per_raw_data > black_gr ? per_raw_data - black_gr : {BITS{1'b0}};
        default: blc_sub = {BITS{1'b0}};
    endcase
end
always @ (posedge clk or negedge rst_n) 
begin
    if (rst_n == 1'b0) 
        raw_nowtime <= 8'd0;
    else
        raw_nowtime <= blc_sub;
end

reg post_raw_data_en_r0;
reg post_raw_data_en_r1;
always @ (posedge clk or negedge rst_n) 
begin
    if (rst_n == 1'b0) begin
        post_raw_data_en_r0 <= 1'b0;
        post_raw_data_en_r1 <= 1'b0;
    end
    else begin
        post_raw_data_en_r0 <= per_raw_data_en;
        post_raw_data_en_r1 <= post_raw_data_en_r0;
    end
end

assign post_raw_data_en = post_raw_data_en_r1;
assign post_raw_data = raw_nowtime;
endmodule