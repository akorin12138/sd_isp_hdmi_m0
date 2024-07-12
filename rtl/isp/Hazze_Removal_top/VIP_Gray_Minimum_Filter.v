//基于暗通道先验的图像去雾

//VIP 算法--最小值滤波，消耗四个时钟周期
module VIP_Gray_Minimum_Filter #(
    parameter   [10:0]   IMG_HDISP = 11'd1024 ,
    parameter   [10:0]   IMG_VDISP = 11'd768
)
(
    //global clk
    input           clk,
    input           rst_n,
    
    //Image data prepared to be processed
    input               per_frame_vsync ,
    input               per_frame_href  ,
    input               per_frame_clken ,
    input       [7:0]   per_img_Y       ,
    
    //Image data has been processed
    output              post_frame_vsync,
    output              post_frame_href ,
    output              post_frame_clken,
    output      [7:0]   post_img_Y
);
wire        matrix_frame_vsync;
wire        matrix_frame_href ;
wire        matrix_frame_clken;
wire [7:0]  matrix_p11  ;
wire [7:0]  matrix_p12  ;
wire [7:0]  matrix_p13  ;
wire [7:0]  matrix_p21  ;
wire [7:0]  matrix_p22  ;
wire [7:0]  matrix_p23  ;
wire [7:0]  matrix_p31  ;
wire [7:0]  matrix_p32  ;
wire [7:0]  matrix_p33  ;
reg  [1:0]  post0_frame_vsync ;
reg  [1:0]  post0_frame_href ;
reg  [1:0]  post0_frame_clken;
reg  [7:0]  post0_img_Y      ;
reg  [7:0]  post_img_Y3     ;
reg  [7:0]  post_img_Y1     ;
reg  [7:0]  post_img_Y2     ;

//3x3矩阵
vip_matrix_generate_3x3_8bit u_vip_matrix_generate_3x3_8bit(
    .clk                 (clk),    
    .rst_n               (rst_n),
    //预处理数据
    .per_frame_vsync     (per_frame_vsync),
    .per_frame_href      (per_frame_href),
    .per_frame_clken     (per_frame_clken),
    .per_img_y           (per_img_Y),
    
    //处理后的数据
    .matrix_frame_vsync  (matrix_frame_vsync),
    .matrix_frame_href   (matrix_frame_href),
    .matrix_frame_clken  (matrix_frame_clken),
    .matrix_p11          (matrix_p11),
    .matrix_p12          (matrix_p12),
    .matrix_p13          (matrix_p13),//输出 3X3 矩阵
    .matrix_p21          (matrix_p21),
    .matrix_p22          (matrix_p22),
    .matrix_p23          (matrix_p23),
    .matrix_p31          (matrix_p31),
    .matrix_p32          (matrix_p32),
    .matrix_p33          (matrix_p33)
);
//比较3x3矩阵每行最小值
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        post_img_Y1 <= 8'b0;
    else    if((matrix_p11 <= matrix_p12) && (matrix_p11 <= matrix_p13))
        post_img_Y1 <= matrix_p11;
    else    if((matrix_p12 <= matrix_p11) && (matrix_p12 <= matrix_p13))
        post_img_Y1 <= matrix_p12;
    else   
        post_img_Y1 <= matrix_p13; 

always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        post_img_Y2 <= 8'b0;
    else    if((matrix_p21 <= matrix_p22) && (matrix_p21 <= matrix_p23))
        post_img_Y2 <= matrix_p21;
    else    if((matrix_p22 <= matrix_p21) && (matrix_p22 <= matrix_p23))
        post_img_Y2 <= matrix_p22;
    else   
        post_img_Y2 <= matrix_p23; 
        
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        post_img_Y3 <= 8'b0;
    else    if((matrix_p31 <= matrix_p32) && (matrix_p31 <= matrix_p33))
        post_img_Y3 <= matrix_p31;
    else    if((matrix_p32 <= matrix_p31) && (matrix_p32 <= matrix_p33))
        post_img_Y3 <= matrix_p32;
    else   
        post_img_Y3 <= matrix_p33; 

//比较3x3矩阵最小值
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        post0_img_Y <= 8'b0;
    else    if((post_img_Y1 <= post_img_Y2) && (post_img_Y1 <= post_img_Y3))
        post0_img_Y <= post_img_Y1;
    else    if((post_img_Y2 <= post_img_Y1) && (post_img_Y2 <= post_img_Y3))
        post0_img_Y <= post_img_Y2;
    else   
        post0_img_Y <= post_img_Y3;   

//延迟两个拍
always@(posedge clk) begin
    post0_frame_vsync <= {post0_frame_vsync[0],matrix_frame_vsync};
    post0_frame_href  <= {post0_frame_href[0],matrix_frame_href};
    post0_frame_clken <= {post0_frame_clken[0],matrix_frame_clken};

end

//------------------------------
assign post_img_Y       = post0_img_Y;
assign post_frame_vsync = post0_frame_vsync[1];
assign post_frame_href  = post0_frame_href[1];  
assign post_frame_clken = post0_frame_clken[1]; 
       
endmodule