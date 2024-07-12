module hdmi_top(
    input   wire            hdmi_clk    ,
    input   wire            hdmi_5clk   ,
    input   wire            sys_rst_n   ,
    //用户接口
    input   wire    [15:0]  lcd_data    ,
    output  wire            second_rden ,
    output  wire            first_rden  ,
    output  wire    [10:0]  lcd_xpos    ,  //像素点横坐标
    output  wire    [10:0]  lcd_ypos    ,  //像素点纵坐标
    output  wire     [11:0]  hcnt,
    output  wire     [11:0]  vcnt,

    output  wire            all_ack     ,
    //HDMI接口
    output  wire            tmds_clk_p   ,  // TMDS 时钟通道
    output  wire            tmds_clk_n   ,
    output  wire    [2:0]   tmds_data_p  ,  // TMDS 数据通道
    output  wire    [2:0]   tmds_data_n
);

//*****************************************************
//**                    main code
//***************************************************** 

wire    [23:0]  vga_rgb;
wire            vga_de;
wire            vga_vs;
wire            vga_hs;

wire            lcd_dclk;

//例化视频显示驱动模块
Driver u1_Driver
(
// Input
    .clk            (hdmi_clk       ),
    .rst_n          (sys_rst_n      ),
    .lcd_data       (lcd_data       ),
// Output
    .lcd_dclk       (lcd_dclk       ),
    .lcd_hs         (vga_hs         ),
    .lcd_vs         (vga_vs         ),
    .lcd_rgb        (vga_rgb        ),
    .lcd_en         (vga_de         ),
    .lcd_xpos       (lcd_xpos       ),
    .lcd_ypos       (lcd_ypos       ),
    .hcnt           (hcnt           ),
    .vcnt           (vcnt           ),
    .lcd_request    (all_ack        ),
    .first_ack      (first_rden     ),
    .second_ack     (second_rden    )
);

//例化HDMI驱动模块
dvi_transmitter_top u_rgb2dvi_0(
    .pclk           (hdmi_clk       ),
    .pclk_x5        (hdmi_5clk      ),
    .reset_n        (sys_rst_n      ),
                
    .video_din      (vga_rgb        ),
    .video_hsync    (vga_hs         ), 
    .video_vsync    (vga_vs         ),
    .video_de       (vga_de         ),
                
    .tmds_clk_p     (tmds_clk_p     ),
    .tmds_clk_n     (tmds_clk_n     ),
    .tmds_data_p    (tmds_data_p    ),
    .tmds_data_n    (tmds_data_n    )
    );
	 
endmodule