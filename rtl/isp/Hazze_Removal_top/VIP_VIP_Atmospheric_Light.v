//基于暗通道先验的图像去雾

//计算大气光强度

`timescale 1ns/1ns
module  VIP_Atmospheric_Light #(
    parameter   [10:0]  IMG_HDISP = 11'd1024,
    parameter   [10:0]  IMG_VDISP = 11'd768
)
(
    //global clock
    input               clk,
    input               rst_n,
        
    input               per_frame_vsync,
    input               per_frame_href,
    input               per_frame_clken,
    input       [7:0]   per_img_Dark,
        
    input       [7:0]   per_img_red,
    input       [7:0]   per_img_green,
    input       [7:0]   per_img_blue,
    
    output reg  [7:0]   atmospheric_light,  //大气光强度
    output reg  [7:0]   atmospheric_pos_x,  //大气光强度对应的位置横坐标
    output reg  [7:0]   atmospheric_pos_y   //大气光强度对应位置纵坐标
    
);
//-----------------------------------------------
//lag 1 clocks signal sync
reg     per_frame_vsync_r;
reg     per_frame_href_r ;
reg     per_frame_clken_r;

always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        begin
        per_frame_vsync_r   <=  0;
        per_frame_href_r    <=  0;
        per_frame_clken_r   <=  0;
        end
    else
        begin
        per_frame_vsync_r   <=  per_frame_vsync;
        per_frame_href_r    <=  per_frame_href ;
        per_frame_clken_r   <=  per_frame_clken;
        end
 
/*         
wire    vsync_pos_flag;//场同步信号上升沿
wire    vsync_neg_flag;//场同步信号下降沿

assign vsync_pos_flag = per_frame_vsync & (~per_frame_vsync_r);
assign vsync_neg_flag = (~per_frame_vsync) & per_frame_vsync_r; */

//------------------------------------------
//对输入的像素进行"行/场"方向计数，得到其纵横坐标
wire         vsync_over_flag; //场结束信号
reg [10:0]   x_cnt;
reg [10:0]   y_cnt;

assign vsync_over_flag = ((per_frame_clken) && (x_cnt == IMG_HDISP - 1) && (y_cnt == IMG_VDISP - 1));

always@(posedge clk or negedge rst_n) 
    if(rst_n == 1'b0) 
        x_cnt <= 'd0;
    else if((per_frame_clken) && (x_cnt == IMG_HDISP - 1)) 
        x_cnt <= 'd0;
    else if(per_frame_clken)
        x_cnt <= x_cnt + 1'b1;
    else
        x_cnt <= x_cnt;
        
always@(posedge clk or negedge rst_n) 
    if(rst_n == 1'b0) 
        y_cnt <= 'd0;
    else if((per_frame_clken) && (x_cnt == IMG_HDISP - 1) && (y_cnt == IMG_VDISP - 1)) 
        y_cnt <= 'd0;
    else if((per_frame_clken) && (x_cnt == IMG_HDISP - 1)) 
        y_cnt <= y_cnt + 1'b1;
    else
        y_cnt <= y_cnt; 
        
//------------------------------------------------------
//遍历整个图片，求出暗通道最大亮度所在的位置机器对应的彩色像素数据

reg [7:0]   dark_max    ;   //寄存暗通道图像的最大值
reg [7:0]   color_R     ;   //寄存相应的彩色通道   
reg [7:0]   color_G     ;   //寄存相应的彩色通道   
reg [7:0]   color_B     ;   //寄存相应的彩色通道   
  
reg [9:0]   atmos_x ;   //大气光强度所在位置
reg [9:0]   atmos_y ;   

reg [7:0]   color_max;  //彩色通道的最大值作为大气光强

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        dark_max <=  8'b0;
        color_B  <=  8'd0;
        color_G  <=  8'd0;
        color_R  <=  8'd0;
        
        atmos_x  <= 8'd0;
        atmos_y  <= 8'd0;
    end
    else if(vsync_over_flag) begin
        dark_max <= 8'd0;
        color_R  <= 8'd0;
        color_G  <= 8'd0;
        color_B  <= 8'd0;
        
        atmos_x  <= 8'd0;
        atmos_y  <= 8'd0;
    end
    else if((per_frame_clken) && (per_img_Dark > dark_max)) begin
    //遍历整个图片，求出暗通道最大亮度所在的位置机器对应的彩色像素数据
        dark_max <= per_img_Dark ;
        color_R  <= per_img_red  ;
        color_G  <= per_img_green;
        color_B  <= per_img_blue ;
        
        atmos_x  <= x_cnt;
        atmos_y  <= y_cnt;
    end
    else begin
        dark_max <= dark_max  ;
        color_R  <= color_R   ;
        color_G  <= color_G   ;
        color_B  <= color_B   ;
        
        atmos_x  <= atmos_x   ;
        atmos_y  <= atmos_y   ;
    end
end    
//-----------------------------------------------
//一帧图像结束后，计算彩色像素通道中的最大值

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        atmospheric_light <= 8'd0;
        atmospheric_pos_x <= 11'd0;
        atmospheric_pos_y <= 11'd0;
    end 
    else begin
        //在一帧结束后，输出最终结果
        if(vsync_over_flag) begin
            atmospheric_pos_x <= atmos_x;
            atmospheric_pos_y <= atmos_y;     
            
            //取彩色通道中的最大数据作为大气光强
            if((color_R > color_G) && (color_R > color_B))
                atmospheric_light <= color_R;
            else if((color_G > color_R) && (color_G > color_B))
                atmospheric_light <= color_G;
            else
                atmospheric_light <= color_B;
                
        end
    end
end



endmodule