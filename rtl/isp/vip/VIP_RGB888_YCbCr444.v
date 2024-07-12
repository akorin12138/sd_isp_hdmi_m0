`timescale 1ns/1ns
module VIP_RGB888_YCbCr444
(
	//global clock
	input				clk,  				//cmos video pixel clock
	input				rst_n,				//global reset

	//Image data prepred to be processd
	input				per_frame_vsync,	//Prepared Image data vsync valid signal
	input				per_frame_href,		//Prepared Image data href vaild  signal
	input				per_frame_clken,	//Prepared Image data output/capture enable clock	
	input		[23:0]	per_img_data,		//Prepared Image red data to be processed
	
	//Image data has been processd
	output				post_frame_vsync,	//Processed Image data vsync valid signal
	output				post_frame_href,	//Processed Image data href vaild  signal
	output				post_frame_clken,	//Processed Image data output/capture enable clock	
	output		[23:0]	post_img_YCbCr			//Processed Image brightness output
);
wire [7:0] per_img_red ;
wire [7:0] per_img_green;
wire [7:0] per_img_blue ;
wire [7:0] post_img_Y;
wire [7:0] post_img_Cb;
wire [7:0] post_img_Cr;
assign	per_img_red = per_img_data[23:16];
assign	per_img_green = per_img_data[15:8];
assign	per_img_blue = per_img_data[7:0];
assign  post_img_YCbCr = {post_img_Y,post_img_Cb,post_img_Cr};
//--------------------------------------------
/*********************************************
//Refer to <OV7725 Camera Module Software Applicaton Note> page 5
	Y 	=	(77 *R 	+ 	150*G 	+ 	29 *B)>>8
	Cb 	=	(-43*R	- 	85 *G	+ 	128*B)>>8 + 128
	Cr 	=	(128*R 	-	107*G  	-	21 *B)>>8 + 128
--->
	Y 	=	(77 *R 	+ 	150*G 	+ 	29 *B)>>8
	Cb 	=	(-43*R	- 	85 *G	+ 	128*B + 32768)>>8
	Cr 	=	(128*R 	-	107*G  	-	21 *B + 32768)>>8
**********************************************/
//Step 1
reg	[21:0]	img_red_r0,		img_red_r1,		img_red_r2;	
reg	[21:0]	img_green_r0,	img_green_r1,	img_green_r2; 
reg	[21:0]	img_blue_r0,	img_blue_r1,	img_blue_r2; 
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_red_r0		<=	0;
		img_red_r1		<=	0;
		img_red_r2		<=	0;
		img_green_r0	<=	0;
		img_green_r1	<=	0;
		img_green_r2	<=	0;
		img_blue_r0		<=	0;
		img_blue_r1		<=	0;
		img_blue_r2		<=	0;
		end
	else
		begin
        //y
		img_red_r0		<=	per_img_red 	* 	'd1225;
		img_green_r0	<=	per_img_green 	* 	'd2404;
		img_blue_r0		<=	per_img_blue 	* 	'd467;
        //cb
		img_red_r1		<=	per_img_red 	* 	'd705;
		img_green_r1	<=	per_img_green 	* 	'd1389;
		img_blue_r1		<=	per_img_blue 	* 	'd2093;
        //cr
		img_red_r2		<=	per_img_red 	* 	'd2093;
		img_blue_r2		<=	per_img_blue 	* 	'd1753;
		img_green_r2	<=	per_img_green 	* 	'd340;
		end
end

//--------------------------------------------------
//Step 2
reg	[21:0]	img_Y_r0;	
reg	[21:0]	img_Cb_r0; 
reg	[21:0]	img_Cr_r0; 
always@(posedge clk or negedge rst_n)
begin
	if(!rst_n)
		begin
		img_Y_r0	<=	0;
		img_Cb_r0	<=	0;
		img_Cr_r0	<=	0;
		end
	else
		begin
		img_Y_r0	<=	img_red_r0+img_green_r0+img_blue_r0;
		img_Cb_r0	<=	((img_blue_r1+'d524288)>(img_green_r1+img_red_r1))?(img_blue_r1+'d524288-img_green_r1-img_red_r1):'d0;
		img_Cr_r0	<=	((img_red_r2+'d524288)>(img_green_r2+img_blue_r2))?(img_red_r2+'d524288-img_green_r2-img_blue_r2):'d0;
		end
end

//--------------------------------------------------
//Step 3
reg	[7:0]	img_Y_r1;	
reg	[7:0]	img_Cb_r1; 
reg	[7:0]	img_Cr_r1; 
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        begin
        img_Y_r1	<=	0;
        img_Cb_r1	<=	0;
        img_Cr_r1	<=	0;
        end
    else
        begin
        img_Y_r1	<=	(img_Y_r0 [21:20]==2'b00) ? img_Y_r0 [19:12] : 8'hff;
        img_Cb_r1	<=	(img_Cb_r0[21:20]==2'b00) ? img_Cb_r0[19:12] : 8'hff;
        img_Cr_r1	<=	(img_Cr_r0[21:20]==2'b00) ? img_Cr_r0[19:12] : 8'hff; 
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
            per_frame_href_r    <=  {per_frame_href_r[1:0],     per_frame_href};
            per_frame_clken_r   <=  {per_frame_clken_r[1:0],    per_frame_clken};
        end
end
assign  post_frame_vsync    =   per_frame_vsync_r[2];
assign  post_frame_href     =   per_frame_href_r[2];
assign  post_frame_clken    =   per_frame_clken_r[2];
assign  post_img_Y  =   post_frame_clken ? img_Y_r1 : 8'd0;
assign  post_img_Cb =   post_frame_clken ? img_Cb_r1: 8'd0;
assign  post_img_Cr =   post_frame_clken ? img_Cr_r1: 8'd0;
endmodule
