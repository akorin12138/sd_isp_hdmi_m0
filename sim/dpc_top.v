module dpc_top#(
    parameter WIN_X = 11'd500,      //窗口x坐标
    parameter WIN_Y = 11'd500,      //窗口y坐标
    parameter HDMI_HPIXEL = 11'd640,
    parameter HDMI_VPIXEL = 11'd480,
    parameter RAW_HPIXEL = 11'd1936,
    parameter RAW_VPIXEL = 11'd1088,
    parameter BITS = 8
)(
input  wire clk,
input  wire rstn,

input  wire [7:0]   threshold, //阈值越小,检测越松,坏点检测数越多

input  wire         in_raw_data_en,
input  wire [7:0]   in_raw_data,

output wire         out_raw_data_en,
output wire [7:0]   out_raw_data
);
// outports wire
wire       	matrix_frame_clken;
wire [7:0] 	matrix_p11;
wire [7:0] 	matrix_p12;
wire [7:0] 	matrix_p13;
wire [7:0] 	matrix_p14;
wire [7:0] 	matrix_p15;
wire [7:0] 	matrix_p21;
wire [7:0] 	matrix_p22;
wire [7:0] 	matrix_p23;
wire [7:0] 	matrix_p24;
wire [7:0] 	matrix_p25;
wire [7:0] 	matrix_p31;
wire [7:0] 	matrix_p32;
wire [7:0] 	matrix_p33;
wire [7:0] 	matrix_p34;
wire [7:0] 	matrix_p35;
wire [7:0] 	matrix_p41;
wire [7:0] 	matrix_p42;
wire [7:0] 	matrix_p43;
wire [7:0] 	matrix_p44;
wire [7:0] 	matrix_p45;
wire [7:0] 	matrix_p51;
wire [7:0] 	matrix_p52;
wire [7:0] 	matrix_p53;
wire [7:0] 	matrix_p54;
wire [7:0] 	matrix_p55;

reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

vip_matrix_generate_5x5_8bit u_vip_matrix_generate_5x5_8bit(
    .clk                	( clk                 ),
    .rst_n              	( rstn                ),
    .per_frame_vsync    	( 1'b1                ),
    .per_frame_href     	( 1'b1                ),
    .per_frame_clken    	( in_raw_data_en      ),
    .per_img_y          	( in_raw_data         ),
    .matrix_frame_vsync 	(                     ),
    .matrix_frame_href  	(                     ),
    .matrix_frame_clken 	( matrix_frame_clken  ),
    .matrix_p11         	( matrix_p11          ),
    .matrix_p12         	( matrix_p12          ),
    .matrix_p13         	( matrix_p13          ),
    .matrix_p14         	( matrix_p14          ),
    .matrix_p15         	( matrix_p15          ),
    .matrix_p21         	( matrix_p21          ),
    .matrix_p22         	( matrix_p22          ),
    .matrix_p23         	( matrix_p23          ),
    .matrix_p24         	( matrix_p24          ),
    .matrix_p25         	( matrix_p25          ),
    .matrix_p31         	( matrix_p31          ),
    .matrix_p32         	( matrix_p32          ),
    .matrix_p33         	( matrix_p33          ),
    .matrix_p34         	( matrix_p34          ),
    .matrix_p35         	( matrix_p35          ),
    .matrix_p41         	( matrix_p41          ),
    .matrix_p42         	( matrix_p42          ),
    .matrix_p43         	( matrix_p43          ),
    .matrix_p44         	( matrix_p44          ),
    .matrix_p45         	( matrix_p45          ),
    .matrix_p51         	( matrix_p51          ),
    .matrix_p52         	( matrix_p52          ),
    .matrix_p53         	( matrix_p53          ),
    .matrix_p54         	( matrix_p54          ),
    .matrix_p55         	( matrix_p55          )
);

// parameter RAW_HPIXEL = 11'd1920;
// parameter RAW_VPIXEL = 11'd1080;
//输入的一帧图像大小为1936x1088


//h_cnt:行同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(matrix_frame_clken == 1'b1)
        if(h_cnt == RAW_HPIXEL - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(matrix_frame_clken == 1'b1)
        if((v_cnt == RAW_VPIXEL - 1'd1) &&  (h_cnt == RAW_HPIXEL-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == RAW_HPIXEL - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

//          GBGBG
//          RGRGR
//          GBGBG
//          RGRGR
//          GBGBG
reg [BITS-1:0] t1_p1, t1_p2, t1_p3;
reg [BITS-1:0] t1_p4, t1_p5, t1_p6;
reg [BITS-1:0] t1_p7, t1_p8, t1_p9;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t1_p1 <= 0; t1_p2 <= 0; t1_p3 <= 0;
        t1_p4 <= 0; t1_p5 <= 0; t1_p6 <= 0;
        t1_p7 <= 0; t1_p8 <= 0; t1_p9 <= 0;
    end
    else begin
        case ({v_cnt[0],h_cnt[0]})
            2'd1,2'd2: begin //Gr/Gb
                t1_p1 <= matrix_p11; t1_p2 <= matrix_p13; t1_p3 <= matrix_p15;
                t1_p4 <= matrix_p31; t1_p5 <= matrix_p33; t1_p6 <= matrix_p35;
                t1_p7 <= matrix_p51; t1_p8 <= matrix_p53; t1_p9 <= matrix_p55;
            end
            2'd0,2'd3: begin //B/R
                t1_p1 <= matrix_p22; t1_p2 <= matrix_p13; t1_p3 <= matrix_p24;
                t1_p4 <= matrix_p31; t1_p5 <= matrix_p33; t1_p6 <= matrix_p35;
                t1_p7 <= matrix_p42; t1_p8 <= matrix_p53; t1_p9 <= matrix_p44;
            end
            default: begin
                t1_p1 <= 0; t1_p2 <= 0; t1_p3 <= 0;
                t1_p4 <= 0; t1_p5 <= 0; t1_p6 <= 0;
                t1_p7 <= 0; t1_p8 <= 0; t1_p9 <= 0;
            end
        endcase
    end
end

//中值滤波 step1
reg [BITS-1:0] t2_min1, t2_med1, t2_max1;
reg [BITS-1:0] t2_min2, t2_med2, t2_max2;
reg [BITS-1:0] t2_min3, t2_med3, t2_max3;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t2_min1 <= 0; t2_med1 <= 0; t2_max1 <= 0;
        t2_min2 <= 0; t2_med2 <= 0; t2_max2 <= 0;
        t2_min3 <= 0; t2_med3 <= 0; t2_max3 <= 0;
    end
    else begin
        t2_min1 <= min(t1_p1, t1_p2, t1_p3);
        t2_med1 <= med(t1_p1, t1_p2, t1_p3);
        t2_max1 <= max(t1_p1, t1_p2, t1_p3);
        t2_min2 <= min(t1_p4, t1_p5, t1_p6);
        t2_med2 <= med(t1_p4, t1_p5, t1_p6);
        t2_max2 <= max(t1_p4, t1_p5, t1_p6);
        t2_min3 <= min(t1_p7, t1_p8, t1_p9);
        t2_med3 <= med(t1_p7, t1_p8, t1_p9);
        t2_max3 <= max(t1_p7, t1_p8, t1_p9);
    end
end

//中值滤波 step2
reg [BITS-1:0] t3_max_of_min, t3_med_of_med, t3_min_of_max; 
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t3_max_of_min <= 0; t3_med_of_med <= 0; t3_min_of_max <= 0;
    end
    else begin
        t3_max_of_min <= max(t2_min1, t2_min2, t2_min3);
        t3_med_of_med <= med(t2_med1, t2_med2, t2_med3);
        t3_min_of_max <= min(t2_max1, t2_max2, t2_max3);
    end
end

//中值滤波 step3
reg [BITS-1:0] t4_medium;//synthesis keep = 1
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t4_medium <= 0;
    end
    else begin
        t4_medium <= med(t3_max_of_min, t3_med_of_med, t3_min_of_max);
    end
end

//将中值打拍对齐到坏点检测时序
reg [BITS-1:0] t5_medium;//synthesis keep = 1
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t5_medium <= 0;
    end
    else begin
        t5_medium <= t4_medium;
    end
end

//坏点检测 step1 (转有符号数)
reg signed [BITS:0] t2_p1, t2_p2, t2_p3;
reg signed [BITS:0] t2_p4, t2_p5, t2_p6;
reg signed [BITS:0] t2_p7, t2_p8, t2_p9;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t2_p1 <= 0; t2_p2 <= 0; t2_p3 <= 0;
        t2_p4 <= 0; t2_p5 <= 0; t2_p6 <= 0;
        t2_p7 <= 0; t2_p8 <= 0; t2_p9 <= 0;
    end
    else begin
        t2_p1 <= {1'b0,t1_p1}; t2_p2 <= {1'b0,t1_p2}; t2_p3 <= {1'b0,t1_p3};
        t2_p4 <= {1'b0,t1_p4}; t2_p5 <= {1'b0,t1_p5}; t2_p6 <= {1'b0,t1_p6};
        t2_p7 <= {1'b0,t1_p7}; t2_p8 <= {1'b0,t1_p8}; t2_p9 <= {1'b0,t1_p9};
    end
end

//坏点检测 step2 (计算中心像素与周围八个像素值的差)
reg [BITS:0] t3_center;
reg signed [BITS:0] t3_diff1, t3_diff2, t3_diff3, t3_diff4, t3_diff5, t3_diff6, t3_diff7, t3_diff8;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t3_center <= 0;
        t3_diff1 <= 0; t3_diff2 <= 0;
        t3_diff3 <= 0; t3_diff4 <= 0;
        t3_diff5 <= 0; t3_diff6 <= 0;
        t3_diff7 <= 0; t3_diff8 <= 0;
    end
    else begin
        t3_center <= t2_p5[BITS-1:0];
        t3_diff1 <= t2_p5 - t2_p1;
        t3_diff2 <= t2_p5 - t2_p2;
        t3_diff3 <= t2_p5 - t2_p3;
        t3_diff4 <= t2_p5 - t2_p4;
        t3_diff5 <= t2_p5 - t2_p6;
        t3_diff6 <= t2_p5 - t2_p7;
        t3_diff7 <= t2_p5 - t2_p8;
        t3_diff8 <= t2_p5 - t2_p9;
    end
end

//坏点检测 step3 (判断差值是否都为正或都为负,计算差值绝对值)
reg t4_defective_pix;
reg [BITS-1:0] t4_center;
reg [BITS-1:0] t4_diff1, t4_diff2, t4_diff3, t4_diff4, t4_diff5, t4_diff6, t4_diff7, t4_diff8;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t4_defective_pix <= 0;
        t4_center <= 0;
        t4_diff1 <= 0; t4_diff2 <= 0;
        t4_diff3 <= 0; t4_diff4 <= 0;
        t4_diff5 <= 0; t4_diff6 <= 0;
        t4_diff7 <= 0; t4_diff8 <= 0;
    end
    else begin//s表示有符号数
        t4_center <= t3_center;
        t4_defective_pix <= (8'b0000_0000 == {t3_diff1[BITS],t3_diff2[BITS],t3_diff3[BITS],t3_diff4[BITS],t3_diff5[BITS],t3_diff6[BITS],t3_diff7[BITS],t3_diff8[BITS]})
                            || (8'b1111_1111 == {t3_diff1[BITS],t3_diff2[BITS],t3_diff3[BITS],t3_diff4[BITS],t3_diff5[BITS],t3_diff6[BITS],t3_diff7[BITS],t3_diff8[BITS]});
        t4_diff1 <= t3_diff1[BITS] ? 1'sd0 - t3_diff1 : t3_diff1;
        t4_diff2 <= t3_diff2[BITS] ? 1'sd0 - t3_diff2 : t3_diff2;
        t4_diff3 <= t3_diff3[BITS] ? 1'sd0 - t3_diff3 : t3_diff3;
        t4_diff4 <= t3_diff4[BITS] ? 1'sd0 - t3_diff4 : t3_diff4;
        t4_diff5 <= t3_diff5[BITS] ? 1'sd0 - t3_diff5 : t3_diff5;
        t4_diff6 <= t3_diff6[BITS] ? 1'sd0 - t3_diff6 : t3_diff6;
        t4_diff7 <= t3_diff7[BITS] ? 1'sd0 - t3_diff7 : t3_diff7;
        t4_diff8 <= t3_diff8[BITS] ? 1'sd0 - t3_diff8 : t3_diff8;
    end
end

//坏点检测 step4 (判断差值绝对值是否超出阈值)
reg t5_defective_pix;
reg [BITS-1:0] t5_center;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t5_defective_pix <= 0;
        t5_center <= 0;
    end
    else begin
        t5_center <= t4_center;
        t5_defective_pix <= t4_defective_pix && t4_diff1 > threshold && t4_diff2 > threshold && t4_diff3 > threshold && t4_diff4 > threshold && 
                                                t4_diff5 > threshold && t4_diff6 > threshold && t4_diff7 > threshold && t4_diff8 > threshold;
    end
end

//坏点检测 step5 (坏点成立输出中值滤波值, 非坏点输出原值)
reg [BITS-1:0] t6_center;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        t6_center <= 0;
    end
    else begin
        t6_center <= t5_defective_pix ? t5_medium : t5_center;
    end
end

localparam DLY_CLK = 6;
reg [DLY_CLK-1:0] out_raw_data_en_dly;
always @ (posedge clk or negedge rstn) begin
    if (!rstn) begin
        out_raw_data_en_dly <= 0;
    end
    else begin
        out_raw_data_en_dly <= {out_raw_data_en_dly[DLY_CLK-2:0], matrix_frame_clken};
    end
end

assign out_raw_data_en = out_raw_data_en_dly[DLY_CLK-1];
assign out_raw_data = t6_center;

function [BITS-1:0] min;
    input [BITS-1:0] a, b, c;
    begin
        min = (a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c);
    end
endfunction
function [BITS-1:0] med;
    input [BITS-1:0] a, b, c;
    begin
        med = (a < b) ? ((b < c) ? b : (a < c ? c : a)) : ((b > c) ? b : (a > c ? c : a));
    end
endfunction
function [BITS-1:0] max;
    input [BITS-1:0] a, b, c;
    begin
        max = (a > b) ? ((a > c) ? a : c) : ((b > c) ? b : c);
    end
endfunction

endmodule //dpc_top
