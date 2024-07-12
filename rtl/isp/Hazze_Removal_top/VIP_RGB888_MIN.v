//基于暗通道先验的图像去雾

//VIP 算法--计算RGB三个通道中的最小值，消耗一个时钟

module VIP_RGB888_MIN
(
    //global clock
    input           clk,
    input           rst_n,
    
    //Image data prepared to be processed
    input               per_frame_vsync,
    input               per_frame_href,
    input               per_frame_clken,
    input       [7:0]   per_img_red,
    input       [7:0]   per_img_green,
    input       [7:0]   per_img_blue,
    
    //Image data has been processed
    output reg          post_frame_vsync,
    output reg          post_frame_href,
    output reg          post_frame_clken,
    output reg  [7:0]   post_RGB_MIN
);

always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        post_RGB_MIN <= 8'h0;
    else    if((per_img_red <= per_img_green) && (per_img_red <= per_img_blue))
        post_RGB_MIN <= per_img_red;
    else    if((per_img_green <= per_img_red) && (per_img_green <= per_img_blue))
        post_RGB_MIN <= per_img_green;
    else
        post_RGB_MIN <= per_img_blue;
        
//延迟一个拍
always@(posedge clk) begin
    post_frame_vsync <= per_frame_vsync;
    post_frame_href <= per_frame_href;
    post_frame_clken <= per_frame_clken;
end
   
endmodule