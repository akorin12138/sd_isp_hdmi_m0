// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : hfut904
// File   : write_full.v
// Create : 2022-03-04 10:32:09
// Revise : 2022-03-04 15:25:14
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
module write_full #(
	//-----------------paramter-------------------------------
	parameter 			FIFO_addr_size 		=		2		

	)(
		//==================	port define ===========================

	input										clk_w					,
	input										rst_w					,
	input										w_en 					,
	
	input		[FIFO_addr_size:0]				r_pointer_gray_sync		,
	output										full 					,
	output	wire	[FIFO_addr_size-1:0]		w_addr					,
	output	wire	[FIFO_addr_size:0]			w_pointer_gray 					 

);


//========================reg wire =================================

	reg 		[FIFO_addr_size:0]		w_pointer_bin				;
	wire 		flag_wr												;


//===================Main  Code=====================================

//always block
always @(posedge clk_w or negedge rst_w) begin : proc_
	if(~rst_w) begin
		 		w_pointer_bin 		<= 		0				;
	end 
	else if (flag_wr)begin
				w_pointer_bin	 	<= 		w_pointer_bin + 1;
	end
	else begin
		 w_pointer_bin 				<= 			w_pointer_bin 	;
	end
end



//assign
assign		flag_wr				=		(w_en == 1) && (full == 0)			;

assign		w_pointer_gray		=		(w_pointer_bin >> 1)^w_pointer_bin	;
//二进制码转换为gary码		Gn-1 = 	Bn-1 Gi= Bi+1 ^ Bi

assign 		w_addr				=		w_pointer_bin[FIFO_addr_size-1:0]	;

assign		full 				=		(w_pointer_gray == {~r_pointer_gray_sync[FIFO_addr_size:FIFO_addr_size-1],r_pointer_gray_sync[FIFO_addr_size-2:0]} ) ? 1: 0	;

//满信号  最高位取反，其他位相等就是满
endmodule 


