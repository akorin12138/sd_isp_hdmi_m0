//基于暗通道先验的图像去雾

module Hazze_Removal_top#(
    parameter   IMG_HDISP = 11'd1024 ,
    parameter   IMG_VDISP = 11'd768
)
(   
    //global clk
    input           clk,
    input           rst_n,
    
    //Image data prepared to be processed
    input               per_frame_vsync ,
    input               per_frame_href  ,
    input               per_frame_clken ,
    input       [23:0]  per_img_data ,

    //Image data has been processed
    output              post_frame_vsync,
    output              post_frame_href ,
    output              post_frame_clken,
    output      [23:0]  post_img_data    

);
wire [7:0]   per_img_red  ;
wire [7:0]   per_img_green;
wire [7:0]   per_img_blue ;
wire [7:0]   post_img_red  ;
wire [7:0]   post_img_green;
wire [7:0]   post_img_blue ;
assign per_img_red   = per_img_data[23:16];
assign per_img_green = per_img_data[15:8];
assign per_img_blue  = per_img_data[7:0];
assign post_img_data = {post_img_red,post_img_green,post_img_blue};

wire            post0_frame_vsync  ;
wire            post0_frame_href   ;
wire            post0_frame_clken  ;
wire    [7:0]   post0_img_Dark     ; //暗通道图像

wire    [7:0]   atmospheric_light;
wire    [7:0]   atmospheric_pos_x;  //大气光强度对应位置横坐标
wire    [7:0]   atmospheric_pos_y;  //大气光强度对应位置纵坐标

reg     [23:0]  img_rgb_reg1;
reg     [23:0]  img_rgb_reg2;
reg     [23:0]  img_rgb_reg3;
reg     [23:0]  img_rgb_reg4;
reg     [23:0]  img_rgb_reg5;
reg     [23:0]  img_rgb_reg6;
reg     [23:0]  img_rgb_reg7;
reg     [23:0]  img_rgb_reg8;

wire            post1_frame_vsync   ;
wire            post1_frame_href    ;
wire            post1_frame_clken   ;
wire    [7:0]   post1_transmission  ;//透射率

wire            post2_frame_vsync   ;
wire            post2_frame_href    ;
wire            post2_frame_clken   ;
wire    [7:0]   post2_img_red       ;//暗通道图案
wire    [7:0]   post2_img_green     ;//暗通道图案
wire    [7:0]   post2_img_blue      ;//暗通道图案

//---------------------------------------
//将彩色图像延迟五/八个时钟，与暗通道图像同步

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        img_rgb_reg1 <= 24'b0;
        img_rgb_reg2 <= 24'b0;
        img_rgb_reg3 <= 24'b0;
        img_rgb_reg4 <= 24'b0;
        img_rgb_reg5 <= 24'b0;
        img_rgb_reg6 <= 24'b0;
        img_rgb_reg7 <= 24'b0;
        img_rgb_reg8 <= 24'b0;
    end
    else begin              
        img_rgb_reg1 <= {per_img_red,per_img_green,per_img_blue};
        img_rgb_reg2 <= img_rgb_reg1;
        img_rgb_reg3 <= img_rgb_reg2;
        img_rgb_reg4 <= img_rgb_reg3;
        img_rgb_reg5 <= img_rgb_reg4;
        img_rgb_reg6 <= img_rgb_reg5;
        img_rgb_reg7 <= img_rgb_reg6;
        img_rgb_reg8 <= img_rgb_reg7;
    end
end        

//---------------Step 1------------------------
//计算彩色图像的暗通道，共消耗五个时钟周期
VIP_Dark_Channel #(
    .IMG_HDISP(IMG_HDISP),
    .IMG_VDISP(IMG_VDISP)
)
u_VIP_Dark_Channel(
    //global clock
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    
    .per_frame_vsync    (per_frame_vsync    ),
    .per_frame_href     (per_frame_href     ),
    .per_frame_clken    (per_frame_clken    ),
    .per_img_red        (per_img_red        ),
    .per_img_green      (per_img_green      ),
    .per_img_blue       (per_img_blue       ),
                         
    .post_frame_vsync   (post0_frame_vsync  ),
    .post_frame_href    (post0_frame_href   ),
    .post_frame_clken   (post0_frame_clken  ),
    .post_img_Dark      (post0_img_Dark     ) //暗通道图像
  
);

//----------------Step 2-------------------
//计算大气光强度

VIP_Atmospheric_Light #(
    .IMG_HDISP(IMG_HDISP),
    .IMG_VDISP(IMG_VDISP)
)u_VIP_Atmospheric_Light
(
    //global clock          
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
                             
    .per_frame_vsync        (post0_frame_vsync      ),
    .per_frame_href         (post0_frame_href       ),
    .per_frame_clken        (post0_frame_clken      ),
    .per_img_Dark           (post0_img_Dark         ), //暗通道图像
                             
    .per_img_red            (img_rgb_reg5[23:16]    ),  //延迟五个时钟的彩色图像
    .per_img_green          (img_rgb_reg5[15: 8]    ),
    .per_img_blue           (img_rgb_reg5[ 7: 0]    ),
                             
    .atmospheric_light      (atmospheric_light      ),  //大气光强度
    .atmospheric_pos_x      (atmospheric_pos_x      ),  //大气光强度对应的位置横坐标
    .atmospheric_pos_y      (atmospheric_pos_y      )   //大气光强度对应位置纵坐标
    
);

//----------------Step 3---------------------------

//计算透射率图，消耗三个时钟

VIP_Transmission_Map u_VIP_Transmission_Map
(
    //global clk
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    
    //Image data prepared to be processed
    .per_frame_vsync    (post0_frame_vsync  ),
    .per_frame_href     (post0_frame_href   ),
    .per_frame_clken    (post0_frame_clken  ),
                                  
    .per_img_Dark       (post0_img_Dark     ),   //暗通道
    .atmospheric_light  (atmospheric_light  ),  //大气光强度
    
    //Image data has been processed
    .post_frame_vsync   (post1_frame_vsync  ),
    .post_frame_href    (post1_frame_href   ),
    .post_frame_clken   (post1_frame_clken  ),
    .post_transmission  (post1_transmission ) //透射率

);

//----------------Step 4---------------------------

//恢复场景辐射，消耗三个时钟周期

VIP_scene_radiance #(
    .IMG_HDISP(IMG_HDISP),
    .IMG_VDISP(IMG_VDISP)
)
u_VIP_scene_radiance(
    //global clock
    .clk                (clk                ),
    .rst_n              (rst_n              ),
    
    //Image data prepared to be processed
    .per_frame_vsync    (post1_frame_vsync  ),
    .per_frame_href     (post1_frame_href   ),
    .per_frame_clken    (post1_frame_clken  ),
                          
    .per_transmission   (post1_transmission ),   //透射率图像
    .per_img_red        (img_rgb_reg8[23:16]),
    .per_img_green      (img_rgb_reg8[15: 8]),
    .per_img_blue       (img_rgb_reg8[ 7: 0]),
    .atmospheric_light  (atmospheric_light  ),  //大气光强度
    
    
    //Image data has been processed
    .post_frame_vsync   (post2_frame_vsync  ),
    .post_frame_href    (post2_frame_href   ),
    .post_frame_clken   (post2_frame_clken  ),
    .post_img_red       (post2_img_red      ),
    .post_img_green     (post2_img_green    ),
    .post_img_blue      (post2_img_blue     ) 
);

//------------------------------------
//输出最终结果
assign post_frame_vsync = post2_frame_vsync     ;
assign post_frame_href  = post2_frame_href      ;
assign post_frame_clken = post2_frame_clken     ;
assign post_img_red     = post2_img_red         ;
assign post_img_green   = post2_img_green       ;
assign post_img_blue    = post2_img_blue        ;


endmodule