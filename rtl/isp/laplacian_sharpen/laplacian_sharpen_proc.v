// *********************************************************************
// 
// Copyright (C) 2021-20xx CrazyBird Corporation
// 
// Filename     :   laplacian_sharpen_proc.v
// Author       :   CrazyBird
// Email        :   CrazyBirdLin@qq.com
// 
// Description  :   
// 
// Modification History
// Date         By          Version         Change Description
//----------------------------------------------------------------------
// 2022/03/13   CrazyBird   1.0             Original
// 
// *********************************************************************
module laplacian_sharpen_proc
(
    input  wire                 clk             ,
    input  wire                 rst_n           ,
    
    //  Image data prepared to be processed
    input  wire                 per_img_vsync   ,       //  Prepared Image data vsync valid signal
    input  wire                 per_img_href    ,       //  Prepared Image data href vaild  signal
    input  wire                 per_img_clken   ,       //  Prepared Image data clk vaild  signal
    input  wire     [23:0]      per_img_data    ,       //  Prepared Image brightness input
    // input  wire     [7:0]       per_img_gray    ,       //  Prepared Image brightness input
    
    //  Image data has been processed
    output wire                  post_img_vsync  ,       //  processed Image data vsync valid signal
    output wire                  post_img_href   ,       //  processed Image data href vaild  signal
    output wire                  post_img_clken  ,       //  processed Image data clk vaild  signal
    output wire      [23:0]      post_img_data           //  processed Image brightness output
    // output reg      [7:0]       post_img_gray           //  processed Image brightness output
);
//----------------------------------------------------------------------
//  Generate 8Bit 3X3 Matrix
wire                            matrix_img_vsync;
wire                            matrix_img_href;
wire                            matrix_img_clken;
// wire                            matrix_top_edge_flag;
// wire                            matrix_bottom_edge_flag;
// wire                            matrix_left_edge_flag;
// wire                            matrix_right_edge_flag;
wire            [7:0]           matrix_p11;
wire            [7:0]           matrix_p12;
wire            [7:0]           matrix_p13;
wire            [7:0]           matrix_p21;
wire            [7:0]           matrix_p22;
wire            [7:0]           matrix_p23;
wire            [7:0]           matrix_p31; 
wire            [7:0]           matrix_p32;
wire            [7:0]           matrix_p33;

wire            [7:0]           per_img_gray;
assign  per_img_gray =  per_img_data[23:16];

wire             [7:0]          post_img_gray;



//3x3矩阵
vip_matrix_generate_3x3_8bit u_vip_matrix_generate_3x3_8bit(
    .clk                 (clk),    
    .rst_n               (rst_n),
    //预处理数据
    .per_frame_vsync     (per_img_vsync             ), 
    .per_frame_href      (per_img_href              ), 
    .per_frame_clken     (per_img_clken             ), 
    .per_img_y           (per_img_gray              ),
    
    //处理后的数据
    .matrix_frame_vsync  (matrix_img_vsync),
    .matrix_frame_href   (matrix_img_href),
    .matrix_frame_clken  (matrix_img_clken),
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
//----------------------------------------------------------------------
reg             [10:0]          minute_data;
reg             [ 9:0]          minus_data;

always @(posedge clk)
begin
    minute_data <= {matrix_p22,2'b0} + matrix_p22;
    minus_data  <= matrix_p12 + matrix_p21 + matrix_p23 + matrix_p32;
end

//----------------------------------------------------------------------
reg signed      [11:0]          pixel_data1;

always @(posedge clk)
begin
    pixel_data1 <= $signed({1'b0,minute_data}) - $signed({1'b0,minus_data});
end

assign post_img_gray = (pixel_data1[11] == 1'b1) ? 8'b0 : 
                        (pixel_data1[10:8] != 3'b0) ? 8'd255 : pixel_data1[7:0];

// wire             [7:0]           pixel_data2;

// always @(posedge clk)
// begin
//     if(pixel_data1[11] == 1'b1)
//         pixel_data2 <= 8'b0;
//     else if(pixel_data1[10:8] != 3'b0)
//         pixel_data2 <= 8'd255;
//     else
//         pixel_data2 <= pixel_data1[7:0];
// end

//----------------------------------------------------------------------
//  lag 3 clocks signal sync
reg             [2:0]           matrix_img_vsync_r1;
reg             [2:0]           matrix_img_href_r1;
reg             [2:0]           matrix_img_clken_r1;
// reg             [2:0]           matrix_edge_flag_r1;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        matrix_img_vsync_r1 <= 3'b0;
        matrix_img_href_r1  <= 3'b0;
        matrix_img_clken_r1  <= 3'b0;
        // matrix_edge_flag_r1 <= 3'b0;
    end
    else
    begin
        matrix_img_vsync_r1 <= {matrix_img_vsync_r1[1:0],matrix_img_vsync};
        matrix_img_href_r1  <= {matrix_img_href_r1[1:0],matrix_img_href};
        matrix_img_clken_r1  <= {matrix_img_clken_r1[1:0],matrix_img_clken};
        // matrix_edge_flag_r1 <= {matrix_edge_flag_r1[1:0],matrix_top_edge_flag | matrix_bottom_edge_flag | matrix_left_edge_flag | matrix_right_edge_flag};
    end
end


reg             [23:0]          post_datad0;
reg             [23:0]          post_datad1;
reg             [23:0]          post_datad2;
reg             [23:0]          post_datad3;
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        post_datad0 <= 24'd0;
        post_datad1 <= 24'd0;
        post_datad2 <= 24'd0;
        post_datad3 <= 24'd0;
    end else if(per_img_clken == 1'b1)
    begin
        post_datad0 <= per_img_data;
        post_datad1 <= post_datad0;
        post_datad2 <= post_datad1;
        post_datad3 <= post_datad2;
        // post_img_data <= {post_img_gray,post_datad2[15:0]};
    end
end

assign post_img_data = {post_img_gray,post_datad3[15:0]};
assign post_img_vsync =  matrix_img_vsync_r1[1];
assign post_img_href  =  matrix_img_href_r1 [1];
assign post_img_clken =  matrix_img_clken_r1[1];
// reg             [7:0]           matrix_p22_r1       [0:2];

// always @(posedge clk)
// begin
//     matrix_p22_r1[0] <= matrix_p22;
//     matrix_p22_r1[1] <= matrix_p22_r1[0];
//     matrix_p22_r1[2] <= matrix_p22_r1[1];
// end

//----------------------------------------------------------------------
//  result output
// always @(posedge clk)
// begin
// /*     if(matrix_edge_flag_r1[2] == 1'b1)
//         post_img_gray <= matrix_p22_r1[2];
//     else */
//         post_img_gray <= pixel_data2;
// end

// always @(posedge clk or negedge rst_n)
// begin
//     if(!rst_n)
//     begin
//         post_datad0 <= 24'd0;
//         post_datad1 <= 24'd0;
//         post_datad2 <= 24'd0;
//         post_img_vsync <= 1'b0;
//         post_img_href  <= 1'b0;
//         post_img_clken  <= 1'b0;
//     end
//     else
//     begin
//         post_datad0 <= per_img_data;
//         post_datad1 <= post_datad0;
//         post_datad2 <= post_datad1;
//         post_img_vsync <= matrix_img_vsync_r1[2];
//         post_img_href  <= matrix_img_href_r1[2];
//         post_img_clken  <= matrix_img_clken_r1[2];
//         // post_img_data <= {post_img_gray,post_datad2[15:0]};
//     end
// end
endmodule