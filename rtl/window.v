/*
用于RGB的值在存入SDRAM前
*/
module window #(
    parameter WIN_X = 11'd500,      //窗口x坐标,应小于WIDTH-HDMI_HPIXEL
    parameter WIN_Y = 11'd500,      //窗口y坐标,应小于HEIGHT-HDMI_VPIXEL
    parameter WIDTH = 1936,         //原图分辨率
    parameter HEIGHT = 1088,        //原图分辨率
    parameter HDMI_HPIXEL = 11'd640,//显示器分辨率
    parameter HDMI_VPIXEL = 11'd480 //显示器分辨率
)(
    input  wire         clk,
    input  wire         rstn,
    input  wire         win_data_en,
    input  wire [23:0]  win_data,
    output wire         sdram_data_en,
    output wire [15:0]  sdram_data
);
//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(win_data_en == 1'b1)
        if(h_cnt == WIDTH - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(win_data_en == 1'b1)
        if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == WIDTH - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

wire windows_en = (h_cnt <= HDMI_HPIXEL-1 + WIN_X) && (v_cnt <= HDMI_VPIXEL-1 + WIN_Y) && 
    (h_cnt >= WIN_X) && (v_cnt >= WIN_Y) && 
    (win_data_en == 1'b1) ? 1'b1 : 1'b0;

assign sdram_data_en = windows_en;
assign sdram_data = {win_data[23:19],win_data[15:10],win_data[7:3]};

endmodule //window

