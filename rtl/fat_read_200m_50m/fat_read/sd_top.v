module sd_top
#(
    parameter  H_VALID  =   24'd1024 ,   //行有效数据
    parameter  V_VALID  =   24'd768    //列有效数据
)
(
    input               clk,
    input               clk_200m,
    input               rst_n,
        
    output              sd_clk,
    inout               sd_cmd,
    inout   [3:0]       sd_dat,
        
    output  [15:0]      sd_img_data,    
    output              sd_img_data_en  
            
);
localparam  H_IMG   =   24'd1936;
localparam  V_IMG   =   24'd1088;

localparam  sd_crtl_speed = 200;
localparam  sd_data_speed = 50;
localparam  sd_data_8b_cycle = sd_crtl_speed/sd_data_speed*2;
localparam  sd_data_16b_cycle = sd_crtl_speed/sd_data_speed*4;

localparam  sd_data16_cnt_max   =   sd_data_16b_cycle-1;

wire                sd_ren;         
wire    [31:0]      sd_sector;      
wire    [29:0]      sd_data_size;   
wire                sd_done;        
wire                sd_outen;       
wire    [7:0]       sd_outbyte;     
wire    [31:0]      sd_outaddr;     
                                    
                                    
wire	            crc7_outdata_en;
wire    [6:0]	    crc7_outdata;    
wire    [39:0]	    crc7_indata;
wire	            crc7_indata_req;
wire        	    table_read_rden;//查表得到值
wire    [7:0]       table_read_address;
wire    [7:0]	    table_read_data;

reg     [3:0]       sd_data16_cnt;
reg                 sd_data16_valid;
reg     [15:0]      sd_data16;       

reg     [11:0]      hcnt;  
reg     [11:0]      vcnt; 
wire                lcd_valid; 

assign sd_ren = 1'b1;
assign sd_sector = 32'd24832;   //day
// assign sd_sector = 32'd1505920;   //night
assign sd_data_size = 30'd758292480;   //data_size

//8位转16位
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0) 
        sd_data16_cnt <= 'b0;
    else if((sd_outen)&&(sd_data16_cnt == sd_data16_cnt_max))
        sd_data16_cnt <= 0;
    else if(sd_outen) 
        sd_data16_cnt <= sd_data16_cnt + 1;
    else
        sd_data16_cnt <= sd_data16_cnt;

always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        sd_data16 <= 16'b0;
    else if((sd_data16_cnt[2:0] == 3'b001)&&(sd_outen))
        sd_data16 <= {sd_data16[7:0],sd_outbyte};
    else
        sd_data16 <= sd_data16;
        
always@(posedge clk or negedge rst_n)
    if(rst_n == 1'b0)
        sd_data16_valid <= 1'b0;
    else if((sd_data16_cnt == sd_data16_cnt_max)&&(sd_outen))
        sd_data16_valid <= 1'b1;
    else
        sd_data16_valid <= 1'b0;   
        

//取1024*768区域像素
always @ (posedge clk or negedge rst_n)
    if (rst_n == 1'b0)
        hcnt <= 12'd0;
    else if((sd_data16_valid)&&(hcnt == H_IMG - 1'b1))
        hcnt <= 12'd0;
    else if(sd_data16_valid)  
        hcnt <= hcnt + 12'd1; 
 
//v_sync counter & generator
always@(posedge clk or negedge rst_n)
    if (rst_n == 1'b0)
        vcnt <= 12'b0;
    else if((sd_data16_valid)&&(hcnt == H_IMG - 1'b1)&&(vcnt == V_IMG - 1'b1))	//frame over
        vcnt <= 12'b0;
    else if((sd_data16_valid)&&(hcnt == H_IMG - 1'b1))	//line over
        vcnt <= vcnt + 1'b1;
            
assign  lcd_valid = ((sd_data16_valid)&&(hcnt<H_VALID)&&(vcnt<V_VALID));      

assign   sd_img_data_en =  lcd_valid;
assign   sd_img_data    =  sd_data16; 

sd_operation   u_sd_operation
(
	.sys_clk                (clk            ),
	.clk_200m               (clk_200m       ),
	.init_repeat_req        (~rst_n         ),
    
	.read_req               (sd_ren         ),
    
	.sd_ram_blockaddress    (sd_sector      ),
	.sd_ram_data_size       (sd_data_size   ),
    
    .outdata_done           (sd_done        ),
	.outdata_en             (sd_outen       ),
	.outdata                (sd_outbyte     ),
	.outdata_num            (sd_outaddr     ),
    
	.write_req              (0              ),
    
	.read_ram_data          (),
	.read_ram_en            (),
	.read_ram_address       (),
    
	.sd_idle_flag           (),
    
	.sd_command             (sd_cmd         ),
	.sd_data                (sd_dat         ),
	.sd_clk                 (sd_clk         ),
    
	.crc7_outdata_en        (crc7_outdata_en),
	.crc7_outdata           (crc7_outdata   ),
	.crc7_indata            (crc7_indata    ),
	.crc7_indata_req        (crc7_indata_req)
	
	);
    
crc7    u_crc7
(
	.sys_clk                (clk            ),
	.indata                 (crc7_indata    ),
	.indata_req             (crc7_indata_req),
    
	.table_read_rden        (table_read_rden),
	.table_read_address     (table_read_address),
	.table_read_data        (table_read_data),
    
	.outdata                (crc7_outdata   ),
	.outdata_en             (crc7_outdata_en)
	);

crc7_bram   u_crc7_bram
( 
    .doa            (table_read_data    ), 
    .dia            (                   ),
    .addra          (table_read_address ),
    .clka           (clk                ),
    .wea            (0                  )
    );
endmodule