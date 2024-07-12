// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// File   : fifo_ctrl.v
// Create : 2022-06-09 09:19:13
// Revise : 2022-06-20 09:14:11
// -----------------------------------------------------------------------------
`timescale 1ps/1ps

module fifo_ctrl (
		//signal define 
		//system signals
		input 					sys_clk 			,		//系统时钟，167MHZ
		input 					sys_rst_n 			,		//系统复位信号，低电平有效
		//写fifo信号				//
		input					wr_fifo_wr_clk		,		//写fifo写时钟
		input 					wr_fifo_wr_req 		,		//写fifo写请求
		input 	[15:0]			wr_fifo_wr_data 	,		//写fifo写数据
		input 	[23:0]			sdram_wr_b_addr 	,		//写SDRAM的首地址
		input 	[23:0]			sdram_wr_e_addr 	,		//写SDRAM的末地址
		input 	[9:0]			wr_burst_len 		,		//写SDRAM的突发长度
		input 					wr_rst 				,		//写复位信号，写fifo清零
		//读fifo信号				//
		input					rd_fifo_rd_clk		,		//读fifo读时钟
		input 					rd_fifo_rd_req 		,		//读fifo读请求
		input 	[23:0]			sdram_rd_b_addr 	,		//读SDRAM的首地址
		input 	[23:0]			sdram_rd_e_addr 	,		//读SDRAM的末地址
		input 	[9:0]			rd_burst_len 		,		//读SDRAM的突发长度
		input 					rd_rst 				,		//读复位信号，读fifo清零
		output 	wire  [15:0]	rd_fifo_rd_data 	,		//读fifo读数据
		output 	wire  [9:0]		rd_fifo_num			,		//读FIFO中的数据量 /读FIFO中写入的数据量
		//
		input 					read_valid 			,		//SDRAM读使能
		input 					init_end 			,		//SDRAM初始化结束信号
		//
		//SDRAM写信号		//
		input 					sdram_wr_ack 		,		//SDRAM写响应
		output 	reg 			sdram_wr_req 		,		//SDRAM写请求
		output 	reg 	[23:0]	sdram_wr_addr 		,		//SDRAM写地址
		output 	wire 	[15:0]	sdram_data_in 		,		//写入SDRAM的数据
		//SDRAM读信号		//
		input 					sdram_rd_ack		,		//SDRAM读响应
		input 			[15:0]	sdram_data_out 		,		//SDRAM读出的数据
		output 	reg 			sdram_rd_req		,		//SDRAM读请求
		output reg		[23:0]	sdram_rd_addr 				//SDRAM读地址
		

	);


//======================================
//param and internal signals
//======================================


//wire define 
wire            wr_ack_fall ;   //写响应信号下降沿
wire            rd_ack_fall ;   //读相应信号下降沿
wire    [9:0]   wr_fifo_num ;   //写fifo中的数据量


//reg define
reg        wr_ack_dly       ;   //写响应打拍
reg        rd_ack_dly       ;   //读响应打拍


//wr_ack_dly: 写响应信号打拍
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_
	if(~sys_rst_n) begin
		 wr_ack_dly 	<= 1'b0				;
	end 
	else begin
		 wr_ack_dly 	<= 	sdram_wr_ack	;
	end
end


//rd_ack_dly:读响应信号打拍
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_rd_ack_dly 
	if(~sys_rst_n) begin
		rd_ack_dly  <= 		1'b0  	;
	end 
	else begin
		rd_ack_dly  <= 	 	sdram_rd_ack 	;
	end
end

//wr_ack_fall,rd_ack_fall:检测读写响应信号下降沿
assign  wr_ack_fall = (wr_ack_dly & ~sdram_wr_ack);
assign  rd_ack_fall = (rd_ack_dly & ~sdram_rd_ack);


//sdram_wr_addr :sdram写地址
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_sdram_wr_addr 
	if(~sys_rst_n) begin
		sdram_wr_addr  <= 24'd0		;
	end 
	else if(wr_rst == 1'b1) begin
		sdram_wr_addr  <= sdram_wr_b_addr ;
	end
	else if(wr_ack_fall == 1'b1 )	//一次突发写结束，更改写地址
		begin
				if(sdram_wr_addr < (sdram_wr_e_addr - wr_burst_len))			//不使用乒乓操作,一次突发写结束,更改写地址,未达到末地址,写地址累加
					sdram_wr_addr 	<=	sdram_wr_addr + wr_burst_len	;
				else															//不使用乒乓操作,到达末地址,回到写起始地址
					sdram_wr_addr 	<=  sdram_wr_b_addr 			;
		end 
end


//sdram_rd_addr:sdram读地址
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        sdram_rd_addr   <=  24'd0;
    else    if(rd_rst == 1'b1)
        sdram_rd_addr   <=  sdram_rd_b_addr;
    else    if(rd_ack_fall == 1'b1) //一次突发读结束,更改读地址
        begin
            if(sdram_rd_addr < (sdram_rd_e_addr - rd_burst_len))
                    //读地址未达到末地址,读地址累加
                sdram_rd_addr   <=  sdram_rd_addr + rd_burst_len;
            else    //到达末地址,回到首地址
                sdram_rd_addr   <=  sdram_rd_b_addr;
        end

//sdram_wr_req,sdram_rd_req:读写请求信号
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(~sys_rst_n) begin
		sdram_rd_req 	 	<= 	1'b0		;
		sdram_wr_req 		<= 	1'b0 		;
	end 
	else if (init_end == 1'b1 )begin		//初始化完成，响应读写请求
		//优先执行写操作，防止写入SDRAM中的数据丢失
			if(wr_fifo_num >= wr_burst_len)	 begin	//写FIFO中的数据量达到写突发长度，数据送出
		 		sdram_wr_req 		<= 		1'b1 	;	//写请求有效，输出到仲裁机，仲裁机判断后输出写使能到写模块，写模块输出
		 		sdram_rd_req		<= 		1'b0 	;
		 	end 

		 	else if((rd_fifo_num < rd_burst_len ) && (read_valid == 1'b1 ))		begin//读FIFO中的数据量小于读突发长度，且读使能信号有效
		 		sdram_wr_req 		<= 		1'b0 	;	
				sdram_rd_req 		<= 		1'b1 	;
		 	end 

		 	else 	begin
		 		sdram_rd_req 	 	<= 	1'b0		;
				sdram_wr_req 		<= 	1'b0 		;
		 	end
	end
	else 	begin
		 		sdram_rd_req 	 	<= 	1'b0		;
				sdram_wr_req 		<= 	1'b0 		;
	end

end

//读写fifo例化
//------------- wr_fifo_data -------------
/*
fifo_data   wr_fifo_data(
    //用户接口
    .wrclk      (wr_fifo_wr_clk ),  //写时钟
    .wrreq      (wr_fifo_wr_req ),  //写请求
    .data       (wr_fifo_wr_data),  //写数据
    //SDRAM接口
    .rdclk      (sys_clk        ),  //读时钟
    .rdreq      (sdram_wr_ack   ),  //读请求
    .q          (sdram_data_in  ),  //读数据

    .rdusedw    (wr_fifo_num    ),  //FIFO中的数据量，读时钟域的指针
    .wrusedw    (               ),
    .aclr       (~sys_rst_n || wr_rst)  //清零信号
    );
*/
//------------- rd_fifo_data -------------
/*
fifo_data   rd_fifo_data(
    //sdram接口
    .wrclk      (sys_clk        ),  //写时钟
    .wrreq      (sdram_rd_ack   ),  //写请求
    .data       (sdram_data_out ),  //写数据
    //用户接口
    .rdclk      (rd_fifo_rd_clk ),  //读时钟
    .rdreq      (rd_fifo_rd_req ),  //读请求
    .q          (rd_fifo_rd_data),  //读数据

    .rdusedw    (               ),
    .wrusedw    (rd_fifo_num    ),  //FIFO中的数据量
    .aclr       (~sys_rst_n || rd_rst)  //清零信号
    );
*/

/* //写fifo例化
	FIFO_async #(
			.FIFO_data_size(16),
			.FIFO_addr_size(10)
		) inst_FIFO_async_wr (
			.clk_w    (wr_fifo_wr_clk				),		//写时钟	
			.rst_w    (~sys_rst_n || wr_rst 		),		//写复位
			.w_en     (wr_fifo_wr_req 				),		//写使能 / 写请求

			.clk_r    (sys_clk 						),		//读时钟
			.rst_r    (~sys_rst_n || wr_rst 		),		//读复位
			.r_en     (sdram_wr_ack 				),		//读使能 / 读请求

			.data_in  (wr_fifo_wr_data 				),		//写数据
			.data_out (sdram_data_in 				),		//读数据
			.empty    (								),		//空信号
			.full     (								),		//满信号
			.wrusedw  (								),		//写指针
			.rdusedw  (	wr_fifo_num					)		//读指针
		);

//读fifo例化
	FIFO_async #(
			.FIFO_data_size(16),
			.FIFO_addr_size(10)
		) inst_FIFO_async_rd  (
			.clk_w    (sys_clk						),		//写时钟	
			.rst_w    (~sys_rst_n || rd_rst 		),		//写复位
			.w_en     (sdram_rd_ack 				),		//写使能 / 写请求

			.clk_r    (rd_fifo_rd_clk 				),		//读时钟
			.rst_r    (~sys_rst_n || wr_rst 		),		//读复位
			.r_en     (rd_fifo_rd_req 				),		//读使能 / 读请求

			.data_in  (sdram_data_out 				),		//写数据
			.data_out (rd_fifo_rd_data 				),		//读数据
			.empty    (								),		//空信号
			.full     (								),		//满信号
			.wrusedw  (								),		//写指针
			.rdusedw  (	rd_fifo_num					)		//读指针
		); */
//------------- wr_fifo_data -------------
SDRAMFIFO etr_fifo_wrdata(
.rst(~sys_rst_n || wr_rst),
.di(wr_fifo_wr_data),
.clkw(wr_fifo_wr_clk),
.we(wr_fifo_wr_req),
.dout(sdram_data_in),
.clkr(sys_clk),
.re(sdram_wr_ack),
.valid(),
.empty_flag(),
.full_flag(),
.afull(),
.aempty(),
.rdusedw(wr_fifo_num),
.wrusedw()
);

//------------- rd_fifo_data -------------
SDRAMFIFO etr_fifo_rddata(
.rst(~sys_rst_n || rd_rst),
.di(sdram_data_out),
.clkw(sys_clk),
.we(sdram_rd_ack),
.dout(rd_fifo_rd_data),
.clkr(rd_fifo_rd_clk),
.re(rd_fifo_rd_req),
.valid(),
.empty_flag(),
.full_flag(),
.afull(),
.aempty(),
.wrusedw(rd_fifo_num)
);











endmodule
