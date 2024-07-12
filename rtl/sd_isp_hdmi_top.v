`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	ttt 
//////////////////////////////////////////////////////////////////////////////////
module sd_isp_hdmi_top(

		input           sys_clk,
        input           sys_rst_n,
        
		output			LED,
		 
        //SDCARD
        inout   wire    [3:0]   sd_dat      ,  
        output  wire            sd_clk      ,  
        inout   wire            sd_cmd      ,  
        //SDRAM
        output  wire            sdram_clk   ,  //SDRAM 芯片时钟
        output  wire            sdram_cke   ,  //SDRAM 时钟有效
        output  wire            sdram_cs_n  ,  //SDRAM 片选
        output  wire            sdram_ras_n ,  //SDRAM 行有效
        output  wire            sdram_cas_n ,  //SDRAM 列有效
        output  wire            sdram_we_n  ,  //SDRAM 写有效
        output  wire    [1:0]   sdram_ba    ,  //SDRAM Bank地址
        output  wire    [1:0]   sdram_dqm   ,  //SDRAM 数据掩码
        output  wire    [11:0]  sdram_addr  ,  //SDRAM 行/列地址
        inout   wire    [15:0]  sdram_data    ,  //SDRAM 数据

        // input  wire [31:0]  isp_data_num0to7,
        // input  wire [31:0]  isp_data_num8to15,
        
		//HDMI
		output			HDMI_CLK_P,
		output			HDMI_D2_P,
		output			HDMI_D1_P,
		output			HDMI_D0_P	

    );

// parameter  H_VALID  =   24'd1024 ;   //行有效数据
// parameter  V_VALID  =   24'd768 ;   //列有效数据
parameter  H_VALID  =   24'd1936 ;   //行有效数据
parameter  V_VALID  =   24'd1088 ;   //列有效数据
    
//rst_n
wire rst_n;
//clk
wire clk25m;
wire hdmi_clk_5;    //synthesis keep
wire hdmi_clk,locked;
wire sdram_clk_100m;//synthesis keep
wire sdram_clk_100m_shift;
wire locked1;
wire locked2;
wire sdcard_clk;//synthesis keep 

//sdcard
wire            sd_rd_data_en   ;  //synthesis keep
wire    [15:0]  sd_rd_data      ;  //synthesis keep
//sdram_ctrl
wire            sdram_wr_en           ;   //synthesis keep 
wire    [15:0]  sdram_wr_data         ;   //synthesis keep 
wire            sdram_rd_en           ;   //synthesis keep 
wire    [15:0]  sdram_rd_data         ;   //synthesis keep
wire            sdram_init_end/*synthesis keep=1 */  ;  //SDRAM初始化完成
reg             sdram_shift_wr_en        ;//0:sdram1;1:sdram2
reg             sdram_shift_rd_en        ;//0:sdram1;1:sdram2
reg            sdram1_wr_en           ;   //synthesis keep 
reg            sdram2_wr_en           ;   //synthesis keep 
reg             sdram1_rd_en           ;   //synthesis keep 
reg             sdram2_rd_en           ;   //synthesis keep 
reg     [15:0]  sdram1_wr_data         ;   //synthesis keep 
reg     [15:0]  sdram2_wr_data         ;   //synthesis keep 
wire    [15:0]  sdram1_rd_data         ;   //synthesis keep
wire    [15:0]  sdram2_rd_data         ;   //synthesis keep 
 //VGA
wire			VGA_HS;     //synthesis keep 
wire			VGA_VS;     //synthesis keep 
wire			VGA_DE;     //synthesis keep 
wire [4:0]	VGA_R;		
wire [5:0]	VGA_G;		
wire [4:0]	VGA_B;	
reg [15:0] VGA_RGB;	
	
wire [23:0]   post_isp_data;  
wire          post_isp_data_en;  
wire [23:0]   post_win_data;  
wire          post_win_data_en;  

wire isp_100m;
wire mux_100m;

wire rgb_clk;//synthesis keep = 1
wire yuv_clk;//synthesis keep = 1
wire raw_clk;//synthesis keep = 1
wire mux_clk;//synthesis keep = 1

assign rst_n = sys_rst_n & locked & locked1 & locked2;
/*****************************************/
/*时钟例化*/
/*****************************************/
tx_pll u_tx_pll(
		.refclk     (sys_clk),
		.reset      (!sys_rst_n),
		.extlock    (locked),
		.clk1_out   (hdmi_clk),
		.clk2_out   (hdmi_clk_5)
	);
sd_pll u_sd_pll(
		.refclk     (sys_clk),
		.reset      (!sys_rst_n),
		.extlock    (locked1),
		.clk0_out   (sdcard_clk),  //100m
		.clk1_out   (raw_clk ),//100m
		.clk2_out   (mux_clk ),//100m
		.clk3_out   (rgb_clk ),//100m
		.clk4_out   (yuv_clk )//100m
);
pll_gen u_pll_gen(
    .refclk     ( sys_clk               ),
    .reset      ( !sys_rst_n            ),
    .extlock    ( locked2               ),
    .clk0_out   ( sdram_clk_100m        ),
    .clk1_out   ( sdram_clk_100m_shift  )
);
// BUFG u_BUFG0(
//     .i ( isp_100m ),
//     .o ( isp_clk  )
// );
// BUFG u_BUFG1(
//     .i ( mux_100m ),
//     .o ( mux_clk  )
// );

/*****************************************/
/*SD卡模块例化*/
/*****************************************/
sd_top
#(
    .H_VALID(H_VALID),
    .V_VALID(V_VALID)
) u_sd_top
(
    .clk                (sdcard_clk     ),
    .rst_n              (rst_n & sdram_init_end        ),
    .sd_block_addr      ( 34944  ),      //addr与rd_en同一周期
    .sd_clk             (sd_clk         ),
    .sd_cmd             (sd_cmd         ),
    .sd_dat             (sd_dat         ),
    .sd_ren             (1'b1       ),      //读取一整个视频
    .sd_img_data        (sd_rd_data     ),
    .sd_img_data_en     (sd_rd_data_en  )       //取窗后的数据
    
);

sdram_top u_sdram_top
(
    .sys_clk                (sdram_clk_100m),             // sdram 控制器参考时钟
    .clk_out                (sdram_clk_100m_shift),       // 用于输出的相位偏移时钟
    .sys_rst_n              (rst_n),      // 系统复位，低电平有效

    //用户写端口
    .wr_fifo_wr_clk         (raw_clk),          // 写端口FIFO: 写时钟
    .wr_fifo_wr_req         (sdram_wr_en ),          // 写端口FIFO: 写使能
    .wr_fifo_wr_data        (sdram_wr_data),        // 写端口FIFO: 写数据
    .sdram_wr_b_addr        (23'd0),                // 写SDRAM的起始地址
    .sdram_wr_e_addr        (1920*1080-1),          // 写SDRAM的结束地址
    .wr_burst_len           (10'd512),              // 写SDRAM时的数据突发长度
    .wr_rst                 (~rst_n),         // 写端口复位: 复位写地址,清空写FIFO
    //所有图片写入sdram完成，拉高sdram写端口复位，锁定端口

    //用户读端口
    .rd_fifo_rd_clk         (hdmi_clk),             // 读端口FIFO: 读时钟
    .rd_fifo_rd_req         (VGA_DE),           // 读端口FIFO: 读使能
    .sdram_rd_b_addr        (24'd0),      // 读SDRAM的起始地址
    .sdram_rd_e_addr        (1920*1080-1),      // 读SDRAM的结束地址
    .rd_burst_len           (10'd512),              // 从SDRAM中读数据时的突发长度
    .rd_rst                 (~rst_n),         // 读端口复位: 复位读地址,清空读FIFO
    .rd_fifo_rd_data        (sdram_rd_data),        // 读端口FIFO: 读数据

     //用户控制端口
    .read_valid             (1'b1),                 // SDRAM 读使能
    .init_end               (sdram_init_end),      // SDRAM 初始化完成标志

    //SDRAM 芯片接口
    .sdram_clk              (sdram_clk),            // SDRAM 芯片时钟
    .sdram_cke              (sdram_cke),            // SDRAM 时钟有效
    .sdram_cs_n             (sdram_cs_n),           // SDRAM 片选
    .sdram_ras_n            (sdram_ras_n),          // SDRAM 行有效
    .sdram_cas_n            (sdram_cas_n),          // SDRAM 列有效
    .sdram_we_n             (sdram_we_n),           // SDRAM 写有效
    .sdram_ba               (sdram_ba),             // SDRAM Bank地址
    .sdram_addr             (sdram_addr),           // SDRAM 行/列地址
    .sdram_dq               (sdram_data),            // SDRAM 数据
    .sdram_dqm              (sdram_dqm)          
); 
hdmi_top u_hdmi_top
(
    .hdmi_clk       (hdmi_clk                   ),
    .hdmi_5clk      (hdmi_clk_5                 ),
    .sys_rst_n      (rst_n  & sdram_init_end   ),
    // 用户接口
    .lcd_data       (sdram_rd_data),
    .second_rden    (),
    .first_rden     (),
    .lcd_xpos       (lcd_xpos),     //像素点横坐标
    .lcd_ypos       (lcd_ypos),     //像素点纵坐标
    .hcnt           (hcnt),
    .vcnt           (vcnt),
    .all_ack        (VGA_DE               ),
    // HDMI接口
    .tmds_clk_p     (HDMI_CLK_P                 ),   //TMDS 时钟通道
    .tmds_clk_n     (                 ),
    .tmds_data_p    ({HDMI_D2_P,HDMI_D1_P,HDMI_D0_P}                ),  //TMDS 数据通道
    .tmds_data_n    (                )
);	

/*****************************************/
/*TEST*/
/*****************************************/
reg		[23:0]	cnt;	
always @(posedge hdmi_clk)
begin
	if(rst_n&sdram_init_end)
		cnt <= cnt+1'b1;
	else
		cnt  <= 16'd0;
end
assign LED=cnt[23];












// reg [15:0] sd_data_r0;
// reg [15:0] sd_data_r1;
// reg        sd_data_en_r0;
// reg        sd_data_en_r1;

// always @(posedge isp_clk or negedge rst_n) begin
//     if(rst_n)begin
//         sd_data_r0 <= 16'd0;
//         sd_data_r1 <= 16'd0;
//     end else begin
//         sd_data_r0 <= sd_rd_data;
//         sd_data_r1 <= sd_data_r0;
//     end
// end
// always @(posedge isp_clk or negedge rst_n) begin
//     if(rst_n)begin
//         sd_data_en_r0 <= 1'b0;
//         sd_data_en_r1 <= 1'b0;
//     end else begin
//         sd_data_en_r0 <= sd_rd_data_en;
//         sd_data_en_r1 <= sd_data_en_r0;
//     end
// end

wire [23:0]  post_isp_data0;
wire         post_isp_data_en0;
wire [23:0]  post_isp_data1;
wire         post_isp_data_en1;

ispMUX u_ispMUX(
    .rgb_clk          	( rgb_clk           ),
    .raw_clk          	( raw_clk           ),
    .yuv_clk          	( yuv_clk           ),
    .mux_clk          	( mux_clk           ),
    .rst_n            	( rst_n             ),
    .per_sd_data      	( sd_rd_data        ),
    .per_sd_data_en   	( sd_rd_data_en     ),

    .post_isp_data0    	( post_isp_data0    ),
    .post_isp_data_en0 	( post_isp_data_en0 ),
    .post_isp_data1    	( post_isp_data1    ),
    .post_isp_data_en1 	( post_isp_data_en1 ),
    // .isp_data_num0to7   ( isp_data_num0to7  ),
    // .isp_data_num8to15  ( isp_data_num8to15 )
    .isp_data_num0to7   ( 32'h00130347 ),
    .isp_data_num8to15  ( 32'h0808004a )
);



/***********************************************************************************************************/

window_split #(
    .WIN_X       	( 8     ),
    .WIN_Y       	( 4     ),
    .WIDTH       	( 1936  ),
    .HEIGHT      	( 1088  ),
    .HDMI_HPIXEL 	( 1920  ),
    .HDMI_VPIXEL 	( 1080  )
)u_window_split(
    .clk           	( mux_clk             ),
    .rstn          	( rst_n               ),
    .win_data_en0  	( post_isp_data_en0   ),
    .win_data_en1  	( post_isp_data_en1   ),
    .win_data0     	( post_isp_data0      ),
    .win_data1     	( post_isp_data1      ),
    .split_en       ( 1'b1         ),
    .sdram_data_en 	( sdram_wr_en         ),
    .split_x        ( 8                   ),
    .split_y        ( 4                   ),
    .sdram_data    	( sdram_wr_data       )
);







// window #(
//     .WIN_X  	( 11'd4  ),
//     .WIN_Y  	( 11'd8  ),
//     .WIDTH  	( 11'd1936 ),
//     .HEIGHT 	( 11'd1088 ),
//     .HDMI_HPIXEL( HDMI_HPIXEL),
//     .HDMI_VPIXEL( HDMI_VPIXEL)
// )u_window(
//     .clk           	( yuv_clk           ),
//     .rstn          	( rst_n             ),
//     .win_data_en   	( post_isp_data_en  ),
//     .win_data      	( post_isp_data     ),//24bit
//     .sdram_data_en 	( sdram_wr_en       ),
//     .sdram_data    	( sdram_wr_data     ) //16bit
// );


endmodule
