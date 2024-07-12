// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : hfut904
// File   : synchronization.v
// Create : 2022-03-04 14:26:40
// Revise : 2022-03-04 20:55:24
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
///同步模块 打两拍进行同步
module synchronization #(
//=======================paramter==========================================
	parameter		FIFO_addr_size		=		2		
	)(
						
	//====================port define=======================================
		input							clk 				,
		input 							rst 				,
		input 		[FIFO_addr_size:0]	din					,
		output	reg	[FIFO_addr_size:0]	dout				
	
);

//====================reg wire ==========================================
	reg 		[FIFO_addr_size:0]	dout_t			;

//always block
always @(posedge clk or negedge rst) begin 
	if(~rst) begin
		 		dout 		<= 		{(FIFO_addr_size){1'b0}}				;
		 		dout_t		<=		{(FIFO_addr_size){1'b0}}				;
	end 		
	else begin		
		 		dout_t		<= 		din			;
		 		dout 		<=		dout_t		;
	end
end

endmodule 
