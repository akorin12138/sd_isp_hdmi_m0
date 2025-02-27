module bayer2rgb #(
    parameter WIN_X = 11'd500,      //窗口x坐标
    parameter WIN_Y = 11'd500,      //窗口y坐标
    parameter HDMI_HPIXEL = 11'd640,
    parameter HDMI_VPIXEL = 11'd480,
    parameter RAW_HPIXEL = 11'd1936,
    parameter RAW_VPIXEL = 11'd1088
)(
    input  wire clk,
    input  wire rstn,

    input  wire         in_href,
    input  wire [7:0]  in_raw,

    output wire         out_href,
    output wire [23:0]  out_rgb //synthesis keep = 1
);
// parameter RAW_HPIXEL = 11'd1920;
// parameter RAW_VPIXEL = 11'd1080;
//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

// outports wire
wire        	matrix_frame_vsync;
wire        	matrix_frame_href;
wire        	matrix_frame_clken;
wire [15:0]matrix_p11;
wire [15:0]matrix_p12;
wire [15:0]matrix_p13;
wire [15:0]matrix_p21;
wire [15:0]matrix_p22;
wire [15:0]matrix_p23;
wire [15:0]matrix_p31;
wire [15:0]matrix_p32;
wire [15:0]matrix_p33;
//bayer2rgb算法
reg  [7:0]   RGB_R;
reg  [7:0]   RGB_G;
reg  [7:0]   RGB_B;
reg matrix_frame_clken_r;
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

vip_matrix_generate_3x3_8bit u_vip_matrix_generate_3x3_8bit(
    .clk                	( clk                       ),
    .rst_n              	( rstn                      ),
    .per_frame_vsync    	( 1'b1                      ),
    .per_frame_href     	( 1'b1                      ),
    .per_frame_clken    	( in_href          ),
    .per_img_y          	( in_raw                ),
    .matrix_frame_vsync 	( matrix_frame_vsync        ),
    .matrix_frame_href  	( matrix_frame_href         ),
    .matrix_frame_clken 	( matrix_frame_clken        ),
    .matrix_p11( matrix_p11          ),.matrix_p12( matrix_p12          ),.matrix_p13( matrix_p13          ),
    .matrix_p21( matrix_p21          ),.matrix_p22( matrix_p22          ),.matrix_p23( matrix_p23          ),
    .matrix_p31( matrix_p31          ),.matrix_p32( matrix_p32          ),.matrix_p33( matrix_p33          )
);

always @(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)begin
        RGB_R <= 8'd0;
        RGB_G <= 8'd0;
        RGB_B <= 8'd0;
    end
    else if(matrix_frame_clken == 1'b1)
        case ({v_cnt[0],h_cnt[0]})
            2'b00:begin
                RGB_R <= (matrix_p12 + matrix_p32)>>1;
                RGB_G <= matrix_p22;
                RGB_B <= (matrix_p21 + matrix_p23)>>1;
            end
            2'b01:begin
                RGB_R <= (matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
                RGB_G <= (matrix_p21 + matrix_p23 + matrix_p12 + matrix_p32)>>2;
                RGB_B <= matrix_p22;
            end
            2'b10:begin
                RGB_R <= matrix_p22;
                RGB_G <= (matrix_p21 + matrix_p23 + matrix_p12 + matrix_p32)>>2;
                RGB_B <= (matrix_p11 + matrix_p13 + matrix_p31 + matrix_p33)>>2;
            end
            2'b11:begin
                RGB_R <= (matrix_p21 + matrix_p23)>>1;
                RGB_G <= matrix_p22;
                RGB_B <= (matrix_p12 + matrix_p32)>>1;
            end
            default: begin
                RGB_R <= 8'd0;
                RGB_G <= 8'd0;
                RGB_B <= 8'd0;
            end
        endcase
end
wire windows_en = (h_cnt <= HDMI_HPIXEL-1 + WIN_X) && (v_cnt <= HDMI_VPIXEL-1 + WIN_Y) && 
    (h_cnt >= WIN_X) && (v_cnt >= WIN_Y) && 
    (matrix_frame_clken == 1'b1) ? 1'b1 : 1'b0;

always@(posedge clk or negedge rstn) begin
    if(rstn == 1'b0)begin
        matrix_frame_clken_r <= 1'b0;
    end
    else
        matrix_frame_clken_r <= matrix_frame_clken;
end
//取640x480窗
assign out_href = matrix_frame_clken_r;
// assign out_href = windows_en ;
assign out_rgb = {RGB_R,RGB_G,RGB_B};
// assign out_rgb = in_raw;

endmodule //bayer2rgb

