// -----------------------------------------------------------------------------
// Copyright (c) 2014-2022 All rights reserved
// -----------------------------------------------------------------------------
// Author : hfut904
// File   : FIFO_async.v
// Create : 2022-03-04 09:47:04
// Revise : 2022-03-04 21:03:52
// Editor : sublime text4, tab size (4)
// -----------------------------------------------------------------------------
//异步fifo设计 包括五个部分 RAM、write_full、read_empty、synchronization(写到读、读到写)
module FIFO_async #( 
	//------------------paramter------------------------------

 	parameter 					FIFO_data_size	=	6 	,
 	parameter					FIFO_addr_size 	=	5 		
	
	)(	
	//write signals
	input 				 					clk_w		,
	input 				 					rst_w		,
	input 				 					w_en		,
 	//read signals
	input 				 					clk_r		,
	input 				 					rst_r		,
	input 				 					r_en		,
	//data in & out
	input 		[FIFO_data_size-1:0] 		data_in 	,
	output 		[FIFO_data_size-1:0] 		data_out  	,
	//key signals
	output 		wire						empty 		,
	output 		wire						full 		,
    output      [FIFO_addr_size-1:0]        wrusedw     ,
    output      [FIFO_addr_size-1:0]        rdusedw      
    
);



//==============================================================
//------------paramter reg  wire  ------------------------------

wire 		[FIFO_addr_size:0]		r_pointer_gray_sync		 	;
wire		[FIFO_addr_size:0]		w_pointer_gray_sync		 	;

wire 		[FIFO_addr_size:0]		r_pointer_gray 				;	
wire 	 	[FIFO_addr_size:0] 		w_pointer_gray 				;

wire 		[FIFO_addr_size-1:0] 	w_addr 						;
wire 		[FIFO_addr_size-1:0] 	r_addr 						;

assign wrusedw = w_addr;
assign rdusedw = r_addr;

//inst model
	RAM #(
			.FIFO_data_size(FIFO_data_size),
			.FIFO_addr_size(FIFO_addr_size)
		) inst_RAM (
			.clk_w    (clk_w		),
			.rst_w    (rst_w		),
			.clk_r    (clk_r		),
			.rst_r    (rst_r		),
			.full     (full 		),
			.empty    (empty 		),
			.w_en     (w_en 		),
			.r_en     (r_en 		),
			.r_addr   (r_addr		),
			.w_addr   (w_addr 		),
			.data_in  (data_in 		),
			.data_out (data_out		)
		);


	write_full #(
			.FIFO_addr_size(FIFO_addr_size)
		) inst_write_full (
			.clk_w               (clk_w 				),
			.rst_w               (rst_w 				),
			.w_en                (w_en 					),
			.r_pointer_gray_sync (r_pointer_gray_sync 	),
			.w_pointer_gray      (w_pointer_gray 		),
			.w_addr              (w_addr 				),
			.full                (full 					)
		);


	read_empty #(
			.FIFO_addr_size(FIFO_addr_size)
		) inst_read_empty (
			.clk_r               (clk_r	 				),
			.rst_r               (rst_r 				),
			.r_en                (r_en 					),
			.w_pointer_gray_sync (w_pointer_gray_sync 	),
			.r_pointer_gray      (r_pointer_gray 		),
			.r_addr              (r_addr 				),
			.empty               (empty 				)
		);


	synchronization #(
			.FIFO_addr_size(FIFO_addr_size)
		) inst1_synchronization (
			.clk      (clk_r 					),
			.rst      (rst_r 					),
			.din  	  (r_pointer_gray 			),
			.dout 	  (r_pointer_gray_sync		)
		);

	synchronization #(
			.FIFO_addr_size(FIFO_addr_size)
		) inst2_synchronization (
			.clk      (clk_w 					),
			.rst      (rst_w 					),
			.din  	  (w_pointer_gray 			),
			.dout 	  (w_pointer_gray_sync		)
		);



endmodule 


