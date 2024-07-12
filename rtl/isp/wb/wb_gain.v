//用作直方图统计
module wb_gain #(
    parameter IMG0_HDISP = 11'd1936,
    parameter IMG0_VDISP = 11'd1088
)(
    input           clk           ,
    input           rst_n          ,
    
    input           per_img_clken ,
    input   [23:0]  per_img_data  ,
    
    output  [38:0]  out_gain_r    ,
    output  [38:0]  out_gain_g    ,
    output  [38:0]  out_gain_b    
      
);

// parameter ImageSize = 32'h00001b4e;//1/(640*480) 1/ImageSize = 0.00000325520833，1位整数位，31位小数位0.000_0000_0000_0000_0001_1011_0100_1110
parameter ImageSize =  32'h403; //1936*1088 1位整数位，31位小数位
// parameter ImageSize =  32'h40B; //1920*1080 1位整数位，31位小数位

parameter IMG1_HDISP = 11'd1920;
parameter IMG1_VDISP = 11'd1080;
parameter IMG_HB = 8;
parameter IMG_VB = 4;
parameter IMG_HBL = 1928;
parameter IMG_VBL = 1084;

wire testwire;

wire [7:0] post0_img_R;
wire [7:0] post0_img_G;
wire [7:0] post0_img_B;

reg [31:0]  AccR;
reg [31:0]  AccG;
reg [31:0]  AccB;
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;
reg [32:0]  pix_cnt;
wire        pic_finish;
reg         pic_finish_d0;
reg         pic_finish_d1;
wire        pic_valid;
reg         pic_valid_dly;
wire        pic_valid_negflag;
reg         pic_valid_negflag_dly;

reg [63:0]  AverageR_temp;
reg [63:0]  AverageG_temp;
reg [63:0]  AverageB_temp;

wire[31:0]  AverageR_recip;
wire[31:0]  AverageG_recip;
wire[31:0]  AverageB_recip;

reg[38:0] Rgain;
reg[38:0] Ggain;
reg[38:0] Bgain;
//
assign  post0_img_R = {per_img_data[23:16]};
assign  post0_img_G = {per_img_data[15:8]};
assign  post0_img_B = {per_img_data[7:0]};

assign testwire = per_img_clken;

//h_cnt:行同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(per_img_clken == 1'b1)
        if(h_cnt == IMG0_HDISP - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场同步信号计数器
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(per_img_clken == 1'b1)
        if((v_cnt == IMG0_VDISP - 1'd1) &&  (h_cnt == IMG0_HDISP-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == IMG0_HDISP - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

wire pic_end;
wire pic_end1;
assign pic_finish = ((v_cnt == IMG0_VDISP - 1'd1) &&  (h_cnt == IMG0_HDISP-1'd1)) ? 1'b1 : 1'b0;
always@(posedge clk) begin
    pic_finish_d0 <= pic_finish; //延迟一个时钟，此时位于下一帧第一个像素点
    pic_finish_d1 <= pic_finish_d0;
end

//取像素区域1920*1080
assign pic_valid = (h_cnt >= IMG_HB) && (h_cnt < IMG_HBL) && (v_cnt >= IMG_VB) && (v_cnt < IMG_VBL);
assign pic_end =( pic_finish & (~pic_finish_d0));
assign pic_end1 = (pic_finish_d0 & (~pic_finish_d1));
//----------------------------------------
//      CLORK 0  RGB三通道像素值累加
//----------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AccR <= 32'd0;
        AccG <= 32'd0;
        AccB <= 32'd0;
        pix_cnt <= 'b0;
    end
    else if(pic_end)begin
        // AccR <= 'b0 ;
        // AccG <= 'b0 ;
        // AccB <= 'b0 ;
        AccR <= post0_img_R;
        AccG <= post0_img_G;
        AccB <= post0_img_B;
        pix_cnt <= 'b1;
    end
    else if(/* (pic_valid)&& */(per_img_clken)) begin
        AccR <= (AccR + post0_img_R);
        AccG <= (AccG + post0_img_G);
        AccB <= (AccB + post0_img_B);
        pix_cnt <= pix_cnt + 'b1;
    end
    else begin
        AccR <= AccR;
        AccG <= AccG;
        AccB <= AccB;
        pix_cnt <= pix_cnt;
    end
    
end

//----------------------------------------
//      CLORK 1  RGB三通道像素值取平均
//----------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        AverageR_temp <= 'd0;
        AverageG_temp <= 'd0;
        AverageB_temp <= 'd0;
    end
    else if(pic_end == 1) begin
        AverageR_temp <= (AccR * ImageSize);           
        AverageG_temp <= (AccG * ImageSize);
        AverageB_temp <= (AccB * ImageSize);
    end
    else  begin
        AverageR_temp <= AverageR_temp;           
        AverageG_temp <= AverageG_temp;
        AverageB_temp <= AverageB_temp;
    end
end

//获取每个通道的倒数
Reciprocal Reciprocal_R(
    .Average(AverageR_temp[38:31]), //截取8位整数位
    .Recip(AverageR_recip)
);

Reciprocal Reciprocal_G(
    .Average(AverageG_temp[38:31]),//截取8位整数位
    .Recip(AverageG_recip)
);

Reciprocal Reciprocal_B(
    .Average(AverageB_temp[38:31]),//截取8位整数位
    .Recip(AverageB_recip)
);

//----------------------------------------
//      CLORK 2  
//----------------------------------------
always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        Rgain <= 'd0;
        Ggain <= 'd0;
        Bgain <= 'd0;
    end
    else  if(pic_end1 == 1) begin
        Rgain <= {AverageR_recip,7'd0};       //左移7位，相当于乘以128
        Ggain <= {AverageG_recip,7'd0};
        Bgain <= {AverageB_recip,7'd0};
    end
    else begin
        Rgain <= Rgain;
        Ggain <= Ggain;
        Bgain <= Bgain;
    end
end

assign out_gain_r = Rgain;
assign out_gain_g = Ggain;
assign out_gain_b = Bgain;
endmodule //wb_inst

