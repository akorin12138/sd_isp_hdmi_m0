//基于暗通道先验的图像去雾

//恢复场景辐射，消耗三个时钟周期

`timescale 1ns/1ns
module VIP_scene_radiance #(
    parameter   [10:0]  IMG_HDISP = 11'd1024,
    parameter   [10:0]  IMG_VDISP = 11'd768
)
(
    //global clock
    input               clk,
    input               rst_n,
    
    //Image data prepared to be processed
    input               per_frame_vsync ,
    input               per_frame_href  ,
    input               per_frame_clken ,
    
    input       [7:0]   per_transmission,   //透射率图像
    input       [7:0]   per_img_red ,
    input       [7:0]   per_img_green,
    input       [7:0]   per_img_blue,
    input       [7:0]   atmospheric_light,  //大气光强度
    
    
    //Image data has been processed
    output              post_frame_vsync,
    output              post_frame_href ,
    output              post_frame_clken,
    output      [7:0]   post_img_red    ,
    output      [7:0]   post_img_green  ,
    output      [7:0]   post_img_blue    
);

//场景辐射计算公式  scene = (fog_img - atmos_light)/t + atmos_light
//--------------->  scene = (255 * fog_img - (255-transmission)*atmos_light)/transmission)
//(其中t为透射率，范围0至1； 而transmission = t*255)

wire [7:0]  minus_trans;

assign minus_trans = 255 - per_transmission;

//--------------------------------------------------
//第一个时钟 计算乘法

reg [15:0]  fog_mult_255_r ; //255 * fog_img
reg [15:0]  fog_mult_255_g ; //255 * fog_img
reg [15:0]  fog_mult_255_b ; //255 * fog_img
reg [15:0]  trans_mult_altmos; //(255-transmission)*atmospheric_light

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        fog_mult_255_r      <=  16'd0;
        fog_mult_255_g      <=  16'd0;
        fog_mult_255_b      <=  16'd0;
        trans_mult_altmos   <=  16'd0;
    end
    else begin
        fog_mult_255_r      <=  {per_img_red  ,8'd0} - per_img_red;
        fog_mult_255_g      <=  {per_img_green,8'd0} - per_img_green;
        fog_mult_255_b      <=  {per_img_blue ,8'd0} - per_img_blue;
        trans_mult_altmos   <=  minus_trans * atmospheric_light;       
    end
end        

//----------------------------------------
//第二个时钟  计算减法

reg [15:0]  numerator_r; // 分子
reg [15:0]  numerator_g; // 分子
reg [15:0]  numerator_b; // 分子

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        numerator_r <= 16'd0;
        numerator_g <= 16'd0;
        numerator_b <= 16'd0;
    end
    else begin 
        if(fog_mult_255_r > trans_mult_altmos)
            numerator_r <= fog_mult_255_r - trans_mult_altmos;
        else
            numerator_r <= 16'd0;
        if(fog_mult_255_g > trans_mult_altmos)
            numerator_g <= fog_mult_255_g - trans_mult_altmos;
        else
            numerator_g <= 16'd0;
        if(fog_mult_255_b > trans_mult_altmos)
            numerator_b <= fog_mult_255_b - trans_mult_altmos;
        else
            numerator_b <= 16'd0;
    end
end

//延迟两个时钟，进行数据同步
reg [7:0] transmission_reg1;
reg [7:0] transmission_reg2;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        transmission_reg1 <= 'b0;
        transmission_reg2 <= 'b0;
    end
    else begin
        transmission_reg1 <= per_transmission;
        transmission_reg2 <= transmission_reg1;
    end 
end    

//------------------------------------------------
//第三个时钟，计算除法
reg [15:0] scene_radiance_r;
reg [15:0] scene_radiance_g;
reg [15:0] scene_radiance_b;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        scene_radiance_r <= 16'd0;
        scene_radiance_g <= 16'd0;
        scene_radiance_b <= 16'd0;
    end
    else begin
        scene_radiance_r <= numerator_r/transmission_reg2;
        scene_radiance_g <= numerator_g/transmission_reg2;
        scene_radiance_b <= numerator_b/transmission_reg2;
    end
end

assign post_img_red     = (scene_radiance_r > 8'd255) ? 8'd255 : scene_radiance_r[7:0];
assign post_img_green   = (scene_radiance_g > 8'd255) ? 8'd255 : scene_radiance_g[7:0];
assign post_img_blue    = (scene_radiance_b > 8'd255) ? 8'd255 : scene_radiance_b[7:0];


//-----------------------------------
//lag 3 clocks signal sync
reg [2:0]   per_frame_vsync_r;
reg [2:0]   per_frame_href_r;
reg [2:0]   per_frame_clken_r;

//将同步信号延迟两拍，用于同步化处理
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        per_frame_vsync_r <= 0;
        per_frame_href_r  <= 0;
        per_frame_clken_r <= 0;
    end
    else begin
        per_frame_vsync_r <= { per_frame_vsync_r[1:0], per_frame_vsync};
        per_frame_href_r  <= { per_frame_href_r[1:0],  per_frame_href};
        per_frame_clken_r <= { per_frame_clken_r[1:0], per_frame_clken};
    end
end

assign post_frame_vsync =   per_frame_vsync_r[2];
assign post_frame_href  =   per_frame_href_r[2];
assign post_frame_clken =   per_frame_clken_r[2];
endmodule