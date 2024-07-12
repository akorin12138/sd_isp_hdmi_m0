//1936*1088
module white_balenceb_top
#(
    parameter ROW_WIDTH = 1936,
    parameter COL_WIDTH = 1088
)(
    input  wire         clk,
    input  wire         rst_n,

    input  wire         per_img_clken,
    input  wire [23:0]  per_img_data,

    output wire         post_img_clken,
    output wire [23:0]  post_img_data
);
    
// outports wire
wire [38:0]  	    gain_r;
wire [38:0]  	    gain_g;
wire [38:0]  	    gain_b;
wb_gain
#(
    .IMG0_HDISP(ROW_WIDTH),
    .IMG0_VDISP(COL_WIDTH)
) u_wb_gain(
    .clk            	( clk           ),
    .rst_n           	( rst_n         ),
    .per_img_clken 	    ( per_img_clken ),
    .per_img_data    	( per_img_data  ),
    .out_gain_r     	( gain_r        ),
    .out_gain_g     	( gain_g        ),
    .out_gain_b     	( gain_b        )
);

isp_wb
#(
    .WIDTH(ROW_WIDTH),
    .HEIGHT(COL_WIDTH)
)u_isp_wb(
    .clk         	( clk           ),
    .rst_n        	( rst_n         ),
    .gain_r       	( gain_r /* 39'd4658947456 */       ),//可打两拍跨时钟域处理
    .gain_g       	( gain_g /* 39'd2643056768 */       ),//可打两拍跨时钟域处理
    .gain_b       	( gain_b /* 39'd3926827136 */       ),//可打两拍跨时钟域处理
    .per_img_clken  ( per_img_clken ),
    .per_img_data   ( per_img_data  ),
    .post_img_clken ( post_img_clken),
    .post_img_data 	( post_img_data )
);

endmodule //wb_top

