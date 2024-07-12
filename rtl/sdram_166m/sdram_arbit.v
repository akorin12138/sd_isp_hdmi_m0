
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// File   : sdram_arbit.v
// Create : 2022-06-07 15:32:59
// Revise : 2022-06-20 16:21:04
// Verdion:
// Description:
// -----------------------------------------------------------------------------
`timescale 1ps/1ps
module sdram_arbit (
	//system signals
			input 					sys_clk 		,		//系统时钟，167M	
			input 					sys_rst_n 		,		//系统复位信号，低电平有效
	//init signals					
			input 					init_end 		,		//初始化结束标志		
			input  	[3:0]			init_cmd 		,		//初始化阶段命令
			input 	[1:0]			init_ba			,		//初始化阶段bank地址
			input 	[12:0]			init_addr 		,		//初始化阶段地址总线
	//aref signals					
			input 					aref_req		,		//刷新请求信号
			input 					aref_end 		,		//刷新结束信号
			input 	[3:0]			aref_cmd 		,		//刷新阶段命令
			input 	[1:0]			aref_ba 		,		//刷新阶段bank地址
			input 	[12:0]			aref_addr		,		//刷新阶段地址
	//write signals					
			input 					wr_req 			,		//写数据请求
			input 					wr_end 			,		//一次写结束信号
			input 	[3:0]			wr_cmd 			,		//写阶段命令
			input 	[1:0]			wr_ba 			,		//写阶段BANK地址
			input 	[12:0]			wr_addr 		,		//写阶段地址总线
			input 	[15:0]			wr_data 		,		//写数据
			input 					wr_sdram_en 	,		//写sdram使能信号
	//read signals				
			input 					rd_req 			,		//读请求
			input 					rd_end 			,		//读数据结束
			input 	[3:0]			rd_cmd 			,		//读阶段命令
			input 	[1:0] 			rd_ba 			,		//读阶段bank地址
			input 	[12:0]			rd_addr 		,		//读地址总线
	//output signals				
			output  	reg			aref_en 		,		//刷新请求
			output 		reg			wr_en 			,		//写数据使能
			output 		reg			rd_en 			,		//读数据使能
			output 		wire		sdram_cke 		,		//sdram时钟有效信号
			output 		wire		sdram_cs_n 		,		//sdram片选信号
			output 		wire		sdram_cas_n 	,		//sdram行选通信号
			output 		wire		sdram_ras_n		,		//sdram列选通信号
			output 		wire		sdram_we_n		,		//sdram写使能信号
			output reg	[1:0]		sdram_ba 		,		//sdram的bank地址
			output reg	[12:0]		sdram_addr 		,		//sdram的地址总线
			inout wire [15:0] 		sdram_dq				//sdram的数据总线
		
	);	

//localparam
localparam 		IDLE 	=	3'b000		,		//初始状态
				ARBIT 	=	3'b001		,		//仲裁状态
				AREF 	=	3'b011		,		//自动刷新
				WRITE 	=	3'b010		,		//写状态
				READ 	=	3'b110		;		//读状态
//命令
localparam 		NOP 	=	4'b0111		;	//空操作命令


//reg define
reg 	[3:0]		sdram_cmd	;	//写入SDRAM 命令
reg 	[2:0]		state_cs 	;	//当前状态
reg 	[2:0]		state_ns	;	//下一状态
reg 	[15:0]	 	wr_data_reg	;	//数据寄存

//状态机
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_state_cs
	if(~sys_rst_n) begin
		state_cs 	<= 	IDLE 		;
	end else begin	
		state_cs 	<= 	state_ns	;
	end
end


//组合逻辑，判断跳转
always@(*) 	begin
		case(state_cs)
			IDLE 	:	begin
							if(init_end == 1'b1)
								state_ns = 	ARBIT 	;
							else
								state_ns =	IDLE 	;

			end 

			ARBIT	:	begin						//刷新请求>写请求>读请求
							if(aref_req == 1'b1)
								state_ns = AREF 	;
							else if(wr_req == 1'b1 )
								state_ns = WRITE 	;
							else if(rd_req == 1'b1)
								state_ns = READ 	;
							else
								state_ns = ARBIT 	;

			end 

			AREF 	:	begin
							if(aref_end == 1'b1)
								state_ns  	=  	ARBIT 	;
							else
								state_ns  	=	AREF 	;

			end 

			WRITE	:	begin
							if(wr_end == 1'b1)
								state_ns 	=	ARBIT 	;
							else
								state_ns 	=	WRITE	;

			end 

			READ 	:	begin
							if(rd_end == 1'b1)
								state_ns 	=	ARBIT 	;
							else
								state_ns	=	READ 	;

			end 

			default	:		state_ns 	=	IDLE	;

		endcase 

end 


//时序逻辑 输出错误，组合逻辑输出，可组合可时序
//sdram_ba sdram_addr sdram_cmd
always @(* ) begin 
	case(state_cs)

		IDLE 	:	begin
						sdram_cmd  	=  init_cmd	;
						sdram_ba    =  init_ba		;
						sdram_addr  =  init_addr	;
		end 

		ARBIT 	:	begin
						sdram_cmd   =  NOP			;
						sdram_ba    =  2'b11		;
						sdram_addr  =  13'h1fff	;
		end

		AREF 	:	begin
						sdram_cmd   =  aref_cmd	;
						sdram_ba    =  aref_ba		;
						sdram_addr  =  aref_addr	;

		end 

		WRITE 	:	begin
						sdram_cmd   =  wr_cmd		;
            			sdram_ba    =  wr_ba		;
            			sdram_addr  =  wr_addr		;
				
		end 

		READ 	:	begin
						sdram_cmd   =  rd_cmd		;
						sdram_ba    =  rd_ba		;
						sdram_addr  =  rd_addr		;
						
		end 

		default : 	begin
						sdram_cmd   =  NOP			;
						sdram_ba    =  2'b11		;
						sdram_addr  =  13'h1fff	;

		end 
	endcase // state_cs
end

//自动刷新使能
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_
	if(~sys_rst_n) begin
		aref_en 	<= 	1'b0		;
	end 
	else if ((state_cs == ARBIT) && (aref_req == 1'b1) )begin
		 aref_en 	<= 	1'b1 		;
	end
	else if(aref_end == 1'b1 )
		aref_en 	<= 	1'b0 		;
end

//写数据使能
//wr_en
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_wr_en 
	if(~sys_rst_n) begin
		wr_en  <= 1'b0		;
	end 
	else if((state_cs == ARBIT) && (aref_req == 1'b0) && (wr_req == 1'b1)) begin
		wr_en  <= 1'b1		;
	end
	else if(wr_end == 1'b1)
		wr_en 	<=	1'b0	;
end


//读数据使能
//rd_en
always @(posedge sys_clk or negedge sys_rst_n) begin : proc_rd_en 
	if(~sys_rst_n) begin
		rd_en  		<= 1'b0 		;
	end

	else  if((state_cs == ARBIT) && (aref_req == 1'b0) && (rd_req == 1'b1) )begin
		rd_en 		 <= 1'b1 		;
	end

	else if(rd_end	==	1'b1)
		rd_en 		<=	1'b0 		;
end
	

//SDRAM 时钟使能
assign	sdram_cke = 1'b1 	;

//SDRAM 数据总线
assign	sdram_dq  = (wr_sdram_en == 1'b1 )?wr_data: 16'bz 	;	//作为输出端口，延迟一拍？

always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
		 wr_data_reg <= 0;
	end else begin
		 wr_data_reg <=	wr_data ;
	end
end

//片选信号，行地址选通信号，列地址选通信号，写使能信号
assign 	{sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n}	=	sdram_cmd 	;

endmodule




