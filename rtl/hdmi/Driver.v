`timescale 1ns/1ns
module Driver
#(
//1024*768分辨率
    // parameter   H_SYNC  = 136,      // 行同步信号时间
    // parameter   H_BACK  = 160,      // 行消隐后肩时间
    // parameter   H_DISP  = 1024,     // 行数据有效时间
    // parameter   H_FRONT = 24,       // 行消隐前肩时间
    // parameter   H_TOTAL = 1344,     // 行扫描总时间

    // parameter   V_SYNC  = 6,        // 列同步信号时间
    // parameter   V_BACK  = 29,       // 列消隐后肩时间
    // parameter   V_DISP  = 768,      // 列数据有效时间
    // parameter   V_FRONT = 3,        // 列消隐前肩时间
    // parameter   V_TOTAL = 806,      // 列扫描总时间

    //1920*1080分辨率
    parameter   H_SYNC  = 44,      // 行同步信号时间
    parameter   H_BACK  = 148,      // 行消隐后肩时间
    parameter   H_DISP  = 1920,     // 行数据有效时间
    parameter   H_FRONT = 88,       // 行消隐前肩时间
    parameter   H_TOTAL = 2200,     // 行扫描总时间

    parameter   V_SYNC  = 5,        // 列同步信号时间
    parameter   V_BACK  = 36,       // 列消隐后肩时间
    parameter   V_DISP  = 1080,      // 列数据有效时间
    parameter   V_FRONT = 4,        // 列消隐前肩时间
    parameter   V_TOTAL = 1125,      // 列扫描总时间

    parameter   IMG_W   = 1024,      //摄像头分辨率
    parameter   IMG_H   = 640,
    parameter   IMG_X   = 0,
    parameter   IMG_Y   = 128,
    
    parameter   IMG_W2   = 1024,      //摄像头分辨率
    parameter   IMG_H2   = 640,
    parameter   IMG_X2   = 0,
    parameter   IMG_Y2   = 128
)
(
    input   wire            clk,            //VGA clock
    input   wire            rst_n,          //sync reset
    input   wire    [15:0]  lcd_data,       //lcd data

    //lcd interface
    output  wire            lcd_dclk,       //lcd pixel clock
    output  wire            lcd_hs,         //lcd horizontal sync
    output  wire            lcd_vs,         //lcd vertical sync
    output  wire    [23:0]  lcd_rgb,        //lcd display data
    output  wire            lcd_en,
    output  wire            lcd_request,

    //user interface
    output  wire    [10:0]  lcd_xpos,       //lcd horizontal coordinate
    output  wire    [10:0]  lcd_ypos,       //lcd vertical coordinate
    output  reg     [11:0]  hcnt,
    output  reg     [11:0]  vcnt,

    output  wire            first_ack,
    output  wire            second_ack
);

localparam  H_AHEAD =   2'd0;
localparam  THB     =   H_SYNC + H_BACK;
localparam  TH      =   H_SYNC + H_BACK + H_DISP;
localparam  TVB     =   V_SYNC + V_BACK;
localparam  TV      =   V_SYNC + V_BACK + V_DISP;

/*******************************************
		SYNC--BACK--DISP--FRONT
*******************************************/
always @ (posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
        hcnt <= 12'd0;
    else
    begin
        if(hcnt < H_TOTAL - 1'b1)   //line over
            hcnt <= hcnt + 1'b1;
        else
            hcnt <= 12'd0;
    end
end 

assign  lcd_hs = (hcnt <= H_SYNC - 1'b1) ? 1'b1 : 1'b0; // line over flag

//v_sync counter & generator
always@(posedge clk or negedge rst_n)
begin
    if (rst_n == 1'b0)
        vcnt <= 12'b0;
    else if(hcnt == H_TOTAL - 1'b1)	//line over
        begin
        if(vcnt == V_TOTAL - 1'b1)		//frame over
            vcnt <= 12'd0;
        else
            vcnt <= vcnt + 1'b1;
        end
end

assign  lcd_vs = (vcnt <= V_SYNC - 1'b1) ? 1'b1 : 1'b0; // frame over flag

// LED clock
assign  lcd_dclk = ~clk;

// Control Display
assign  lcd_en = (hcnt >= H_SYNC + H_BACK  && hcnt < H_SYNC + H_BACK + H_DISP) &&
                        (vcnt >= V_SYNC + V_BACK  && vcnt < V_SYNC + V_BACK + V_DISP)
                        ? 1'b1 : 1'b0;                   // Display Enable Signal

assign  lcd_rgb = lcd_en ? {lcd_data[15:11],lcd_data[15:13],lcd_data[10:5],lcd_data[10:9],lcd_data[4:0],lcd_data[4:2]} : 24'h000000;

assign  lcd_request = (hcnt >= H_SYNC + H_BACK - H_AHEAD && hcnt < H_SYNC + H_BACK + H_DISP - H_AHEAD) &&
                        (vcnt >= V_SYNC + V_BACK && vcnt < V_SYNC + V_BACK + V_DISP) 
                        ? 1'b1 : 1'b0;

assign first_ack = ((hcnt - (THB - H_AHEAD)) >= IMG_X && (hcnt - (THB - H_AHEAD)) < (IMG_X + IMG_W)) &&
                 ((vcnt - TVB) >= IMG_Y && (vcnt - TVB) < (IMG_Y + IMG_H)) ? 1'b1 : 1'b0;

assign second_ack = ((hcnt - (THB - H_AHEAD)) >= IMG_X2 && (hcnt - (THB - H_AHEAD)) < (IMG_X2 + IMG_W2)) &&
                 ((vcnt - TVB) >= IMG_Y2 && (vcnt - TVB) < (IMG_Y2 + IMG_H2)) ? 1'b1 : 1'b0;

//lcd xpos & ypos
assign  lcd_xpos = lcd_request ? (hcnt - (H_SYNC + H_BACK - H_AHEAD)) : 12'd0;
assign  lcd_ypos = lcd_request ? (vcnt - (V_SYNC + V_BACK)) : 12'd0;

endmodule
