module VIP_YCbCr444_RGB888
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//Image data prepred to be processd
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input				per_frame_clken,	//Prepared Image data output/capture enable clock	
	input 		[23:0]  per_img_data,
	//Image data has been processd
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output				post_frame_clken,	//Processed Image data output/capture enable clock	
	output  	[23:0]	post_img_rgb
);
wire [7:0] per_y ;
wire [7:0] per_cb;
wire [7:0] per_cr ;
wire [7:0] post_img_r;
wire [7:0] post_img_g;
wire [7:0] post_img_b;
assign	per_y = per_img_data[23:16];
assign	per_cb = per_img_data[15:8];
assign	per_cr = per_img_data[7:0];
assign  post_img_rgb = {post_img_r,post_img_g,post_img_b};


/***************************************parameters*******************************************/

//Step 1
reg	[21:0]	img_y_r0,	img_y_r1,	img_y_r2;	
reg	[21:0]	img_cb_r0,	img_cb_r1,	img_cb_r2; 
reg	[21:0]	img_cr_r0,	img_cr_r1,	img_cr_r2; 
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_y_r0		<=	0;
		img_y_r1		<=	0;
		img_y_r2		<=	0;
		img_cb_r0	    <=	0;
		img_cb_r1	    <=	0;
		img_cb_r2	    <=	0;
		img_cr_r0		<=	0;
		img_cr_r1		<=	0;
		img_cr_r2		<=	0;
		end
	else
		begin
		img_y_r0		<=	per_y   *   'd4096;
		img_cr_r0		<=	per_cr	* 	'd5616;

		img_y_r1		<=	per_y   *   'd4096;
		img_cb_r1	    <=	per_cb 	* 	'd1376;
		img_cr_r1		<=	per_cr	* 	'd2859;

		img_y_r2		<=	per_y   *   'd4096;
		img_cb_r2	    <=	per_cb 	* 	'd7094;
		end
end

//--------------------------------------------------
//Step 2
reg	[21:0]	img_r_r0;	
reg	[21:0]	img_g_r0; 
reg	[21:0]	img_b_r0; 
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_r_r0	<=	0;
		img_g_r0	<=	0;
		img_b_r0	<=	0;
		end
	else
		begin
		img_r_r0	<=	((img_y_r0 + img_cr_r0)>'d718799) ? img_y_r0 + img_cr_r0 - 'd718799 : 'd0;//负数归0
		img_g_r0	<=	((img_y_r1 + 'd542114)>(img_cb_r1 + img_cr_r1)) ? (img_y_r1 +  'd542114 - img_cb_r1 - img_cr_r1) : 'd0;
		img_b_r0	<=	((img_y_r2 + img_cb_r2)>'d908067) ? img_y_r2 + img_cb_r2 - 'd908067 : 'd0;
		end
end

//--------------------------------------------------
//Step 3
reg	[7:0]	img_r_r1;	
reg	[7:0]	img_g_r1; 
reg	[7:0]	img_b_r1;

// assign  img_r_r1 = img_r_r0[21:20]!=2'b00 ? 8'hff : img_r_r0[19:12];
// assign  img_g_r1 = img_g_r0[21:20]!=2'b00 ? 8'hff : img_g_r0[19:12];
// assign  img_b_r1 = img_b_r0[21:20]!=2'b00 ? 8'hff : img_b_r0[19:12];//超出阈值

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
        img_r_r1	<=	0;
        img_g_r1	<=	0;
        img_b_r1	<=	0;
        end
    else
        begin
        img_r_r1	<=	(img_r_r0[21:20]==2'b00) ? img_r_r0[19:12] : 8'hff;
        img_g_r1	<=	(img_g_r0[21:20]==2'b00) ? img_g_r0[19:12] : 8'hff;
        img_b_r1	<=	(img_b_r0[21:20]==2'b00) ? img_b_r0[19:12] : 8'hff; 
        end
end

//------------------------------------------
//lag 3 clocks signal sync  
reg	[2:0]	per_frame_vsync_r;
reg	[2:0]	per_frame_href_r;
reg	[2:0]	per_frame_clken_r;
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
            per_frame_vsync_r <= 0;
            per_frame_href_r <= 0;
            per_frame_clken_r <= 0;
        end
    else
        begin
            per_frame_vsync_r   <=  {per_frame_vsync_r[1:0],    per_frame_vsync};
            per_frame_href_r    <=  {per_frame_href_r [1:0],     per_frame_href};
            per_frame_clken_r   <=  {per_frame_clken_r[1:0],    per_frame_clken};
        end
end
assign  post_frame_vsync    =   per_frame_vsync_r[2];
assign  post_frame_href     =   per_frame_href_r [2];
assign  post_frame_clken    =   per_frame_clken_r[2];
assign  post_img_r =   post_frame_clken ? img_r_r1: 8'd0;
assign  post_img_g =   post_frame_clken ? img_g_r1: 8'd0;
assign  post_img_b =   post_frame_clken ? img_b_r1: 8'd0;
endmodule
