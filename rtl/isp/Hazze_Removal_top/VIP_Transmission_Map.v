//基于暗通道先验的图像去雾

//计算透射率图，消耗三个时钟

`timescale 1ns/1ns
module VIP_Transmission_Map
(
    //global clk
    input               clk,
    input               rst_n,
    
    //Image data prepared to be processed
    input               per_frame_vsync ,
    input               per_frame_href  ,
    input               per_frame_clken ,
    
    input       [7:0]   per_img_Dark    ,   //暗通道
    input       [7:0]   atmospheric_light,  //大气光强度
    
    //Image data has been processed
    output              post_frame_vsync,
    output              post_frame_href ,
    output              post_frame_clken,
    output      [7:0]   post_transmission   //透射率

);

//w = 0.9
parameter W_MULT_255 = 230; // 0.9 * 255

//t0 = 0.1
parameter T_MIN     = 25; //透射率最小值

//透射率计算公式 t = 1 - w * (Dark/atmospheric_light)
//----------->   post_transmission = t*255 = 255 - W_MULT_255 * Dark/atmospheric_light

//----------------------------------------------------------
//第一个时钟,计算乘法

reg [15:0]  w255_mult_dark;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w255_mult_dark <= 16'd0;
    end
    else begin
        w255_mult_dark <= W_MULT_255 * per_img_Dark; 
    end
end

//第二个时钟，计算除法

reg [15:0]  w255xdark_div_atmos;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        w255xdark_div_atmos <= 16'd0;
    end
    else begin
        w255xdark_div_atmos <= w255_mult_dark / atmospheric_light;
    end
end

//第三个时钟，计算减法
reg [15:0]  transmission;

always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        transmission <= 16'd0;
    end
    else begin
        if(w255xdark_div_atmos >= 255 - T_MIN)
            transmission <= T_MIN;
        else    
            transmission <= 255 - w255xdark_div_atmos;
    end
end

assign post_transmission = transmission[7:0];

//-----------------------------------
//lag 3 clocks signal sync
reg [2:0]   per_frame_vsync_r;
reg [2:0]   per_frame_href_r;
reg [2:0]   per_frame_clken_r;

//将同步信号延迟三拍，用于同步化处理
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