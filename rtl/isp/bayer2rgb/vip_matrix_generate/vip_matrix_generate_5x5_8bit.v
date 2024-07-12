module  vip_matrix_generate_5x5_8bit
(
    input             clk,  
    input             rst_n,

    input             per_frame_vsync,
    input             per_frame_href,
    input             per_frame_clken,
    input      [7:0]  per_img_y,
    
    output            matrix_frame_vsync,
    output            matrix_frame_href,
    output            matrix_frame_clken,
    output reg [7:0]  matrix_p11,
    output reg [7:0]  matrix_p12, 
    output reg [7:0]  matrix_p13,
    output reg [7:0]  matrix_p14, 
    output reg [7:0]  matrix_p15, 
    output reg [7:0]  matrix_p21,
    output reg [7:0]  matrix_p22, 
    output reg [7:0]  matrix_p23, 
    output reg [7:0]  matrix_p24,
    output reg [7:0]  matrix_p25,
    output reg [7:0]  matrix_p31,
    output reg [7:0]  matrix_p32,
    output reg [7:0]  matrix_p33,
    output reg [7:0]  matrix_p34,
    output reg [7:0]  matrix_p35,
    output reg [7:0]  matrix_p41,
    output reg [7:0]  matrix_p42,
    output reg [7:0]  matrix_p43,
    output reg [7:0]  matrix_p44,
    output reg [7:0]  matrix_p45,
    output reg [7:0]  matrix_p51,
    output reg [7:0]  matrix_p52,
    output reg [7:0]  matrix_p53,
    output reg [7:0]  matrix_p54,
    output reg [7:0]  matrix_p55
    
);

//wire define
wire    [7:0]   row1_data;
wire    [7:0]   row2_data;
wire    [7:0]   row3_data;
wire    [7:0]   row4_data;
wire            read_frame_href;
wire            read_frame_clken;

//reg define
reg     [7:0]   row5_data;
reg     [3:0]   per_frame_vsync_r;
reg     [3:0]   per_frame_href_r;
reg     [3:0]   per_frame_clken_r;

//*****************************************************
//**                    main code
//*****************************************************

reg     [7:0]   per_img_y_0;
reg     [7:0]   per_img_y_1;

//当前数据放在第5行 延迟3个时钟
always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            begin
                row5_data <= 8'd0;
                per_img_y_0 <= 8'd0;
                per_img_y_1 <= 8'd0;
            end
        else
            begin
                row5_data <= per_img_y_1;
                per_img_y_1 <= per_img_y_0;
                per_img_y_0 <= per_img_y;
            end
    end

//用于存储列数据的RAM
line_shift_ram_8bit_5x5  u_line_shift_ram_8bit_5x5
(
    .clock          (clk),
    .rst_n          (rst_n),
    .clken          (per_frame_clken),
    .per_frame_href (per_frame_href),
    
    .shiftin        (per_img_y),
    .post_clken     (read_frame_clken),
    .taps0x         (row4_data),
    .taps1x         (row3_data),
    .taps2x         (row2_data),
    .taps3x         (row1_data)
);

//将同步信号延迟两拍，用于同步化处理
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        per_frame_vsync_r <= 0;
        per_frame_href_r  <= 0;
        per_frame_clken_r <= 0;
    end
    else begin
        per_frame_vsync_r <= { per_frame_vsync_r[2:0], per_frame_vsync};
        per_frame_href_r  <= { per_frame_href_r[2:0],  per_frame_href};
        per_frame_clken_r <= { per_frame_clken_r[2:0], per_frame_clken};
    end
end

/* assign read_frame_href    = per_frame_href_r[0];
assign read_frame_clken   = per_frame_clken_r[0]; */

//在同步处理后的控制信号下，输出图像矩阵
always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        {matrix_p11, matrix_p12, matrix_p13, matrix_p14, matrix_p15} <= 24'h0;
        {matrix_p21, matrix_p22, matrix_p23, matrix_p24, matrix_p25} <= 24'h0;
        {matrix_p31, matrix_p32, matrix_p33, matrix_p34, matrix_p35} <= 24'h0;
        {matrix_p41, matrix_p42, matrix_p43, matrix_p44, matrix_p45} <= 24'h0;
        {matrix_p51, matrix_p52, matrix_p53, matrix_p54, matrix_p55} <= 24'h0;
    end
    else if(read_frame_clken) begin
        {matrix_p11, matrix_p12, matrix_p13, matrix_p14, matrix_p15} <= {matrix_p12, matrix_p13, matrix_p14, matrix_p15,row1_data};
        {matrix_p21, matrix_p22, matrix_p23, matrix_p24, matrix_p25} <= {matrix_p22, matrix_p23, matrix_p24, matrix_p25,row2_data};
        {matrix_p31, matrix_p32, matrix_p33, matrix_p34, matrix_p35} <= {matrix_p32, matrix_p33, matrix_p34, matrix_p35,row3_data};
        {matrix_p41, matrix_p42, matrix_p43, matrix_p44, matrix_p45} <= {matrix_p42, matrix_p43, matrix_p44, matrix_p45,row4_data};
        {matrix_p51, matrix_p52, matrix_p53, matrix_p54, matrix_p55} <= {matrix_p52, matrix_p53, matrix_p54, matrix_p55,row5_data};
    end
    else begin
        {matrix_p11, matrix_p12, matrix_p13, matrix_p14, matrix_p15} <= {matrix_p11, matrix_p12, matrix_p13, matrix_p14, matrix_p15};
        {matrix_p21, matrix_p22, matrix_p23, matrix_p24, matrix_p25} <= {matrix_p21, matrix_p22, matrix_p23, matrix_p24, matrix_p25};
        {matrix_p31, matrix_p32, matrix_p33, matrix_p34, matrix_p35} <= {matrix_p31, matrix_p32, matrix_p33, matrix_p34, matrix_p35};
        {matrix_p41, matrix_p42, matrix_p43, matrix_p44, matrix_p45} <= {matrix_p41, matrix_p42, matrix_p43, matrix_p44, matrix_p45};
        {matrix_p51, matrix_p52, matrix_p53, matrix_p54, matrix_p55} <= {matrix_p51, matrix_p52, matrix_p53, matrix_p54, matrix_p55};
    end
end

assign matrix_frame_vsync = per_frame_vsync_r[2];
assign matrix_frame_href  = per_frame_href_r [2];
assign matrix_frame_clken = per_frame_clken_r[2];

endmodule 