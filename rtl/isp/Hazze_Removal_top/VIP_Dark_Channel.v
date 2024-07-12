//基于暗通道先验的图像去雾

//计算彩色图像的暗通道，共消耗五个时钟周期

`timescale 1ns/1ns
module VIP_Dark_Channel #(
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
    input       [7:0]   per_img_red,
    input       [7:0]   per_img_green,
    input       [7:0]   per_img_blue,
    
    output              post_frame_vsync,
    output              post_frame_href,
    output              post_frame_clken,
    output      [7:0]   post_img_Dark       //暗通道图像
  
);
//-------------------------------------------------
//VIP 算法--计算RGB三个通道中的最小值，消耗一个时钟

wire        post0_frame_vsync;
wire        post0_frame_href;
wire        post0_frame_clken;
wire [7:0]  post0_RGB_MIN   ;   //RGB三个通道中的最小值

VIP_RGB888_MIN u_VIP_RGB888_MIN
(
    //global clock
    .clk                (clk),
    .rst_n              (rst_n),
    
    //Image data prepared to be processed
    .per_frame_vsync    (per_frame_vsync    ),
    .per_frame_href     (per_frame_href     ),
    .per_frame_clken    (per_frame_clken    ),
    .per_img_red        (per_img_red        ),
    .per_img_green      (per_img_green      ),
    .per_img_blue       (per_img_blue       ),
    
    //Image data has been processed
    .post_frame_vsync   (post0_frame_vsync  ),
    .post_frame_href    (post0_frame_href   ),
    .post_frame_clken   (post0_frame_clken  ),
    .post_RGB_MIN       (post0_RGB_MIN      )
);

//-------------------------------------------------
//VIP 算法--最小值滤波，消耗四个时钟周期

wire        post1_frame_vsync   ;
wire        post1_frame_href    ;
wire        post1_frame_clken   ;
wire [7:0]  post1_img_Y         ;
VIP_Gray_Minimum_Filter #(
    .IMG_HDISP  (IMG_HDISP),
    .IMG_VDISP  (IMG_VDISP)
) u_VIP_Gray_Minimum_Filter (
    //global clk
    .clk                    (clk),
    .rst_n                  (rst_n),
    
    //Image data prepared to be processed
    .per_frame_vsync        (post0_frame_vsync      ),
    .per_frame_href         (post0_frame_href       ),
    .per_frame_clken        (post0_frame_clken      ),
    .per_img_Y              (post0_RGB_MIN          ),
    
    //Image data has been processed
    .post_frame_vsync       (post1_frame_vsync   ),
    .post_frame_href        (post1_frame_href    ),
    .post_frame_clken       (post1_frame_clken   ),
    .post_img_Y             (post1_img_Y         )
);

assign  post_frame_vsync    =   post1_frame_vsync   ;      
assign  post_frame_href     =   post1_frame_href    ;   
assign  post_frame_clken    =   post1_frame_clken   ;
assign  post_img_Dark       =   post1_img_Y         ;

endmodule