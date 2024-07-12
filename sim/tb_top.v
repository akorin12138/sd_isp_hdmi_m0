`timescale 1ns / 1ps
module tb_top();

parameter   CLK_PERIOD      =20                                                      ;
// parameter   W_BMP_WIDTH     =32'h014e                                               ;
parameter   W_BMP_WIDTH     =32'd1936                                               ;
// parameter   W_BMP_HIGHT     =32'h00fe                                               ;
parameter   W_BMP_HIGHT     =32'd1088                                               ;
parameter   PIXEL_BITS      =16'd24                                                 ;   //24bits
parameter   PIXEL_BYTES     =PIXEL_BITS/8                                           ;   //3bytes
parameter   IMAGE_SIZE      =W_BMP_WIDTH*PIXEL_BYTES*W_BMP_HIGHT    ;
parameter   BMP_FILE_HEAD   = 32'd54                                                ; 
parameter   BM_WINDOWS      = 16'h4d42                                              ;
parameter   FILE_SIZE       =IMAGE_SIZE+BMP_FILE_HEAD                               ;

// reg [ 7:0] vip_pixel_data [0:921600];   //640x480x3
// reg [ 7:0] vip_pixel_data [0:2359296];   //1024x768x3
// reg [ 7:0] vip_pixel_data [0:6220800];   //1920x1080x3
reg [ 7:0] vip_pixel_data [0:6319104];   //1936x1088x3
reg [7:0]   wr_bmp_data [0:7000000]    ;//写图片数据
reg [7:0]   BMP_HEAD [0:53]    ;//写图片数据
reg         clk                     ;
reg [7:0]   rd_data                 ;//用于波形显示
reg [7:0]   wr_data                 ;//用于波形显示

integer R_bmp_width   ;//读出图片的宽度
integer R_bmp_hight   ;//读出图片的高度
integer R_data_start_index   ;//读出图片的宽度
integer R_bmp_size   ;//读出BMP文件的大小

reg rst_n ;
 
//原始图像数据
wire [15:0] per_img_data;
wire        per_img_clken;
//Bayer转RGB图象数据
wire [23:0] post0_img_data;
wire        post0_img_clken;
wire [23:0] post1_img_data;
wire        post1_img_clken;
wire [23:0] post2_img_data;
wire        post2_img_clken;

reg [31:0]  vip_cnt;
reg         vip_out_en;     //寄存VIP处理图像的使能信号，仅维持一帧的时间
reg         vip_out_en1;     //寄存VIP处理图像的使能信号，仅维持一帧的时间
reg [31:0]  vip_out_cnt;
reg [31:0]  vip_out_cnt1;

//-------------------------------------
//寄存图像处理之后的像素数据
 
wire 		vip_out_frame_clken;    
wire [7:0]	vip_out_img_R     ;   
wire [7:0]	vip_out_img_G     ;   
wire [7:0]	vip_out_img_B     ;  

integer iIndex = 0;                 //输出BMP数据索引
integer oBmpFileId;                 //输出BMP图片

reg [31:0] rBmpWord;
initial begin
    clk =1'b1;
    #(CLK_PERIOD/2);
    forever
        #(CLK_PERIOD/2) clk = ~clk;
end

initial begin
    rst_n =   1'b0;
    #20
    rst_n=1'b1;
end

//BMP头文件
initial begin
    //BM
    BMP_HEAD[0 ]  =   BM_WINDOWS[0+:8]   ;
    BMP_HEAD[1 ]  =   BM_WINDOWS[8+:8]   ;
    //bmp file size
    BMP_HEAD[2 ]  =   FILE_SIZE[7-:8]    ;
    BMP_HEAD[3 ]  =   FILE_SIZE[15-:8]   ;
    BMP_HEAD[4 ]  =   FILE_SIZE[23-:8]   ;
    BMP_HEAD[5 ]  =   FILE_SIZE[31-:8]   ;
    //reserved
    BMP_HEAD[6 ]  =   8'h00   ;
    BMP_HEAD[7 ]  =   8'h00   ;
    BMP_HEAD[8 ]  =   8'h00   ;
    BMP_HEAD[9 ]  =   8'h00   ;
    
    //offset
    BMP_HEAD[10]  =   BMP_FILE_HEAD[7-:8]    ;   
    BMP_HEAD[11]  =   BMP_FILE_HEAD[15-:8]   ;
    BMP_HEAD[12]  =   BMP_FILE_HEAD[23-:8]   ;
    BMP_HEAD[13]  =   BMP_FILE_HEAD[31-:8]   ;
    
    //bmp information struct
    BMP_HEAD[14]  =   8'h28   ;
    BMP_HEAD[15]  =   8'h00   ;
    
    BMP_HEAD[16]  =   8'h00   ;
    BMP_HEAD[17]  =   8'h00   ;
    
    //write bmp width
    BMP_HEAD[18]  =   W_BMP_WIDTH[7-:8]    ;
    BMP_HEAD[19]  =   W_BMP_WIDTH[15-:8]   ;
    BMP_HEAD[20]  =   W_BMP_WIDTH[23-:8]   ;
    BMP_HEAD[21]  =   W_BMP_WIDTH[31-:8]   ;
    //write bmp hight
    BMP_HEAD[22]  =   W_BMP_HIGHT[7-:8]    ;
    BMP_HEAD[23]  =   W_BMP_HIGHT[15-:8]   ;
    BMP_HEAD[24]  =   W_BMP_HIGHT[23-:8]   ;
    BMP_HEAD[25]  =   W_BMP_HIGHT[31-:8]   ;
    
    //bit planes
    BMP_HEAD[26]  =   8'h01   ;
    BMP_HEAD[27]  =   8'h00   ;
    
    //one pixel use bits
    BMP_HEAD[28]  =   PIXEL_BITS[7-:8]   ;
    BMP_HEAD[29]  =   PIXEL_BITS[15-:8]   ;
    
    //compress
    BMP_HEAD[30]  =   8'h00   ;
    BMP_HEAD[31]  =   8'h00   ;
    BMP_HEAD[32]  =   8'h00   ;
    BMP_HEAD[33]  =   8'h00   ;
    
    //bmp image size
    BMP_HEAD[34]  =   IMAGE_SIZE[7-:8]    ;
    BMP_HEAD[35]  =   IMAGE_SIZE[15-:8]   ;
    BMP_HEAD[36]  =   IMAGE_SIZE[23-:8]   ;
    BMP_HEAD[37]  =   IMAGE_SIZE[31-:8]   ;
    
    BMP_HEAD[38]  =   8'hC2   ;    
    BMP_HEAD[39]  =   8'h0e   ;
    BMP_HEAD[40]  =   8'h00   ;
    BMP_HEAD[41]  =   8'h00   ;
    
    BMP_HEAD[42]  =   8'hC2   ;
    BMP_HEAD[43]  =   8'h0e   ;
    BMP_HEAD[44]  =   8'h00   ;
    BMP_HEAD[45]  =   8'h00   ;
    //use color board
    BMP_HEAD[46]  =   8'h00   ;
    BMP_HEAD[47]  =   8'h00   ;
    //important color 
    BMP_HEAD[48]  =   8'h00   ;
    BMP_HEAD[49]  =   8'h00   ;
    BMP_HEAD[50]  =   8'h00   ;
    BMP_HEAD[51]  =   8'h00   ;
    BMP_HEAD[52]  =   8'h00   ;
    BMP_HEAD[53]  =   8'h00   ;

    //延迟45ms，等待第一帧VIP处理结束
    #43000000  
    //延迟90ms，等待两帧帧VIP处理结束
    // #86000000      
	oBmpFileId = $fopen("E:\\project\\AnlogicFPGA\\EG4S20\\sd_isp_hdmi\\doc\\pic\\day_img_YUV_RGB1.bmp","wb+");
    //加载图像处理后，BMP图片的文件头和像素数据
	for (iIndex = 0; iIndex < FILE_SIZE; iIndex = iIndex + 1) begin
		if(iIndex < 54)
            wr_bmp_data[iIndex] = BMP_HEAD[iIndex];
        else
            wr_bmp_data[iIndex] = vip_pixel_data[iIndex-54];
	end
    
    //将数组中的数据写到输出BMP图片中        
	for (iIndex = 0; iIndex < FILE_SIZE; iIndex = iIndex + 4) begin
		rBmpWord = {wr_bmp_data[iIndex+3],wr_bmp_data[iIndex+2],wr_bmp_data[iIndex+1],wr_bmp_data[iIndex]};
		$fwrite(oBmpFileId,"%u",rBmpWord);
	end
    //关闭输出BMP图片
	$fclose(oBmpFileId);
end

//-----------------------------------
//ISP算法模块例化
//-----------------------------------
image_src u_image_src(
    //port decleared
    .clk        (clk),   //同步时钟
    .rst_n      (rst_n), //全局复位
    
    .src_sel    (0),  //数据源通道选择
    .test_clken (per_img_clken),
    .test_data  (per_img_data)
);      
    

dpc_top u_dpc_top
(
    .clk             	( clk              ),
    .rstn            	( rst_n             ),
    .threshold       	( 20        ),
    .in_raw_data_en  	( per_img_clken     ),
    .in_raw_data     	( per_img_data[15:8]      ),
    .out_raw_data_en 	( post0_img_clken  ),
    .out_raw_data    	( post0_img_data     )
);
reg test = 1'b1;
wire [7:0]inputdata;
assign inputdata = per_img_data[15:8];
bayer2rgb u_bayer2rgb
(
    .clk      	( clk               ),
    .rstn     	( rst_n             ),
    .in_href  	( post0_img_clken       ),
    .in_raw   	( post0_img_data         ),
    .out_href 	( post1_img_clken   ),
    .out_rgb  	( post1_img_data    )
);

reg [7:0] per_raw_data;
reg [7:0] per_raw_cnt;
reg       per_raw_clken;
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        per_raw_data <= 8'd0;
        per_raw_clken <= 1'b0;
    end else begin
        if (per_raw_data == 'd241) begin
            per_raw_data <= 'd0;
            if(per_raw_cnt == 'd63)
                per_raw_cnt <= 'd63;
            else
                per_raw_cnt <= per_raw_cnt + 1'b1;
        end
        else
            per_raw_data <= per_raw_data + 1'b1;
        per_raw_clken <= 1'b1;
    end

end

gaussian_top u_gaussian_top(
    .pclk           	( clk             ),
    .rst_n          	( rst_n           ),
    .per_raw_data   	( per_raw_data    ),
    .per_raw_clken  	( per_raw_clken   ),
    .post_raw_data  	( post_raw_data   ),
    .post_raw_clken 	( post_raw_clken  )
);

reg [23:0] win_data0,win_data_en0;
reg [23:0] win_data1,win_data_en1;
reg [7:0] delaycnt;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        delaycnt <= 8'd0;
    end else if (delaycnt != 5)
        delaycnt  <= delaycnt + 1'b1;
    else
        delaycnt <= delaycnt;
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        win_data0 <= 24'd0;
        win_data_en0 <= 1'b0;
    end else if(delaycnt == 8'd5)begin
        win_data_en0 <= 1'b1;
        if(win_data0 == 24'd1936)
            win_data0 <= 24'd1;
        else
            win_data0 <= win_data0 + 1'b1;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        win_data1 <= 24'd0;
        win_data_en1 <= 1'b0;
    end else if(delaycnt == 8'd5) begin
        win_data_en1 <= 1'b1;
        if(win_data1 == 24'd1936)
            win_data1 <= 24'd1;
        else
            win_data1 <= win_data1 + 1'b1;
    end
end




// outports wire
wire        	sdram_data_en;
wire [15:0] 	sdram_data;
reg             split_en;
window_split #(
    .WIN_X       	( 0  ),
    .WIN_Y       	( 0  ),
    .WIDTH       	( 1936     ),
    .HEIGHT      	( 1088     ),
    .HDMI_HPIXEL 	( 1920  ),
    .HDMI_VPIXEL 	( 1080  )
)u_window_split(
    .clk           	( clk            ),
    .rstn          	( rst_n           ),
    .win_data_en0  	( win_data_en0   ),
    .win_data_en1  	( win_data_en1   ),
    .win_data0     	( win_data0      ),
    .win_data1     	( win_data1      ),
    .sdram_data_en 	( sdram_data_en  ),
    .sdram_data    	( sdram_data     ),
    .split_en       ( split_en       )
);

wire  hdmi_de = (delaycnt == 8'd5) ? 1'b1 : 1'b0;
page u_page(
    .clk       	( clk        ),
    .clk_ref   	( clk        ),
    .rstn      	( rst_n      ),
    .isp_data  	( win_data0   ),
    .page_addr 	( page_addr  ),
    .page_data 	( page_data  ),
    .app_en    	( 1'b1       ),
    .hdmi_de   	( hdmi_de    ),
    .hdmi_data 	( hdmi_data  )
);




//-------------------------------------
//输出图像处理 
assign vip_out_frame_clken = post1_img_clken;    
assign vip_out_img_R       = {post1_img_data[23:16]};
assign vip_out_img_G       = {post1_img_data[15:8]};
assign vip_out_img_B       = {post1_img_data[7:0]};
// assign vip_out_img_R       = post0_img_data[15:8] ;   
// assign vip_out_img_G       = post0_img_data[15:8] ;   
// assign vip_out_img_B       = post0_img_data[15:8] ; 

always@(posedge clk or negedge rst_n)begin
    if(!rst_n) 
        vip_out_cnt    <=  'b0;
    else if(vip_out_cnt == W_BMP_WIDTH*W_BMP_HIGHT - 1)
        vip_out_cnt    <=  'b0;
    else if(vip_out_frame_clken) 
        vip_out_cnt <= vip_out_cnt + 1;
    else 
        vip_out_cnt <= vip_out_cnt;
end     
always@(posedge clk or negedge rst_n)begin
   if(!rst_n) 
        vip_out_en    <=  1'b1;
   else if(vip_out_cnt == W_BMP_WIDTH*W_BMP_HIGHT - 1)  //第一帧结束之后，使能拉低
        vip_out_en    <=  1'b0;
end


always@(posedge clk or negedge rst_n)begin
   if(!rst_n) 
        vip_out_en1    <=  1'b1;
   else if((vip_out_cnt == W_BMP_WIDTH*W_BMP_HIGHT - 1) && (!vip_out_en))  //第二帧结束之后，使能拉低
        vip_out_en1    <=  1'b0;
end


always@(posedge clk or negedge rst_n)begin
   if(!rst_n) begin
        vip_cnt <=  32'd0;
   end
   else if( vip_out_en /* !vip_out_en && vip_out_en1 */) begin
        if(vip_out_frame_clken) begin
            vip_cnt <=  vip_cnt + 3;
            vip_pixel_data[vip_cnt+0] <= vip_out_img_R;
            vip_pixel_data[vip_cnt+1] <= vip_out_img_G;
            vip_pixel_data[vip_cnt+2] <= vip_out_img_B;
        end
   end
end
// glbl glbl();
endmodule   
