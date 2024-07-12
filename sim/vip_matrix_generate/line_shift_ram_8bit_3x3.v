//3x3矩阵生成模块

//延迟2个时钟周期
module line_shift_ram_8bit_3x3(
    input   wire    clock,
    input   wire    rst_n,
    input   wire    clken,
    input   wire    per_frame_href,
    
    input   wire [7:0]  shiftin,
    output  wire        post_clken,
    output  wire [7:0]  taps0x,
    output  wire [7:0]  taps1x
);
parameter   RAM_ADDR_MAX    =   1936;
//reg define
reg  [2:0]  clken_dly;
reg  [10:0]  ram_rd_addr;
reg  [10:0]  ram_rd_addr_d0;
reg  [10:0]  ram_rd_addr_d1;
reg  [10:0]  ram_rd_addr_d2;
reg  [7:0]  shiftin_d0;
reg  [7:0]  shiftin_d1;
reg  [7:0]  shiftin_d2;
reg  [7:0]  taps0x_d0;

//*****************************************************
//**                    main code
//*****************************************************

//在数据来到时，ram地址累加
always@(posedge clock or negedge rst_n)begin
    if(rst_n == 1'b0)
        ram_rd_addr <= 0 ;
    else if(clken)
        if(ram_rd_addr == RAM_ADDR_MAX - 1)
            ram_rd_addr <= 0 ;
        else
            ram_rd_addr <= ram_rd_addr + 1 ;
    else
        ram_rd_addr <= ram_rd_addr ;
        // ram_rd_addr <= 0 ;
end

//时钟使能信号延迟三拍
always@(posedge clock) begin
    clken_dly <= { clken_dly[1:0] , clken };
end

assign post_clken = clken_dly[0];

//将ram地址延迟二拍
always@(posedge clock ) begin
    ram_rd_addr_d0 <= ram_rd_addr;
    ram_rd_addr_d1 <= ram_rd_addr_d0;
    ram_rd_addr_d2 <= ram_rd_addr_d1;
    
end

//输入数据延迟三拍
always@(posedge clock)begin
    shiftin_d0 <= shiftin;
    shiftin_d1 <= shiftin_d0;
    shiftin_d2 <= shiftin_d1;
end

//用于存储前一行图像的RAM //先读后写
bram_256_8bit bram_256_8bit_inst0
( 
    .dia    (shiftin_d0),
    .addra  (ram_rd_addr_d0),
    .wea    (clken_dly[0]),
    .clk    (clock),
    .dob    (taps0x),
    .addrb  (ram_rd_addr)
);

bram_256_8bit bram_256_8bit_inst1
( 
    .dia    (taps0x),
    .addra  (ram_rd_addr_d0),
    .wea    (clken_dly[0]),
    .clk    (clock),
    .dob    (taps1x),
    .addrb  (ram_rd_addr)
);

endmodule 