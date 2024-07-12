/*
***********************************************************************************************************
**    Input file: None
**    Component name: image_src.v
**    Author:    zhengXiaoliang
**  Company: WHUT
**    Description: to simulate dvd stream
***********************************************************************************************************
*/

`timescale 1ns/1ns

`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2

module image_src
#(   
    parameter iw = 1936,        //默认视频宽度
    parameter ih = 1088,        //默认视频高度
    parameter dw = 16          //默认像素数据位宽
)(
    //port decleared
    input               clk         ,     //同步时钟
    input               rst_n     ,     //全局复位
    
    input       [3:0]   src_sel     ,    //数据源通道选择
    output reg          test_clken  , 
    output reg [dw-1:0] test_data
);


parameter h_total = iw;    //行总数
parameter v_total = ih;    //垂直总数

//variable decleared

reg [dw-1:0]   rd_bmp_data [0:iw*ih-1]    ;//读图片数据
reg [7:0]   rd_bmp_data1 [0:iw*ih*2-1]    ;//读图片数据
reg [31:0]   wr_bmp_data [0:iw*ih/2-1]    ;//读图片数据
reg [31:0]   wr_bmp_data1 [0:iw*ih/2-1]    ;//读图片数据
reg [10:0] h_cnt;
reg [10:0] v_cnt;
reg [23:0] vip_cnt;
reg [2:0]   img_cnt;
integer fp_r;
integer fp_r1;
integer fp;
integer fp1;
integer cnt = 0;

initial
    begin
    fp_r = $fopen("E:\\project\\AnlogicFPGA\\EG4S20\\sd_isp_hdmi\\doc\\day.bin","rb");

    fp = $fread(rd_bmp_data,fp_r);      //$fread读取的大小取决于rd_bmp_data寄存器大小  

    $fclose(fp_r); //关闭文件
 end
initial
    begin
    fp_r1 = $fopen("E:\\project\\AnlogicFPGA\\EG4S20\\sd_isp_hdmi\\doc\\day.bin","rb");

    fp1 = $fread(rd_bmp_data1,fp_r1);      //$fread读取的大小取决于rd_bmp_data寄存器大小   

    $fclose(fp_r1); //关闭文件
 end
 
//---------------------------------------------
//水平计数器
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		h_cnt <= 11'd0;
	else
		h_cnt <= (h_cnt < h_total - 1'b1) ? h_cnt + 1'b1 : 11'd0;
end

//---------------------------------------------
//竖直计数器
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		v_cnt <= 11'd0;		
	else begin
		if(h_cnt == h_total - 1'b1)
			v_cnt <= (v_cnt < v_total - 1'b1) ? v_cnt + 1'b1 : 11'd0;
		else
			v_cnt <= v_cnt;
    end
end

//---------------------------------------------
//有效输出时钟信号
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		test_clken <= 1'd0;
	else
		test_clken <= 1'd1;
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		img_cnt <= 'd0;
		vip_cnt <= 'b0;
    end
	else if(vip_cnt == h_total*v_total - 1) begin
		img_cnt <= img_cnt + 1'd1;
		vip_cnt <= 'b0;
    end
    else begin
        img_cnt <= img_cnt;
        vip_cnt <= vip_cnt + 1;
    end
end
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		test_data <= 'b0;
    end
	else begin
        test_data <= rd_bmp_data[vip_cnt];
        $display("h_cnt = %d,v_cnt = %d,img_cnt = %d, pixdata = %04h",h_cnt,v_cnt,img_cnt,test_data); //for debug use
    
    end
end

endmodule