module ispMUX(
    input  wire         rgb_clk,
    input  wire         raw_clk,
    input  wire         yuv_clk,
    input  wire         mux_clk,
    input  wire         rst_n,

    input  wire [31:0]  isp_data_num0to7,
    input  wire [31:0]  isp_data_num8to15,
    input  wire [15:0]  per_sd_data,
    input  wire         per_sd_data_en,

    output wire [23:0]  post_isp_data0,
    output wire         post_isp_data_en0,

    output wire [23:0]  post_isp_data1,
    output wire         post_isp_data_en1

);

localparam ispNum = 15;
// wire [23:0] ispTempData      [0:ispNum+1];
// wire        ispTempData_en   [0:ispNum+1];
reg [23:0] ispTempData      [0:ispNum+1];
reg        ispTempData_en   [0:ispNum+1];

wire [7:0] bayer_data;

reg [31:0] isp_data_num0to7_r;
reg [31:0] isp_data_num8to15_r;


wire [3:0]  dpc     =  isp_data_num0to7_r [31:28] ;
wire [3:0]  blc     =  isp_data_num0to7_r [27:24] ;
wire [3:0]  bayer   =  isp_data_num0to7_r [23:20] ;
wire [3:0]  wb      =  isp_data_num0to7_r [19:16] ;
wire [3:0]  ccm     =  isp_data_num0to7_r [15:12] ;
wire [3:0]  gamma   =  isp_data_num0to7_r [11:8 ] ;
wire [3:0]  yuv     =  isp_data_num0to7_r [ 7:4 ] ;
wire [3:0]  lap     =  isp_data_num0to7_r [ 3:0 ] ;
wire [3:0]  dnr     =  isp_data_num8to15_r[31:28] ;
wire [3:0]  rgb     =  isp_data_num8to15_r[27:24] ;
wire [3:0]  haze    =  isp_data_num8to15_r[23:20] ;
wire [3:0]  hdr     =  isp_data_num8to15_r[19:16] ;
wire [3:0]  gau     =  isp_data_num8to15_r[15:12] ;
wire [3:0]  bnr     =  isp_data_num8to15_r[11:8 ] ;
wire [3:0]  ispL    =  isp_data_num8to15_r[ 7:4 ] ;
wire [3:0]  ispR    =  isp_data_num8to15_r[ 3:0 ] ;
// reg [3:0]  dpc    = 1 ;
// reg [3:0]  blc    = 2 ;
// reg [3:0]  bayer  = 3 ;
// reg [3:0]  wb     = 4 ;
// reg [3:0]  ccm    = 5 ;
// reg [3:0]  gamma  = 6 ;
// reg [3:0]  yuv    = 7 ;
// reg [3:0]  lap    = 8 ;
// reg [3:0]  dnr    = 9 ;
// reg [3:0]  rgb    = 10 ;
// reg [3:0]  haze   = 11 ;
// reg [3:0]  hdr    = 12 ;
// reg [3:0]  gau    = 13 ;
// reg [3:0]  bnr    = 14 ;
// reg [3:0]  isp    = 15 ;
// always @(posedge mux_clk) begin
//         dpc     <=  isp_data_num0to7_r [31:28] ;
//         blc     <=  isp_data_num0to7_r [27:24] ;
//         bayer   <=  isp_data_num0to7_r [23:20] ;
//         wb      <=  isp_data_num0to7_r [19:16] ;
//         ccm     <=  isp_data_num0to7_r [15:12] ;
//         gamma   <=  isp_data_num0to7_r [11:8 ] ;
//         yuv     <=  isp_data_num0to7_r [ 7:4 ] ;
//         lap     <=  isp_data_num0to7_r [ 3:0 ] ;
//         dnr     <=  isp_data_num8to15_r[31:28] ;
//         rgb     <=  isp_data_num8to15_r[27:24] ;
//         haze    <=  isp_data_num8to15_r[23:20] ;
//         hdr     <=  isp_data_num8to15_r[19:16] ;
//         gau     <=  isp_data_num8to15_r[15:12] ;
//         bnr     <=  isp_data_num8to15_r[11:8 ] ;
//         isp     <=  isp_data_num8to15_r[ 7:4 ] ;

// end
parameter WIDTH = 1936;         //原图分辨率
parameter HEIGHT = 1088;        //原图分辨率
//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

//h_cnt:行同步信号计数器
always@(posedge mux_clk or negedge rst_n)
    if(rst_n == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(per_sd_data_en == 1'b1)
        if(h_cnt == WIDTH - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge mux_clk or negedge rst_n)
    if(rst_n == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(per_sd_data_en == 1'b1)
        if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == WIDTH - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;


always @(posedge mux_clk) begin
    if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))begin
        isp_data_num0to7_r  <= isp_data_num0to7 ;
        isp_data_num8to15_r <= isp_data_num8to15;
    end else begin
        isp_data_num0to7_r  <= isp_data_num0to7 ;
        isp_data_num8to15_r <= isp_data_num8to15;
    end
end
// always @(posedge mux_clk) begin
//     if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))begin
//         isp_data_num0to7_r  <= isp_data_num0to7 ;
//         isp_data_num8to15_r <= isp_data_num8to15;
//     end else begin
//         isp_data_num0to7_r  <= isp_data_num0to7_r ;
//         isp_data_num8to15_r <= isp_data_num8to15_r;
//     end
// end


// wire [3:0]  dpc     = 0 ;
// wire [3:0]  blc     = 0 ;
// wire [3:0]  bayer   = 1 ;
// wire [3:0]  wb      = 3 ;
// wire [3:0]  ccm     = 0 ;
// wire [3:0]  gamma   = 0 ;
// wire [3:0]  yuv     = 0 ;
// wire [3:0]  lap     = 0 ;
// wire [3:0]  dnr     = 0 ;
// wire [3:0]  rgb     = 0 ;
// wire [3:0]  haze    = 0 ;
// wire [3:0]  hdr     = 0 ;
// wire [3:0]  gau     = 0 ;
// wire [3:0]  bnr     = 0 ;
// wire [3:0]  isp     = 4 ;

// dpc
wire       	dpc_raw_data_en;
wire [7:0] 	dpc_raw_data;
// bayer
wire        bayer_rgb_en;
wire [23:0] bayer_rgb;
// blc
wire [7:0]  blc_raw_data;
wire        blc_raw_data_en;
// wb
wire [23:0] wb_rgb_data;
wire        wb_rgb_data_en;
// ccm
wire        out_ccm_rgb_en;
wire [23:0] out_ccm_rgb;
//gamma
wire        out_gamma_rgb_en;
wire [23:0] out_gamma_rgb;
//csc
wire        csc_YCbCr_en;
wire [23:0] csc_YCbCr;
//laplacian_sharpen
wire        lap_yuv_data_en;
wire [23:0] lap_yuv_data;
//2dnr
wire        bilateral_data_en;
wire [23:0] bilateral_data;
//hazz
wire        haze_rgb_data_en;
wire [23:0] haze_rgb_data;

wire        csc_RGB_en;
wire [23:0] csc_RGB;

wire        hdr_YUV_en;
wire [23:0] hdr_YUV;

wire        gau_raw_en;
wire [7:0]  gau_raw;

wire        bnr_raw_en;
wire [7:0]  bnr_raw;

/*
ID      ISP_name

[0]     bayer_data
[1]     dpc_raw_data
[2]     blc_raw_data
[3]     bayer_rgb
[4]     wb_rgb_data
[5]     out_ccm_rgb
[6]     out_gamma_rgb
[7]     csc_YCbCr
[8]     lap_yuv_data
[9]     bilateral_data
[10]    csc_RGB
[11]    haze_rgb_data
[12]    hdr_YUV
[13]    gau_raw
[14]    bnr_raw
*/
always @(posedge mux_clk) begin
    case(dpc)
        4'd0:begin       ispTempData[1] <= bayer_data;     ispTempData_en[1] <= per_sd_data_en ; end
        4'd2:begin       ispTempData[1] <= blc_raw_data;   ispTempData_en[1] <= blc_raw_data_en ;end
        4'd14:begin      ispTempData[1] <= bnr_raw;        ispTempData_en[1] <= bnr_raw_en ;     end
        default:begin    ispTempData[1] <= bayer_data;     ispTempData_en[1] <= per_sd_data_en ; end
    endcase
end
always @(posedge mux_clk) begin
    case(blc)
        4'd0:begin       ispTempData[2] <= bayer_data;     ispTempData_en[2] <= per_sd_data_en ; end
        4'd1:begin       ispTempData[2] <= dpc_raw_data;   ispTempData_en[2] <= dpc_raw_data_en ;end
        4'd14:begin      ispTempData[2] <= bnr_raw;        ispTempData_en[2] <= bnr_raw_en ;     end
        default:begin    ispTempData[2] <= bayer_data;     ispTempData_en[2] <= per_sd_data_en ; end
    endcase
end
always @(posedge mux_clk) begin
    case(bnr)
        4'd0:begin       ispTempData[14] <= bayer_data;     ispTempData_en[14] <= per_sd_data_en ; end
        4'd1:begin       ispTempData[14] <= dpc_raw_data;   ispTempData_en[14] <= dpc_raw_data_en ;end
        4'd2:begin       ispTempData[14] <= blc_raw_data;   ispTempData_en[14] <= blc_raw_data_en ;end
        default:begin    ispTempData[14] <= bayer_data;     ispTempData_en[14] <= per_sd_data_en ; end
    endcase
end
always @(posedge mux_clk) begin
    case(bayer)
        4'd0:begin       ispTempData[3] <= bayer_data;   ispTempData_en[3] <= per_sd_data_en ;   end
        4'd1:begin       ispTempData[3] <= dpc_raw_data; ispTempData_en[3] <= dpc_raw_data_en ;  end
        4'd2:begin       ispTempData[3] <= blc_raw_data; ispTempData_en[3] <= blc_raw_data_en ;  end
        4'd14:begin      ispTempData[3] <= bnr_raw;      ispTempData_en[3] <= bnr_raw_en ;       end
        default:begin    ispTempData[3] <= bayer_data;   ispTempData_en[3] <= per_sd_data_en ;   end
    endcase
end
always @(posedge mux_clk) begin
    case(wb)
        4'd3:begin       ispTempData[4] <= bayer_rgb;       ispTempData_en[4] <= bayer_rgb_en ;    end
        4'd5:begin       ispTempData[4] <= out_ccm_rgb;     ispTempData_en[4] <= out_ccm_rgb_en ;  end
        4'd6:begin       ispTempData[4] <= out_gamma_rgb;   ispTempData_en[4] <= out_gamma_rgb_en ;end
        4'd11:begin      ispTempData[4] <= haze_rgb_data;   ispTempData_en[4] <= haze_rgb_data_en ;end
        default:begin    ispTempData[4] <= bayer_rgb;       ispTempData_en[4] <= bayer_rgb_en ;    end
    endcase
end
always @(posedge mux_clk) begin
    case(ccm)
        4'd3:begin       ispTempData[5] <= bayer_rgb;       ispTempData_en[5] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[5] <= wb_rgb_data;     ispTempData_en[5] <= wb_rgb_data_en ;  end
        4'd6:begin       ispTempData[5] <= out_gamma_rgb;   ispTempData_en[5] <= out_gamma_rgb_en ;end
        4'd11:begin      ispTempData[5] <= haze_rgb_data;   ispTempData_en[5] <= haze_rgb_data_en ;end
        default:begin    ispTempData[5] <= bayer_rgb;       ispTempData_en[5] <= bayer_rgb_en ;    end
    endcase
end
always @(posedge mux_clk) begin
    case(gamma)
        4'd3:begin       ispTempData[6] <= bayer_rgb;       ispTempData_en[6] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[6] <= wb_rgb_data;     ispTempData_en[6] <= wb_rgb_data_en ;  end
        4'd5:begin       ispTempData[6] <= out_ccm_rgb;     ispTempData_en[6] <= out_ccm_rgb_en ;  end
        4'd11:begin      ispTempData[6] <= haze_rgb_data;   ispTempData_en[6] <= haze_rgb_data_en ;end
        default:begin    ispTempData[6] <= bayer_rgb;       ispTempData_en[6] <= bayer_rgb_en ;    end
    endcase
end
always @(posedge mux_clk) begin
    case(haze)
        4'd3:begin       ispTempData[11] <= bayer_rgb;       ispTempData_en[11] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[11] <= wb_rgb_data;     ispTempData_en[11] <= wb_rgb_data_en ;  end
        4'd5:begin       ispTempData[11] <= out_ccm_rgb;     ispTempData_en[11] <= out_ccm_rgb_en ;  end
        4'd6:begin       ispTempData[11] <= out_gamma_rgb;   ispTempData_en[11] <= out_gamma_rgb_en ;end
        default:begin    ispTempData[11] <= bayer_rgb;       ispTempData_en[11] <= bayer_rgb_en ;    end
    endcase
end
always @(posedge mux_clk) begin
    case(yuv)
        4'd3:begin       ispTempData[7] <= bayer_rgb;       ispTempData_en[7] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[7] <= wb_rgb_data;     ispTempData_en[7] <= wb_rgb_data_en ;  end
        4'd5:begin       ispTempData[7] <= out_ccm_rgb;     ispTempData_en[7] <= out_ccm_rgb_en ;  end
        4'd6:begin       ispTempData[7] <= out_gamma_rgb;   ispTempData_en[7] <= out_gamma_rgb_en ;end
        4'd11:begin      ispTempData[7] <= haze_rgb_data;   ispTempData_en[7] <= haze_rgb_data_en ;end
        default:begin    ispTempData[7] <= bayer_rgb;       ispTempData_en[7] <= bayer_rgb_en ;    end
    endcase
end

always @(posedge mux_clk) begin
    case(lap)
        4'd7:begin       ispTempData[8] <= csc_YCbCr;       ispTempData_en[8] <= csc_YCbCr_en ;      end
        4'd9:begin       ispTempData[8] <= bilateral_data;  ispTempData_en[8] <= bilateral_data_en ; end
        4'd12:begin      ispTempData[8] <= hdr_YUV;         ispTempData_en[8] <= hdr_YUV_en ;        end
        default:begin    ispTempData[8] <= csc_YCbCr;       ispTempData_en[8] <= csc_YCbCr_en ;      end
    endcase
end
always @(posedge mux_clk) begin
    case(dnr)
        4'd7:begin       ispTempData[9] <= csc_YCbCr;       ispTempData_en[9] <= csc_YCbCr_en ;      end
        4'd8:begin       ispTempData[9] <= lap_yuv_data;    ispTempData_en[9] <= lap_yuv_data_en ;   end
        4'd12:begin      ispTempData[9] <= hdr_YUV;         ispTempData_en[9] <= hdr_YUV_en ;        end
        default:begin    ispTempData[9] <= csc_YCbCr;       ispTempData_en[9] <= csc_YCbCr_en ;      end
    endcase
end
always @(posedge mux_clk) begin
    case(hdr)
        4'd7:begin       ispTempData[12] <= csc_YCbCr;       ispTempData_en[12] <= csc_YCbCr_en ;      end
        4'd8:begin       ispTempData[12] <= lap_yuv_data;    ispTempData_en[12] <= lap_yuv_data_en ;   end
        4'd9:begin       ispTempData[12] <= bilateral_data;  ispTempData_en[12] <= bilateral_data_en ; end
        default:begin    ispTempData[12] <= csc_YCbCr;       ispTempData_en[12] <= csc_YCbCr_en ;      end
    endcase
end
always @(posedge mux_clk) begin
    case(rgb)
        4'd7:begin       ispTempData[10] <= csc_YCbCr;       ispTempData_en[10] <= csc_YCbCr_en ;      end
        4'd8:begin       ispTempData[10] <= lap_yuv_data;    ispTempData_en[10] <= lap_yuv_data_en ;   end
        4'd9:begin       ispTempData[10] <= bilateral_data;  ispTempData_en[10] <= bilateral_data_en ; end
        4'd12:begin      ispTempData[10] <= hdr_YUV;         ispTempData_en[10] <= hdr_YUV_en ;        end
        default:begin    ispTempData[10] <= csc_YCbCr;       ispTempData_en[10] <= csc_YCbCr_en ;      end
    endcase
end


always @(posedge mux_clk) begin
    case(ispL)
        4'd3:begin       ispTempData[15] <= bayer_rgb;      ispTempData_en[15] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[15] <= wb_rgb_data;    ispTempData_en[15] <= wb_rgb_data_en ;  end
        4'd5:begin       ispTempData[15] <= out_ccm_rgb;    ispTempData_en[15] <= out_ccm_rgb_en ;  end
        4'd6:begin       ispTempData[15] <= out_gamma_rgb;  ispTempData_en[15] <= out_gamma_rgb_en ;end
        4'd10:begin      ispTempData[15] <= csc_RGB;        ispTempData_en[15] <= csc_RGB_en ;      end
        4'd11:begin      ispTempData[15] <= haze_rgb_data;  ispTempData_en[15] <= haze_rgb_data_en ;end
        default:begin    ispTempData[15] <= bayer_rgb;      ispTempData_en[15] <= bayer_rgb_en ;    end
    endcase
end
always @(posedge mux_clk) begin
    case(ispR)
        4'd3:begin       ispTempData[16] <= bayer_rgb;      ispTempData_en[16] <= bayer_rgb_en ;    end
        4'd4:begin       ispTempData[16] <= wb_rgb_data;    ispTempData_en[16] <= wb_rgb_data_en ;  end
        4'd5:begin       ispTempData[16] <= out_ccm_rgb;    ispTempData_en[16] <= out_ccm_rgb_en ;  end
        4'd6:begin       ispTempData[16] <= out_gamma_rgb;  ispTempData_en[16] <= out_gamma_rgb_en ;end
        4'd10:begin      ispTempData[16] <= csc_RGB;        ispTempData_en[16] <= csc_RGB_en ;      end
        4'd11:begin      ispTempData[16] <= haze_rgb_data;  ispTempData_en[16] <= haze_rgb_data_en ;end
        default:begin    ispTempData[16] <= bayer_rgb;      ispTempData_en[16] <= bayer_rgb_en ;    end
    endcase
end



//bayer数据预处理
log12bitsTo8bits u_log12bitsTo8bits(
    .Pre_Data  	( per_sd_data[15:4]   ),
    .Post_Data 	( bayer_data          )
);

dpc_top u_dpc_top(
    .pclk             	( raw_clk          ),
    .rst_n            	( rst_n            ),
    .threshold       	( 16'd20           ),//测试不同阈值下的检测效果
    .in_href  	        ( ispTempData_en[1] ),
    .in_raw     	    ( ispTempData   [1]    ),/* input 8bits */
    .out_href 	        ( dpc_raw_data_en  ),
    .out_raw    	    ( dpc_raw_data     )
);
isp_blc u_isp_blc
(   
    .clk                ( raw_clk           ),
    .rst_n              ( rst_n             ),
    .black_gb           ( 8'd5              ),
    .black_b            ( 8'd5              ),
    .black_r            ( 8'd5              ),
    .black_gr           ( 8'd5              ),
    .per_raw_data_en    ( ispTempData_en[2]   ),
    .per_raw_data       ( ispTempData   [2]      ),
    .post_raw_data_en   ( blc_raw_data_en   ),
    .post_raw_data      ( blc_raw_data      )
);

// gaussian_top u_gaussian_top(
//     .pclk           	( isp_clk           ),
//     .rst_n          	( rst_n             ),
//     .per_raw_clken  	( ispTempData_en[]    ),
//     .per_raw_data   	( ispTempData[0]       ),
//     .post_raw_clken 	( gau_raw_en        ),
//     .post_raw_data  	( gau_raw           )
// );





isp_bnr u_isp_bnr(
    .pclk      	( raw_clk       ),
    .rst_n     	( rst_n         ),
    .nr_level  	( 'd2           ),
    .in_href   	( ispTempData_en[14]  ),
    .in_raw    	( ispTempData   [14]     ),
    .out_href  	( bnr_raw_en    ),
    .out_raw   	( bnr_raw       )
);


bayer2rgb u_bayer2rgb(
    .clk                ( raw_clk           ),
    .rstn               ( rst_n             ),
    .in_href   	        ( ispTempData_en[3]      ),
    .in_raw         	( ispTempData   [3]   ),
    .out_href 	        ( bayer_rgb_en      ),
    .out_rgb       	    ( bayer_rgb         )
);
gamma_top u_gamma_top(
    .gamma_en      	( 1'b1              ),
    .pre_rgb_en    	( ispTempData_en[6]      ),
    .pre_rgb_data  	( ispTempData   [6]         ),
    .post_rgb_en   	( out_gamma_rgb_en  ),
    .post_rgb_data 	( out_gamma_rgb     )
);
//加上了去雾算法会导致时钟违例严重100m->20m
// Hazze_Removal_top #(
//     .IMG_HDISP 	( 11'd1936  ),
//     .IMG_VDISP 	( 11'd1088  )
// )u_Hazze_Removal_top(
//     .clk              	( rgb_clk           ),
//     .rst_n            	( rst_n             ),
//     .per_frame_vsync  	( 1'b1              ),
//     .per_frame_href   	( 1'b1              ),
//     .per_frame_clken  	( ispTempData_en[11]   ),
//     .per_img_data     	( ispTempData   [11]      ),
//     .post_frame_vsync 	(                   ),
//     .post_frame_href  	(                   ),
//     .post_frame_clken 	( haze_rgb_data_en  ),
//     .post_img_data    	( haze_rgb_data     )
// );


white_balenceb_top u_white_balenceb_top
(
    .clk            	( rgb_clk         ),
    .rst_n          	( rst_n           ),
    .per_img_clken  	( ispTempData_en[4]    ),
    .per_img_data   	( ispTempData   [4]       ),
    .post_img_clken 	( wb_rgb_data_en  ),
    .post_img_data  	( wb_rgb_data     )
);


isp_ccm u_isp_ccm
(
    .pclk           	( rgb_clk         ),
    .rst_n          	( rst_n           ),
    .in_rgb_data_en 	( ispTempData_en[5]  ),
    .in_rgb_data    	( ispTempData   [5]     ),
    .out_ccm_rgb_en 	( out_ccm_rgb_en  ),
    .out_ccm_rgb    	( out_ccm_rgb     )
);
VIP_RGB888_YCbCr444 u_VIP_RGB888_YCbCr444(
    .clk              	( rgb_clk               ),
    .rst_n            	( rst_n                 ),
    .per_frame_vsync  	( 1'b1                  ),
    .per_frame_href   	( 1'b1                  ),
    .per_frame_clken  	( ispTempData_en[7]    ),
    .per_img_data     	( ispTempData   [7]       ),
    .post_frame_vsync 	(                       ),
    .post_frame_href  	(                       ),
    .post_frame_clken 	( csc_YCbCr_en          ),
    .post_img_YCbCr     ( csc_YCbCr             )
); 
laplacian_sharpen_proc u_laplacian_sharpen_proc(
    .clk            	( yuv_clk         ),
    .rst_n          	( rst_n           ),
    .per_img_vsync  	( 1'b1            ),
    .per_img_href   	( 1'b1            ),
    .per_img_clken  	(ispTempData_en[8]   ),
    .per_img_data   	(ispTempData   [8]      ),
    
    .post_img_vsync 	(                 ),
    .post_img_href  	(                 ),
    .post_img_clken 	( lap_yuv_data_en ),
    .post_img_data  	( lap_yuv_data    )
);


HDR u_HDR(
    .Pre_YUV_en  	( ispTempData_en[12]   ),
    .Pre_YUV     	( ispTempData   [12]      ),
    .Post_YUV_en 	( hdr_YUV_en            ),
    .Post_YUV    	( hdr_YUV               )
);


isp_2dnr #(
    .BITS        	( 8     ),
    .WIDTH       	( 1936  ),
    .HEIGHT      	( 1088  ),
    .WEIGHT_BITS 	( 5     )
)u_isp_2dnr /* synthesis keep_hierarchy=true */ (
    .pclk          	( yuv_clk               ),
    .rst_n         	( rst_n                 ),
    .in_href       	( ispTempData_en[9]   ),
    .in_yuv_data    ( ispTempData   [9]      ),
    .out_href      	( bilateral_data_en     ),
    .out_yuv_data  	( bilateral_data        )
);
VIP_YCbCr444_RGB888 u_VIP_YCbCr444_RGB888(
    .clk              	( yuv_clk               ),
    .rst_n            	( rst_n                 ),
    .per_frame_vsync  	( 1'b1                  ),
    .per_frame_href   	( 1'b1                  ),
    .per_frame_clken  	( ispTempData_en[10]   ),
    .per_img_data       ( ispTempData   [10]      ),
    .post_frame_vsync 	(                       ),
    .post_frame_href  	(                       ),
    .post_frame_clken 	( csc_RGB_en            ),
    .post_img_rgb       ( csc_RGB               )
);

assign  post_isp_data_en0 = ispTempData_en[15];
assign  post_isp_data0 = ispTempData      [15];

assign  post_isp_data_en1 = ispTempData_en[16];
assign  post_isp_data1 = ispTempData      [16];



endmodule //ispMUX

