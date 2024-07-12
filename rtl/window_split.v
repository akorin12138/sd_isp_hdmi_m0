/*
用于RGB的值在存入SDRAM前
*/
module window_split  #(
    parameter WIN_X = 11'd500,      //窗口x坐标,应小于WIDTH-HDMI_HPIXEL
    parameter WIN_Y = 11'd500,      //窗口y坐标,应小于HEIGHT-HDMI_VPIXEL
    parameter WIDTH = 1936,         //原图分辨率
    parameter HEIGHT = 1088,        //原图分辨率
    parameter HDMI_HPIXEL = 11'd640,//显示器分辨率
    parameter HDMI_VPIXEL = 11'd480 //显示器分辨率
    // parameter SPLIT_WIN_X = 0,      //分屏模式时的显示起始坐标
    // parameter SPLIT_WIN_Y = 0       //分屏模式时的显示起始坐标
)(
    input  wire         clk,
    input  wire         rstn,
    input  wire         win_data_en0,       //分屏左侧输入数据有效信号
    input  wire         win_data_en1,       //分屏右侧输入数据有效信号
    input  wire         split_en,

    input  wire [10:0]  split_x,
    input  wire [10:0]  split_y,
    input  wire [23:0]  win_data0,
    input  wire [23:0]  win_data1,
    output wire         sdram_data_en,
    output wire [15:0]  sdram_data
);
//输入的一帧图76像大小为1936x1088
reg [10:0]  h_cnt0;
reg [10:0]  v_cnt0;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt0   <=  12'd0   ;
    else if(win_data_en0 == 1'b1)
        if(h_cnt0 == WIDTH - 1'd1)
            h_cnt0   <=  12'd0   ;
        else
            h_cnt0   <=  h_cnt0 + 1'd1   ;
    else
        h_cnt0 <= h_cnt0;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt0   <=  12'd0 ;
    else    if(win_data_en0 == 1'b1)
        if((v_cnt0 == HEIGHT - 1'd1) &&  (h_cnt0 == WIDTH-1'd1))
            v_cnt0   <=  12'd0 ;
        else    if(h_cnt0 == WIDTH - 1'd1)
            v_cnt0   <=  v_cnt0 + 1'd1 ;
        else
            v_cnt0   <=  v_cnt0 ;
    else
        v_cnt0   <=  v_cnt0 ;

//输入的一帧图像大小为1936x1088
reg [10:0]  h_cnt1;
reg [10:0]  v_cnt1;
reg         split_en_r;
//h_cnt:行同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt1   <=  12'd0   ;
    else if(win_data_en1 == 1'b1)
        if(h_cnt1 == WIDTH - 1'd1)
            h_cnt1   <=  12'd0   ;
        else
            h_cnt1   <=  h_cnt1 + 1'd1   ;
    else
        h_cnt1 <= h_cnt1;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt1   <=  12'd0 ;
    else    if(win_data_en1 == 1'b1)
        if((v_cnt1 == HEIGHT - 1'd1) &&  (h_cnt1 == WIDTH-1'd1))
            v_cnt1   <=  12'd0 ;
        else    if(h_cnt1 == WIDTH - 1'd1)
            v_cnt1   <=  v_cnt1 + 1'd1 ;
        else
            v_cnt1   <=  v_cnt1 ;
    else
        v_cnt1   <=  v_cnt1 ;

reg [10:0] SPLIT_WIN_X;
reg [10:0] SPLIT_WIN_Y;

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        split_en_r <= 1'b0;
    else if((h_cnt1 >= HDMI_HPIXEL-1 + WIN_X) && (v_cnt1 >= HDMI_VPIXEL-1 + WIN_Y))
        split_en_r <= split_en;
    else
        split_en_r <= split_en_r;
end


always @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        SPLIT_WIN_X <= 11'd0;
        SPLIT_WIN_Y <= 11'd0;
    end
    else if(split_en_r)begin
        SPLIT_WIN_X <= split_x;
        SPLIT_WIN_Y <= split_y;
    end
    else begin
        SPLIT_WIN_X <= WIN_X;
        SPLIT_WIN_Y <= WIN_Y;
    end
end

wire windows_en = (h_cnt0 <= HDMI_HPIXEL-1 + WIN_X) && (v_cnt0 <= HDMI_VPIXEL-1 + WIN_Y) && 
    (h_cnt0 >= WIN_X) && (v_cnt0 >= WIN_Y) && 
    (win_data_en0 == 1'b1) ? 1'b1 : 1'b0;

//预计用4个softfifo 完成分屏任务
wire split_window0_en = (h_cnt0 <= HDMI_HPIXEL/2-1 + SPLIT_WIN_X) && (v_cnt0 <= HDMI_VPIXEL-1 + SPLIT_WIN_Y) && 
    (h_cnt0 >= SPLIT_WIN_X) && (v_cnt0 >= SPLIT_WIN_Y) && 
    (win_data_en0 == 1'b1) ? 1'b1 : 1'b0;
//剩余部分
wire split_window0_en_R = ~split_window0_en & windows_en;


wire split_window1_en = (h_cnt1 <= HDMI_HPIXEL/2-1 + SPLIT_WIN_X) && (v_cnt1 <= HDMI_VPIXEL-1 + SPLIT_WIN_Y) && 
    (h_cnt1 >= SPLIT_WIN_X) && (v_cnt1 >= SPLIT_WIN_Y) && 
    (win_data_en1 == 1'b1) ? 1'b1 : 1'b0;



wire fifoL0_empty,fifoL1_empty;
wire fifoR0_empty,fifoR1_empty;


//w\reL\R0:单数行，w\reL\R1:双数行
wire weL0,weL1;
wire weR0,weR1;

wire reL0,reL1;
wire reR0,reR1;

wire [23:0] doutL0,doutL1;
wire [23:0] doutR0,doutR1;

wire [9:0] fifouseL0;
wire [9:0] fifouseR0;
wire [9:0] fifouseL1;
wire [9:0] fifouseR1;

reg  fifouseL0_r;
reg  fifouseR0_r;
reg  fifouseL1_r;
reg  fifouseR1_r;

assign weL0 = split_window0_en & ~v_cnt0[0]  ;
assign weL1 = split_window0_en & v_cnt0[0]  ;
assign weR0 = split_en_r ? split_window1_en & ~v_cnt1[0] : split_window0_en_R & ~v_cnt0[0];
assign weR1 = split_en_r ? split_window1_en & v_cnt1[0]  : split_window0_en_R &  v_cnt0[0] ;

assign reL0 = ~weL0 & ~fifoL0_empty & fifouseL0_r;
assign reL1 = ~weL1 & ~fifoL1_empty & fifouseL1_r;
assign reR0 = ~weR0 & ~fifoR0_empty & fifoL0_empty & fifouseR0_r; //左fifo读完才轮到右fifo读
assign reR1 = ~weR1 & ~fifoR1_empty & fifoL1_empty & fifouseR1_r;

//确保已经保存了行像素一半的数据
always @(posedge clk or negedge rstn)
    if(~rstn)
        fifouseL0_r <= 1'd0;
    else if (fifouseL0 == HDMI_HPIXEL/2)
        fifouseL0_r <= 1'b1;
    else if (fifouseL0 == 10'd0)
        fifouseL0_r <= 1'b0;
    else
        fifouseL0_r <= fifouseL0_r;
always @(posedge clk or negedge rstn)
    if(~rstn)
        fifouseR0_r <= 1'd0;
    else if (fifouseR0 == HDMI_HPIXEL/2)
        fifouseR0_r <= 1'b1;
    else if (fifouseR0 == 10'd0)
        fifouseR0_r <= 1'b0;
    else
        fifouseR0_r <= fifouseR0_r;
always @(posedge clk or negedge rstn)
    if(~rstn)
        fifouseL1_r <= 1'd0;
    else if (fifouseL1 == HDMI_HPIXEL/2)
        fifouseL1_r <= 1'b1;
    else if (fifouseL1 == 10'd0)
        fifouseL1_r <= 1'b0;
    else
        fifouseL1_r <= fifouseL1_r;
always @(posedge clk or negedge rstn)
    if(~rstn)
        fifouseR1_r <= 1'd0;
    else if (fifouseR1 == HDMI_HPIXEL/2)
        fifouseR1_r <= 1'b1;
    else if (fifouseR1 == 10'd0)
        fifouseR1_r <= 1'b0;
    else
        fifouseR1_r <= fifouseR1_r;





reg [23:0] outdata;
reg        outdata_en;
reg reR1_r,reL1_r,reR0_r,reL0_r;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        reL0_r <=1'b0;
        reR0_r <=1'b0;
        reL1_r <=1'b0;
        reR1_r <=1'b0;
    end
    else begin
        reL0_r <= reL0;
        reR0_r <= reR0;
        reL1_r <= reL1;
        reR1_r <= reR1;
    end
end

always @(posedge clk ) begin
    case ({reR1_r,reL1_r,reR0_r,reL0_r})
        4'b0001:begin outdata <= doutL0;outdata_en <= reL0_r;  end
        4'b0010:begin outdata <= doutR0;outdata_en <= reR0_r;  end
        4'b0100:begin outdata <= doutL1;outdata_en <= reL1_r;  end
        4'b1000:begin outdata <= doutR1;outdata_en <= reR1_r;  end
        4'b0000:begin outdata <= 24'd0 ;outdata_en <= 1'b0  ;  end
        default:begin outdata <= 24'd0 ;outdata_en <= 1'b0  ;  end
    endcase
end

tempfifo u_tempfifoL0(
    .rst        	( ~rstn        ),
    .clkw       	( clk         ),
    .clkr       	( clk         ),
    .we         	( weL0          ),
    .di         	( win_data0         ),
    .re         	( reL0          ),
    .dout       	( doutL0        ),
    .valid      	(         ),
    .full_flag  	(    ),
    .empty_flag 	( fifoL0_empty  ),
    .afull      	(         ),
    .aempty     	(        ),
    .wrusedw    	( fifouseL0      ),
    .rdusedw    	(       )
);
tempfifo u_tempfifoL1(
    .rst        	( ~rstn         ),
    .clkw       	( clk        ),
    .clkr       	( clk        ),
    .we         	( weL1          ),
    .di         	( win_data0          ),
    .re         	( reL1          ),
    .dout       	( doutL1        ),
    .valid      	(         ),
    .full_flag  	(    ),
    .empty_flag 	( fifoL1_empty  ),
    .afull      	(         ),
    .aempty     	(        ),
    .wrusedw    	( fifouseL1      ),
    .rdusedw    	(       )
);
tempfifo u_tempfifoR0(
    .rst        	( ~rstn         ),
    .clkw       	( clk        ),
    .clkr       	( clk        ),
    .we         	( weR0          ),
    .di         	( split_en_r ? win_data1 : win_data0          ),
    .re         	( reR0          ),
    .dout       	( doutR0        ),
    .valid      	(         ),
    .full_flag  	(    ),
    .empty_flag 	( fifoR0_empty  ),
    .afull      	(         ),
    .aempty     	(        ),
    .wrusedw    	( fifouseR0      ),
    .rdusedw    	(       )
);
tempfifo u_tempfifoR1(
    .rst        	( ~rstn         ),
    .clkw       	( clk        ),
    .clkr       	( clk        ),
    .we         	( weR1         ),
    .di         	( split_en_r ? win_data1 : win_data0    ),
    .re         	( reR1          ),
    .dout       	( doutR1        ),
    .valid      	(         ),
    .full_flag  	(    ),
    .empty_flag 	( fifoR1_empty  ),
    .afull      	(         ),
    .aempty     	(        ),
    .wrusedw    	( fifouseR1      ),
    .rdusedw    	(       )
);


assign sdram_data_en = outdata_en;
assign sdram_data = {outdata[23:19],outdata[15:10],outdata[7:3]};

endmodule //window

