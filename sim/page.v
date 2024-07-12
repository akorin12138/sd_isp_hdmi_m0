/*
用于sdram后hdmi前,使能由hdmi模块控制
*/
`include "../rtl/sdran_as_bram/include/global_def.v"
module page(
    input  wire         clk,            //输入时钟为hdmi时钟
    input  wire         clk_ref,        //输入时钟为hdmi偏移180deg时钟
    input  wire         rstn,

    input  wire [15:0]  isp_data,
    input  wire [31:0]  page_addr,
    input  wire [23:0]  page_data,

    input  wire         app_en,         //page显示有效使能
    input  wire         hdmi_de,        //比有效区域早一个周期 

    output wire [15:0]  hdmi_data
);

parameter PAGE_WIDTH  = 300;
parameter PAGE_HEIGHT = 500;
parameter PAGE_SIZE   = PAGE_HEIGHT * PAGE_WIDTH;

wire  			SDRAM_CLK;
wire 			SDR_RAS;
wire  			SDR_CAS;
wire  			SDR_WE;
wire  [`BA_WIDTH-1:0]	SDR_BA; 
wire  [`ROW_WIDTH-1:0]	SDR_ADDR;
wire  [`DATA_WIDTH-1:0]	SDR_DQ ;
wire  [`DM_WIDTH-1:0]	SDR_DM; 

wire 					App_wr_en;
wire [`ADDR_WIDTH-1:0]	App_wr_addr;
wire [`DM_WIDTH-1:0]	App_wr_dm;
wire [`DATA_WIDTH-1:0]	App_wr_din;

wire 					App_rd_en;
wire [`ADDR_WIDTH-1:0]	App_rd_addr;
wire 					Sdr_rd_en;
wire [`DATA_WIDTH-1:0]	Sdr_rd_dout;

reg de_r;
reg [31:0] pixel_cnt;
reg app_enr;
wire sdr_init_done;
wire sdr_init_ref_vld;
wire sdr_busy;

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        app_enr <= 1'b0;
    else if(~hdmi_de)
        app_enr <= app_en;
    else
        app_enr <= app_enr;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        de_r <= 1'b0;
    else
        de_r <= hdmi_de;
end



parameter WIDTH = 1920;         //原图分辨率
parameter HEIGHT = 1080;        //原图分辨率
reg [10:0]  h_cnt;
reg [10:0]  v_cnt;
reg [23:0]  o_data;
wire        page_en;



//h_cnt:行像素计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        h_cnt   <=  12'd0   ;
    else if(de_r == 1'b1)
        if(h_cnt == WIDTH - 1'd1)
            h_cnt   <=  12'd0   ;
        else
            h_cnt   <=  h_cnt + 1'd1   ;
    else
        h_cnt <= h_cnt;
//v_cnt:场像素计数器
always@(posedge clk or negedge rstn)
    if(rstn == 1'b0)
        v_cnt   <=  12'd0 ;
    else    if(de_r == 1'b1)
        if((v_cnt == HEIGHT - 1'd1) &&  (h_cnt == WIDTH-1'd1))
            v_cnt   <=  12'd0 ;
        else    if(h_cnt == WIDTH - 1'd1)
            v_cnt   <=  v_cnt + 1'd1 ;
        else
            v_cnt   <=  v_cnt ;
    else
        v_cnt   <=  v_cnt ;

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        o_data <= 24'd0;
    else if(h_cnt >= (WIDTH-PAGE_WIDTH) && h_cnt <= WIDTH - 1 && 
            v_cnt >= 0 && v_cnt <= PAGE_HEIGHT - 1 )
        o_data <= 24'hffffff;
    else
        o_data <= o_data;
end
// always @(posedge clk or negedge rstn) begin
//     if(~rstn)
//         page_en <= 1'd0;
//     else if(h_cnt >= (WIDTH-PAGE_WIDTH) && h_cnt <= WIDTH - 1 && 
//             v_cnt >= (HEIGHT-PAGE_HEIGHT) && v_cnt <= HEIGHT - 1 )
//         page_en <= 1'b1;
//     else
//         page_en <= 1'b0;
// end

assign page_en = (h_cnt >= (WIDTH-PAGE_WIDTH) && h_cnt <= WIDTH - 1 && 
            v_cnt >= 0 && v_cnt <= PAGE_HEIGHT - 1 ) ? 1'b1 : 1'b0;

assign hdmi_data = page_en & app_enr ? {o_data[23:19],o_data[15:10],o_data[4:0]} : isp_data;

// sdr_as_ram  #( .self_refresh_open(1'b1))
// 	u2_ram( 
// 		.Sdr_clk(clk),
// 		.Sdr_clk_sft(clk_ref),
// 		.Rst(~rstn),                            //高有效
// 		.Sdr_init_done(sdr_init_done),
// 		.Sdr_init_ref_vld(sdr_init_ref_vld),    //sdram刷新状态,读写前先判断该信号的状态
// 		.Sdr_busy(sdr_busy),                    //sdram忙状态暂不使用
		
// 		.App_ref_req(1'b0),
		
//         .App_wr_en  (App_wr_en  ), 
//         .App_wr_addr(App_wr_addr),  	
// 		.App_wr_dm  (App_wr_dm  ),
// 		.App_wr_din (App_wr_din ),

// 		.App_rd_en  (App_rd_en  ),
// 		.App_rd_addr(App_rd_addr),
// 		.Sdr_rd_en	(Sdr_rd_en  ),
// 		.Sdr_rd_dout(Sdr_rd_dout),
	
// 		.SDRAM_CLK(SDRAM_CLK),
// 		.SDR_RAS(SDR_RAS),
// 		.SDR_CAS(SDR_CAS),
// 		.SDR_WE(SDR_WE),
// 		.SDR_BA(SDR_BA),
// 		.SDR_ADDR(SDR_ADDR),
// 		.SDR_DM(SDR_DM),
// 		.SDR_DQ(SDR_DQ)	
// 	);


// assign SDR_CKE=1'b1;

// 	EG_PHY_SDRAM_2M_32 sdram(
// 		.clk(SDRAM_CLK),
// 		.ras_n(SDR_RAS),
// 		.cas_n(SDR_CAS),
// 		.we_n(SDR_WE),
// 		.addr(SDR_ADDR[10:0]),
// 		.ba(SDR_BA),
// 		.dq(SDR_DQ),
// 		.cs_n(1'b0),
// 		.dm0(SDR_DM[0]),
// 		.dm1(SDR_DM[1]),
// 		.dm2(SDR_DM[2]),
// 		.dm3(SDR_DM[3]),
// 		.cke(1'b1)
// 		);

endmodule //page

