// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : hfut904
// File   : read_empty.v
// Create : 2022-03-04 11:10:59
// Revise : 2022-03-04 17:19:20
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
//读空信号产生模块
module read_empty #(
//=====================paramter ================================================

	parameter  				FIFO_addr_size		=		2			
	)(
					//=========================port define===========================================

	input 									clk_r							,
	input									rst_r							,
	input									r_en 							,
	
	input 		[FIFO_addr_size:0]			w_pointer_gray_sync				,
				
	output  wire               				empty 							,
	output 	wire	[FIFO_addr_size-1:0]	r_addr							,
	output	wire	[FIFO_addr_size:0]		r_pointer_gray 					

	
);


//======================reg wire ==================================================
	reg 			[FIFO_addr_size:0] 		r_pointer_bin 					;
	//wire 									flag_rd							;

//============================Main code============================================

always @(posedge clk_r or negedge rst_r) begin : proc_
	if(~rst_r) begin
		 r_pointer_bin		<= 		{FIFO_addr_size{1'b0}}			;
	end
	else if ((r_en == 1) &&(empty == 0)) begin
		 r_pointer_bin		<=    r_pointer_bin + 1   				;
	end
end


//assign

//assign 		flag_rd 			= 	(r_en == 1) &&(empty == 0)						;
assign		r_pointer_gray		=	(r_pointer_bin>>1)^r_pointer_bin				;
assign		r_addr				=	r_pointer_bin[FIFO_addr_size-1:0]				;
assign 		empty 				=	r_pointer_gray == w_pointer_gray_sync? 1: 0 	;	//MSB 最高位相等就判断为空

endmodule 


