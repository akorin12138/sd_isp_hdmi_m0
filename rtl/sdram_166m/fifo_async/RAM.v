// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : hfut904
// File   : RAM.v
// Create : 2022-03-04 10:02:58
// Revise : 2022-03-04 17:03:43
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------

//双口RAM模块

module RAM #(
//------------------------paramter-------------------
	parameter 			FIFO_data_size 		=		3		,
	parameter 			FIFO_addr_size 		= 		2		

	)(
	//----------------------port	define		-----------------
	//write clock & reset
	input				 					clk_w				,
	input 				 					rst_w				,
	//read clock & reset
	input 				 					clk_r 				,
	input				 					rst_r				,
	//key signals
	input 				 					full				,
	input 				 					empty 				,
 	//enable			
	input 				 					w_en				,
	input				 					r_en				,
	//wr rd addr
	input 		[FIFO_addr_size-1:0] 		w_addr				,
	input 		[FIFO_addr_size-1:0]		r_addr				,

	input 		[FIFO_data_size-1:0]		data_in				,
	output	reg	[FIFO_data_size-1:0]		data_out			
	
);




//==============================================================
//------------paramter reg  wire  ------------------------------

	reg 	[FIFO_data_size-1:0]  mem [{FIFO_addr_size{1'b1}}:0 ]	; 

	integer		i 		;
/*------------------------------------------------------------------------------
--  	wire 			flag_wr				;
		wire 			flag_rd	 			;
------------------------------------------------------------------------------*/


	//always block
	always @(posedge clk_w or negedge rst_w) begin 
		if(~rst_w) begin
				for ( i = 0; i <= FIFO_data_size; i=i+1) begin
					mem[i]		<=		{FIFO_data_size{1'b0}}		;
				end

		end 
		else if ((w_en == 1) && (full == 0))begin
				mem[w_addr] 	<=		data_in						;
		end
		else begin
				mem[w_addr] 	<=		{FIFO_data_size{1'b0}}		;
		end
	end

	//rd
	always @(posedge clk_r or negedge rst_r) begin 
		if(~rst_r) begin
			data_out		<=		{FIFO_data_size{1'b0}}		;		//'d0	
		end 
		else if ((r_en == 1) && (empty == 0))begin
				data_out 	<=		mem[r_addr] 					;
		end
		else begin
			data_out		<=		{FIFO_data_size{1'b0}}		;
		end
	end

	//assign
	/*
	assign 			flag_wr		=	(w_en == 1) && (full == 0)		;
	assign 			flag_rd		=	(r_en == 1) && (empty == 0)		;
	*/


endmodule 
