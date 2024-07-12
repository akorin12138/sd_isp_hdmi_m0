module CortexM0_SoC (
        input  wire  sysclk,
        input  wire  RSTn,
        inout  wire  SWDIO,  
        input  wire  SWCLK,
        output wire  TXD,	    //串口1
        input  wire  RXD,
        inout  wire [7:0] ioPin,

        output  wire [3:0] 	key_row,
        input   wire [3:0] 	key_col,

        //SDCARD
        inout   wire    [3:0]   sd_dat      ,  
        output  wire            sd_clk      ,  
        inout   wire            sd_cmd      ,  
        //SDRAM
        output  wire            sdram_clk   ,  //SDRAM 芯片时钟
        output  wire            sdram_cke   ,  //SDRAM 时钟有效
        output  wire            sdram_cs_n  ,  //SDRAM 片选
        output  wire            sdram_ras_n ,  //SDRAM 行有效
        output  wire            sdram_cas_n ,  //SDRAM 列有效
        output  wire            sdram_we_n  ,  //SDRAM 写有效
        output  wire    [1:0]   sdram_ba    ,  //SDRAM Bank地址
        output  wire    [1:0]   sdram_dqm   ,  //SDRAM 数据掩码
        output  wire    [11:0]  sdram_addr  ,  //SDRAM 行/列地址
        inout   wire    [15:0]  sdram_data    ,  //SDRAM 数据
        
        //HDMI
        output			HDMI_CLK_P,
        output			HDMI_D2_P,
        output			HDMI_D1_P,
        output			HDMI_D0_P	

);

wire clk;
parameter  H_VALID  =   24'd1936 ;   //行有效数据
parameter  V_VALID  =   24'd1088 ;   //列有效数据
    
//rst_n
wire rst_n;
//clk
wire clk25m;
wire hdmi_clk_5;    
wire hdmi_clk,locked;
(* MAX_FANOUT = 50 *)wire sdram_clk_100m;
wire sdram_clk_100m_shift;
wire locked1;
wire locked2;
wire sdcard_clk;
//sdcard
wire            sd_rd_data_en   ;  
wire    [15:0]  sd_rd_data      ;  
//sdram_ctrl
wire            sdram_wr_en           ;   
wire    [15:0]  sdram_wr_data         ;   
wire            sdram_rd_en           ;   
wire    [15:0]  sdram_rd_data         ;   
wire            sdram_init_end  ;  //SDRAM初始化完成
reg             sdram_shift_wr_en        ;//0:sdram1;1:sdram2
reg             sdram_shift_rd_en        ;//0:sdram1;1:sdram2
reg            sdram1_wr_en           ;  
reg            sdram2_wr_en           ;  
reg             sdram1_rd_en           ; 
reg             sdram2_rd_en           ; 
reg     [15:0]  sdram1_wr_data         ; 
reg     [15:0]  sdram2_wr_data         ; 
wire    [15:0]  sdram1_rd_data         ; 
wire    [15:0]  sdram2_rd_data         ; 
 //VGA
wire			VGA_HS;    
wire			VGA_VS;    
wire			VGA_DE;    
wire [4:0]	VGA_R;		
wire [5:0]	VGA_G;		
wire [4:0]	VGA_B;	
reg [15:0] VGA_RGB;	
	
wire [23:0]   post_isp_data0;  
wire          post_isp_data0_en;  
wire [23:0]   post_isp_data1;  
wire          post_isp_data1_en;  
wire [23:0]   post_win_data;  
wire          post_win_data_en;  

wire          swck;

wire rgb_clk;//synthesis keep = 1
wire yuv_clk;//synthesis keep = 1
wire raw_clk;//synthesis keep = 1
wire mux_clk;//synthesis keep = 1
// wire isp_100m;
// (* MAX_FANOUT = 50 *)wire isp_clk;
assign rst_n = RSTn & locked & locked1 & locked2;
/*****************************************/
/*时钟例化*/
/*****************************************/
tx_pll u_tx_pll(
		.refclk     (sysclk),
		.reset      (!RSTn),
		.extlock    (locked),
		.clk1_out   (hdmi_clk),
		.clk2_out   (hdmi_clk_5)
	);
sd_pll u_sd_pll(
		.refclk     (sysclk),
		.reset      (!RSTn),
		.extlock    (locked1),
		.clk0_out   (sdcard_clk),  //100m
		.clk1_out   (raw_clk ),//100m
		.clk2_out   (mux_clk ),//100m
		.clk3_out   (rgb_clk ),//100m
		.clk4_out   (yuv_clk )//100m
);
pll_gen u_pll_gen(
    .refclk     ( sysclk               ),
    .reset      ( !RSTn            ),
    .extlock    ( locked2               ),
    .clk0_out   ( sdram_clk_100m        ),
    .clk1_out   ( sdram_clk_100m_shift  )
);
// BUFG u_BUFG0(
//     .i ( isp_100m),
//     .o ( isp_clk )
// );
BUFG u_BUFG1(
    .i ( SWCLK),
    .o ( swck )
);





// pll u_pll(
//     .refclk     ( sysclk),
//     .reset      ( 1'b0),
//     .clk0_out   ( clk)
// );

assign clk = sysclk;

//------------------------------------------------------------------------------
// DEBUG IOBUF 
//------------------------------------------------------------------------------

wire SWDO;
wire SWDOEN;
wire SWDI;

assign SWDI = SWDIO;
assign SWDIO = (SWDOEN) ?  SWDO : 1'bz;

//------------------------------------------------------------------------------
// Interrupt
//------------------------------------------------------------------------------

wire [31:0] IRQ;
wire interrupt_UART;
wire key_interrupt;
wire showinterrupt;
wire sdinterrupt_en;
assign IRQ = {29'b0,interrupt_UART,key_interrupt,showinterrupt};

wire RXEV;
assign RXEV = 1'b0;

//------------------------------------------------------------------------------
// AHB
//------------------------------------------------------------------------------

wire [31:0] HADDR;
wire [ 2:0] HBURST;
wire        HMASTLOCK;
wire [ 3:0] HPROT;
wire [ 2:0] HSIZE;
wire [ 1:0] HTRANS;
wire [31:0] HWDATA;
wire        HWRITE;
wire [31:0] HRDATA;
wire        HRESP;
wire        HMASTER;
wire        HREADY;

//------------------------------------------------------------------------------
// RESET AND DEBUG
//------------------------------------------------------------------------------

wire SYSRESETREQ;
reg cpuresetn;



always @(posedge clk or negedge RSTn)begin
        if (~RSTn) cpuresetn <= 1'b0;
        else if (SYSRESETREQ) cpuresetn <= 1'b0;
        else cpuresetn <= 1'b1;
end

wire CDBGPWRUPREQ;
reg CDBGPWRUPACK;

always @(posedge clk or negedge RSTn)begin
        if (~RSTn) CDBGPWRUPACK <= 1'b0;
        else CDBGPWRUPACK <= CDBGPWRUPREQ;
end

//------------------------------------------------------------------------------
// RESET AND DEBUG
//------------------------------------------------------------------------------
// wire ChipWatcherClk/*synthesis keep=1*/;
// pll upll(
//     .refclk     (clk             ),
//     .clk0_out   (ChipWatcherClk  )
// );

//------------------------------------------------------------------------------
// Instantiate Cortex-M0 processor logic level
//------------------------------------------------------------------------------

cortexm0ds_logic u_logic (

        // System inputs
        .FCLK           (clk),           //FREE running clock 
        .SCLK           (clk),           //system clock
        .HCLK           (clk),           //AHB clock
        .DCLK           (clk),           //Debug clock
        .PORESETn       (RSTn),          //Power on reset
        .HRESETn        (cpuresetn),     //AHB and System reset
        .DBGRESETn      (RSTn),          //Debug Reset
        .RSTBYPASS      (1'b0),          //Reset bypass
        .SE             (1'b0),          // dummy scan enable port for synthesis

        // Power management inputs
        .SLEEPHOLDREQn  (1'b1),          // Sleep extension request from PMU
        .WICENREQ       (1'b0),          // WIC enable request from PMU
        .CDBGPWRUPACK   (CDBGPWRUPACK),  // Debug Power Up ACK from PMU

        // Power management outputs
        .CDBGPWRUPREQ   (CDBGPWRUPREQ),
        .SYSRESETREQ    (SYSRESETREQ),

        // System bus
        .HADDR          (HADDR[31:0]),
        .HTRANS         (HTRANS[1:0]),
        .HSIZE          (HSIZE[2:0]),
        .HBURST         (HBURST[2:0]),
        .HPROT          (HPROT[3:0]),
        .HMASTER        (HMASTER),
        .HMASTLOCK      (HMASTLOCK),
        .HWRITE         (HWRITE),
        .HWDATA         (HWDATA[31:0]),
        .HRDATA         (HRDATA[31:0]),
        .HREADY         (HREADY),
        .HRESP          (HRESP),

        // Interrupts
        .IRQ            (IRQ),          //Interrupt
        .NMI            (1'b0),         //Watch dog interrupt
        .IRQLATENCY     (8'h0),
        .ECOREVNUM      (28'h0),

        // Systick
        .STCLKEN        (1'b0),
        .STCALIB        (26'h0),

        // Debug - JTAG or Serial wire
        // Inputs
        .nTRST          (1'b1),
        .SWDITMS        (SWDI),
        .SWCLKTCK       (swck),
        .TDI            (1'b0),
        // Outputs
        .SWDO           (SWDO),
        .SWDOEN         (SWDOEN),

        .DBGRESTART     (1'b0),

        // Event communication
        .RXEV           (RXEV),         // Generate event when a DMA operation completed.
        .EDBGRQ         (1'b0)          // multi-core synchronous halt request
);

//------------------------------------------------------------------------------
// AHBlite Interconncet
//------------------------------------------------------------------------------

wire            HSEL_P0;
wire    [31:0]  HADDR_P0;
wire    [2:0]   HBURST_P0;
wire            HMASTLOCK_P0;
wire    [3:0]   HPROT_P0;
wire    [2:0]   HSIZE_P0;
wire    [1:0]   HTRANS_P0;
wire    [31:0]  HWDATA_P0;
wire            HWRITE_P0;
wire            HREADY_P0;
wire            HREADYOUT_P0;
wire    [31:0]  HRDATA_P0;
wire            HRESP_P0;

wire            HSEL_P1;
wire    [31:0]  HADDR_P1;
wire    [2:0]   HBURST_P1;
wire            HMASTLOCK_P1;
wire    [3:0]   HPROT_P1;
wire    [2:0]   HSIZE_P1;
wire    [1:0]   HTRANS_P1;
wire    [31:0]  HWDATA_P1;
wire            HWRITE_P1;
wire            HREADY_P1;
wire            HREADYOUT_P1;
wire    [31:0]  HRDATA_P1;
wire            HRESP_P1;

wire            HSEL_P2;
wire    [31:0]  HADDR_P2;
wire    [2:0]   HBURST_P2;
wire            HMASTLOCK_P2;
wire    [3:0]   HPROT_P2;
wire    [2:0]   HSIZE_P2;
wire    [1:0]   HTRANS_P2;
wire    [31:0]  HWDATA_P2;
wire            HWRITE_P2;
wire            HREADY_P2;
wire            HREADYOUT_P2;
wire    [31:0]  HRDATA_P2;
wire            HRESP_P2;

wire            HSEL_P3;
wire    [31:0]  HADDR_P3;
wire    [2:0]   HBURST_P3;
wire            HMASTLOCK_P3;
wire    [3:0]   HPROT_P3;
wire    [2:0]   HSIZE_P3;
wire    [1:0]   HTRANS_P3;
wire    [31:0]  HWDATA_P3;
wire            HWRITE_P3;
wire            HREADY_P3;
wire            HREADYOUT_P3;
wire    [31:0]  HRDATA_P3;
wire            HRESP_P3;

wire            HSEL_P4;
wire    [31:0]  HADDR_P4;
wire    [2:0]   HBURST_P4;
wire            HMASTLOCK_P4;
wire    [3:0]   HPROT_P4;
wire    [2:0]   HSIZE_P4;
wire    [1:0]   HTRANS_P4;
wire    [31:0]  HWDATA_P4;
wire            HWRITE_P4;
wire            HREADY_P4;
wire            HREADYOUT_P4;
wire    [31:0]  HRDATA_P4;
wire            HRESP_P4;

wire            HSEL_P5;
wire    [31:0]  HADDR_P5;
wire    [2:0]   HBURST_P5;
wire            HMASTLOCK_P5;
wire    [3:0]   HPROT_P5;
wire    [2:0]   HSIZE_P5;
wire    [1:0]   HTRANS_P5;
wire    [31:0]  HWDATA_P5;
wire            HWRITE_P5;
wire            HREADY_P5;
wire            HREADYOUT_P5;
wire    [31:0]  HRDATA_P5;
wire            HRESP_P5;

wire            HSEL_P6;
wire    [31:0]  HADDR_P6;
wire    [2:0]   HBURST_P6;
wire            HMASTLOCK_P6;
wire    [3:0]   HPROT_P6;
wire    [2:0]   HSIZE_P6;
wire    [1:0]   HTRANS_P6;
wire    [31:0]  HWDATA_P6;
wire            HWRITE_P6;
wire            HREADY_P6;
wire            HREADYOUT_P6;
wire    [31:0]  HRDATA_P6;
wire            HRESP_P6;

AHBlite_Interconnect Interconncet(
        .HCLK           (clk),
        .HRESETn        (cpuresetn),

        // CORE SIDE
        .HADDR          (HADDR),
        .HTRANS         (HTRANS),
        .HSIZE          (HSIZE),
        .HBURST         (HBURST),
        .HPROT          (HPROT),
        .HMASTLOCK      (HMASTLOCK),
        .HWRITE         (HWRITE),
        .HWDATA         (HWDATA),
        .HRDATA         (HRDATA),
        .HREADY         (HREADY),
        .HRESP          (HRESP),

        // P0
        .HSEL_P0        (HSEL_P0),
        .HADDR_P0       (HADDR_P0),
        .HBURST_P0      (HBURST_P0),
        .HMASTLOCK_P0   (HMASTLOCK_P0),
        .HPROT_P0       (HPROT_P0),
        .HSIZE_P0       (HSIZE_P0),
        .HTRANS_P0      (HTRANS_P0),
        .HWDATA_P0      (HWDATA_P0),
        .HWRITE_P0      (HWRITE_P0),
        .HREADY_P0      (HREADY_P0),
        .HREADYOUT_P0   (HREADYOUT_P0),
        .HRDATA_P0      (HRDATA_P0),
        .HRESP_P0       (HRESP_P0),

        // P1
        .HSEL_P1        (HSEL_P1),
        .HADDR_P1       (HADDR_P1),
        .HBURST_P1      (HBURST_P1),
        .HMASTLOCK_P1   (HMASTLOCK_P1),
        .HPROT_P1       (HPROT_P1),
        .HSIZE_P1       (HSIZE_P1),
        .HTRANS_P1      (HTRANS_P1),
        .HWDATA_P1      (HWDATA_P1),
        .HWRITE_P1      (HWRITE_P1),
        .HREADY_P1      (HREADY_P1),
        .HREADYOUT_P1   (HREADYOUT_P1),
        .HRDATA_P1      (HRDATA_P1),
        .HRESP_P1       (HRESP_P1),

        // P2
        .HSEL_P2        (HSEL_P2),
        .HADDR_P2       (HADDR_P2),
        .HBURST_P2      (HBURST_P2),
        .HMASTLOCK_P2   (HMASTLOCK_P2),
        .HPROT_P2       (HPROT_P2),
        .HSIZE_P2       (HSIZE_P2),
        .HTRANS_P2      (HTRANS_P2),
        .HWDATA_P2      (HWDATA_P2),
        .HWRITE_P2      (HWRITE_P2),
        .HREADY_P2      (HREADY_P2),
        .HREADYOUT_P2   (HREADYOUT_P2),
        .HRDATA_P2      (HRDATA_P2),
        .HRESP_P2       (HRESP_P2),

        // P3
        .HSEL_P3        (HSEL_P3),
        .HADDR_P3       (HADDR_P3),
        .HBURST_P3      (HBURST_P3),
        .HMASTLOCK_P3   (HMASTLOCK_P3),
        .HPROT_P3       (HPROT_P3),
        .HSIZE_P3       (HSIZE_P3),
        .HTRANS_P3      (HTRANS_P3),
        .HWDATA_P3      (HWDATA_P3),
        .HWRITE_P3      (HWRITE_P3),
        .HREADY_P3      (HREADY_P3),
        .HREADYOUT_P3   (HREADYOUT_P3),
        .HRDATA_P3      (HRDATA_P3),
        .HRESP_P3       (HRESP_P3),

        // P4
        .HSEL_P4        (HSEL_P4),
        .HADDR_P4       (HADDR_P4),
        .HBURST_P4      (HBURST_P4),
        .HMASTLOCK_P4   (HMASTLOCK_P4),
        .HPROT_P4       (HPROT_P4),
        .HSIZE_P4       (HSIZE_P4),
        .HTRANS_P4      (HTRANS_P4),
        .HWDATA_P4      (HWDATA_P4),
        .HWRITE_P4      (HWRITE_P4),
        .HREADY_P4      (HREADY_P4),
        .HREADYOUT_P4   (HREADYOUT_P4),
        .HRDATA_P4      (HRDATA_P4),
        .HRESP_P4       (HRESP_P4),

        // P5
        .HSEL_P5        (HSEL_P5),
        .HADDR_P5       (HADDR_P5),
        .HBURST_P5      (HBURST_P5),
        .HMASTLOCK_P5   (HMASTLOCK_P5),
        .HPROT_P5       (HPROT_P5),
        .HSIZE_P5       (HSIZE_P5),
        .HTRANS_P5      (HTRANS_P5),
        .HWDATA_P5      (HWDATA_P5),
        .HWRITE_P5      (HWRITE_P5),
        .HREADY_P5      (HREADY_P5),
        .HREADYOUT_P5   (HREADYOUT_P5),
        .HRDATA_P5      (HRDATA_P5),
        .HRESP_P5       (HRESP_P5),

        // P6
        .HSEL_P6        (HSEL_P6),
        .HADDR_P6       (HADDR_P6),
        .HBURST_P6      (HBURST_P6),
        .HMASTLOCK_P6   (HMASTLOCK_P6),
        .HPROT_P6       (HPROT_P6),
        .HSIZE_P6       (HSIZE_P6),
        .HTRANS_P6      (HTRANS_P6),
        .HWDATA_P6      (HWDATA_P6),
        .HWRITE_P6      (HWRITE_P6),
        .HREADY_P6      (HREADY_P6),
        .HREADYOUT_P6   (HREADYOUT_P6),
        .HRDATA_P6      (HRDATA_P6),
        .HRESP_P6       (HRESP_P6)
);

//------------------------------------------------------------------------------
// AHB RAMCODE
//------------------------------------------------------------------------------

wire [31:0] RAMCODE_RDATA,RAMCODE_WDATA;
wire [13:0] RAMCODE_WADDR;
wire [13:0] RAMCODE_RADDR;
wire [3:0]  RAMCODE_WRITE;

AHBlite_Block_RAM RAMCODE_Interface(
        /* Connect to Interconnect Port 0 */
        .HCLK           (clk),
        .HRESETn        (cpuresetn),
        .HSEL           (HSEL_P0     ),
        .HADDR          (HADDR_P0    ),
        .HPROT          (HPROT_P0    ),
        .HSIZE          (HSIZE_P0    ),
        .HTRANS         (HTRANS_P0   ),
        .HWDATA         (HWDATA_P0   ),
        .HWRITE         (HWRITE_P0   ),
        .HRDATA         (HRDATA_P0   ),
        .HREADY         (HREADY_P0   ),
        .HREADYOUT      (HREADYOUT_P0),
        .HRESP          (HRESP_P0    ),
        .BRAM_WRADDR    (RAMCODE_WADDR),
        .BRAM_RDADDR    (RAMCODE_RADDR),
        .BRAM_RDATA     (RAMCODE_RDATA),
        .BRAM_WDATA     (RAMCODE_WDATA),
        .BRAM_WRITE     (RAMCODE_WRITE)
        /**********************************/
);

//------------------------------------------------------------------------------
// AHB KEY
//------------------------------------------------------------------------------
wire [3:0] key_val;

AHblite_key u_AHblite_key(
    .HCLK      	( clk           ),
    .HRESETn   	( cpuresetn     ),
    .HSEL      	( HSEL_P2       ),
    .HADDR     	( HADDR_P2      ),
    .HTRANS    	( HTRANS_P2     ),
    .HSIZE     	( HSIZE_P2      ),
    .HPROT     	( HPROT_P2      ),
    .HWRITE    	( HWRITE_P2     ),
    .HWDATA    	( HWDATA_P2     ),
    .HREADY    	( HREADY_P2     ),
    .HREADYOUT  ( HREADYOUT_P2  ),
    .HRDATA     ( HRDATA_P2     ),
    .HRESP     	( HRESP_P2      ),
    .key_data   ( key_val       )
);


//------------------------------------------------------------------------------
// AHB RAMDATA
//------------------------------------------------------------------------------

wire [31:0] RAMDATA_RDATA;
wire [31:0] RAMDATA_WDATA;
wire [13:0] RAMDATA_WADDR;
wire [13:0] RAMDATA_RADDR;
wire [3:0]  RAMDATA_WRITE;

AHBlite_Block_RAM RAMDATA_Interface(
        /* Connect to Interconnect Port 0 */
        .HCLK           (clk),
        .HRESETn        (cpuresetn),
        .HSEL           (HSEL_P1     ),
        .HADDR          (HADDR_P1    ),
        .HPROT          (HPROT_P1    ),
        .HSIZE          (HSIZE_P1    ),
        .HTRANS         (HTRANS_P1   ),
        .HWDATA         (HWDATA_P1   ),
        .HWRITE         (HWRITE_P1   ),
        .HRDATA         (HRDATA_P1   ),
        .HREADY         (HREADY_P1   ),
        .HREADYOUT      (HREADYOUT_P1),
        .HRESP          (HRESP_P1    ),
        .BRAM_WRADDR    (RAMDATA_WADDR),
        .BRAM_RDADDR    (RAMDATA_RADDR),
        .BRAM_RDATA     (RAMDATA_RDATA),
        .BRAM_WDATA     (RAMDATA_WDATA),
        .BRAM_WRITE     (RAMDATA_WRITE)
        /**********************************/
);

//------------------------------------------------------------------------------
// AHB UART
//------------------------------------------------------------------------------

wire state;
wire [7:0] UART_RX_data;
wire [7:0] UART_TX_data;
wire tx_en;
AHBlite_UART UART_Interface(
        .HCLK           (clk         ),
        .HRESETn        (cpuresetn   ),
        .HSEL           (HSEL_P3     ),
        .HADDR          (HADDR_P3    ),
        .HPROT          (HPROT_P3    ),
        .HSIZE          (HSIZE_P3    ),
        .HTRANS         (HTRANS_P3   ),
        .HWDATA         (HWDATA_P3   ),
        .HWRITE         (HWRITE_P3   ),
        .HRDATA         (HRDATA_P3   ),
        .HREADY         (HREADY_P3   ),
        .HREADYOUT      (HREADYOUT_P3),
        .HRESP          (HRESP_P3    ),
        .UART_RX        (UART_RX_data),
        .state          (state       ),
        .tx_en          (tx_en       ),
        .UART_TX        (UART_TX_data)
);
//------------------------------------------------------------------------------
// AHB GPIO
//------------------------------------------------------------------------------

wire [7:0] oData;
wire [7:0] iData;
wire outEn;

AHBlite_GPIO GPIO_Interface(
        /* Connect to Interconnect Port 4 */
        .HCLK			(clk            ),
        .HRESETn		(cpuresetn      ),
        .HSEL			(HSEL_P4	 ),
        .HADDR			(HADDR_P4	 ),
        .HPROT			(HPROT_P4	 ),
        .HSIZE			(HSIZE_P4	 ),
        .HTRANS			(HTRANS_P4	 ),
        .HWDATA		        (HWDATA_P4	 ),
        .HWRITE			(HWRITE_P4	 ),
        .HRDATA			(HRDATA_P4	 ),
        .HREADY			(HREADY_P4	 ),
        .HREADYOUT		(HREADYOUT_P4    ),
        .HRESP			(HRESP_P4 	 ),
        .outEn                  (outEn          ),
        .oData                  (oData          ),
        .iData                  (iData          )

        /**********************************/ 
);

//------------------------------------------------------------------------------
// AHB SDCARD
//------------------------------------------------------------------------------
wire            sd_rd_en;
wire            sd_state;
wire   [31:0]   startADDRESS;
AHBlite_Sdcard u_AHBlite_Sdcard(
        .HCLK		( clk                   ),
        .HRESETn	( cpuresetn             ),
        .HSEL		( HSEL_P5               ),
        .HADDR		( HADDR_P5              ),
        .HPROT		( HPROT_P5              ),
        .HSIZE		( HSIZE_P5              ),
        .HTRANS		( HTRANS_P5             ),
        .HWDATA		( HWDATA_P5             ),
        .HWRITE		( HWRITE_P5             ),
        .HRDATA		( HRDATA_P5             ),
        .HREADY		( HREADY_P5             ),
        .HREADYOUT	( HREADYOUT_P5          ),
        .HRESP		( HRESP_P5              ),
        .sd_rd_en     	( sd_rd_en              ),
        .startADDRESS 	( startADDRESS          ),
        .sd_state    	( sd_state              ),
        .interrupt_en 	( sdinterrupt_en        )
);


//------------------------------------------------------------------------------
// AHB ISP
//------------------------------------------------------------------------------
wire [31:0]   isp_data_num0to7;//synthesis keep = 1
wire [31:0]   isp_data_num8to15;//synthesis keep = 1
wire          isp_ctrl_en;
wire [10:0]   split_x;
wire [10:0]   split_y;
AHBlite_ISP u_AHBlite_ISP(
        .HCLK		        ( clk                   ),
        .HRESETn	        ( cpuresetn             ),
        .HSEL		        ( HSEL_P6               ),
        .HADDR		        ( HADDR_P6              ),
        .HPROT		        ( HPROT_P6              ),
        .HSIZE		        ( HSIZE_P6              ),
        .HTRANS		        ( HTRANS_P6             ),
        .HWDATA		        ( HWDATA_P6             ),
        .HWRITE		        ( HWRITE_P6             ),
        .HRDATA		        ( HRDATA_P6             ),
        .HREADY		        ( HREADY_P6             ),
        .HREADYOUT	        ( HREADYOUT_P6          ),
        .HRESP		        ( HRESP_P5              ),
        .isp_data_num0to7  	( isp_data_num0to7      ),
        .isp_data_num8to15  	( isp_data_num8to15     ),
        .isp_ctrl_en            ( isp_ctrl_en           ),
        .split_x                ( split_x               ),
        .split_y                ( split_y               )
        
);



//------------------------------------------------------------------------------
// ROM
//------------------------------------------------------------------------------

Block_RAM RAM_CODE(
        .clka           (clk),
        .addra          (RAMCODE_WADDR),
        .addrb          (RAMCODE_RADDR),
        .dina           (RAMCODE_WDATA),
        .doutb          (RAMCODE_RDATA),
        .wea            (RAMCODE_WRITE)
);

//------------------------------------------------------------------------------
// RAM
//------------------------------------------------------------------------------

Block_RAM RAM_DATA(
        .clka           (clk),
        .addra          (RAMDATA_WADDR),
        .addrb          (RAMDATA_RADDR),
        .dina           (RAMDATA_WDATA),
        .doutb          (RAMDATA_RDATA),
        .wea            (RAMDATA_WRITE)
);

//------------------------------------------------------------------------------
// KEY
//------------------------------------------------------------------------------


Keyboard u_Keyboard(
        .HCLK    	( clk           ),
        .HRESETn 	( cpuresetn     ),
        .key_col 	( key_col       ),
        .key_row 	( key_row       ),
        .key_val 	( key_val       ),
        .key_it  	( key_interrupt )
);


//------------------------------------------------------------------------------
// UART
//------------------------------------------------------------------------------

wire clk_uart;
wire bps_en;
wire bps_en_rx,bps_en_tx;

assign bps_en = bps_en_rx | bps_en_tx;

clkuart_pwm #(
    .BPS_PARA (50000000/115200)
)clkuart_pwm(
        .clk(clk),
        .RSTn(cpuresetn),
        .clk_uart(clk_uart),
        .bps_en(bps_en)
);

UART_RX UART_RX(
        .clk(clk),
        .clk_uart(clk_uart),
        .RSTn(cpuresetn),
        .RXD(RXD),
        .data(UART_RX_data),
        .interrupt(interrupt_UART),
        .bps_en(bps_en_rx)
);

UART_TX UART_TX(
        .clk(clk),
        .clk_uart(clk_uart),
        .RSTn(cpuresetn),
        .data(UART_TX_data),
        .tx_en(tx_en),
        .TXD(TXD),
        .state(state),
        .bps_en(bps_en_tx)
);

//------------------------------------------------------------------------------
// GPIO
//------------------------------------------------------------------------------

GPIO GPIO(
        .outEn(outEn),
        .oData(oData),
        .iData(iData),
        .clk(clk),
        .RSTn(cpuresetn),
        .ioPin(ioPin)
);

//------------------------------------------------------------------------------
// SDcard+SDRAM
//------------------------------------------------------------------------------

sd_top
#(
    .H_VALID(H_VALID),
    .V_VALID(V_VALID)
) u_sd_top
(
    .clk                (sdcard_clk     ),
    .rst_n              (rst_n & sdram_init_end        ),
    .sd_done_pos        ( showinterrupt ),
    .sd_block_addr      ( startADDRESS  ),      //addr与rd_en同一周期
    .sd_state           ( sd_state      ),      //addr与rd_en同一周期
    .sd_clk             (sd_clk         ),
    .sd_cmd             (sd_cmd         ),
    .sd_dat             (sd_dat         ),
    .sd_ren             (sd_rd_en       ),      //读取一整个视频
    .sd_img_data        (sd_rd_data     ),
    .sd_img_data_en     (sd_rd_data_en  )       //取窗后的数据
    
);

sdram_top u_sdram_top
(
    .sys_clk                (sdram_clk_100m),             // sdram 控制器参考时钟
    .clk_out                (sdram_clk_100m_shift),       // 用于输出的相位偏移时钟
    .sys_rst_n              (rst_n),      // 系统复位，低电平有效

    //用户写端口
    .wr_fifo_wr_clk         (raw_clk),          // 写端口FIFO: 写时钟
    .wr_fifo_wr_req         (sdram_wr_en ),          // 写端口FIFO: 写使能
    .wr_fifo_wr_data        (sdram_wr_data),        // 写端口FIFO: 写数据
    .sdram_wr_b_addr        (23'd0),                // 写SDRAM的起始地址
    .sdram_wr_e_addr        (1920*1080-1),          // 写SDRAM的结束地址
    .wr_burst_len           (10'd512),              // 写SDRAM时的数据突发长度
    .wr_rst                 (~rst_n),         // 写端口复位: 复位写地址,清空写FIFO
    //所有图片写入sdram完成，拉高sdram写端口复位，锁定端口

    //用户读端口
    .rd_fifo_rd_clk         (hdmi_clk),             // 读端口FIFO: 读时钟
    .rd_fifo_rd_req         (VGA_DE),           // 读端口FIFO: 读使能
    .sdram_rd_b_addr        (24'd0),      // 读SDRAM的起始地址
    .sdram_rd_e_addr        (1920*1080-1),      // 读SDRAM的结束地址
    .rd_burst_len           (10'd512),              // 从SDRAM中读数据时的突发长度
    .rd_rst                 (~rst_n),         // 读端口复位: 复位读地址,清空读FIFO
    .rd_fifo_rd_data        (sdram_rd_data),        // 读端口FIFO: 读数据

     //用户控制端口
    .read_valid             (1'b1),                 // SDRAM 读使能
    .init_end               (sdram_init_end),      // SDRAM 初始化完成标志

    //SDRAM 芯片接口
    .sdram_clk              (sdram_clk),            // SDRAM 芯片时钟
    .sdram_cke              (sdram_cke),            // SDRAM 时钟有效
    .sdram_cs_n             (sdram_cs_n),           // SDRAM 片选
    .sdram_ras_n            (sdram_ras_n),          // SDRAM 行有效
    .sdram_cas_n            (sdram_cas_n),          // SDRAM 列有效
    .sdram_we_n             (sdram_we_n),           // SDRAM 写有效
    .sdram_ba               (sdram_ba),             // SDRAM Bank地址
    .sdram_addr             (sdram_addr),           // SDRAM 行/列地址
    .sdram_dq               (sdram_data),            // SDRAM 数据
    .sdram_dqm              (sdram_dqm)          
); 
hdmi_top u_hdmi_top
(
    .hdmi_clk       (hdmi_clk                   ),
    .hdmi_5clk      (hdmi_clk_5                 ),
    .sys_rst_n      (rst_n  & sdram_init_end   ),
    // 用户接口
    .lcd_data       (sdram_rd_data),
    .second_rden    (),
    .first_rden     (),
    .lcd_xpos       (lcd_xpos),     //像素点横坐标
    .lcd_ypos       (lcd_ypos),     //像素点纵坐标
    .hcnt           (hcnt),
    .vcnt           (vcnt),
    .all_ack        (VGA_DE               ),
    // HDMI接口
    .tmds_clk_p     (HDMI_CLK_P                 ),   //TMDS 时钟通道
    .tmds_clk_n     (                 ),
    .tmds_data_p    ({HDMI_D2_P,HDMI_D1_P,HDMI_D0_P}                ),  //TMDS 数据通道
    .tmds_data_n    (                )
);	

ispMUX u_ispMUX(
    .rgb_clk          	( rgb_clk           ),
    .raw_clk          	( raw_clk           ),
    .yuv_clk          	( yuv_clk           ),
    .mux_clk          	( mux_clk           ),
    .rst_n            	( rst_n             ),
    .per_sd_data      	( sd_rd_data        ),
    .per_sd_data_en   	( sd_rd_data_en     ),
    .post_isp_data0    	( post_isp_data0    ),
    .post_isp_data_en0 	( post_isp_data0_en ),
    .post_isp_data1    	( post_isp_data1    ),
    .post_isp_data_en1	( post_isp_data1_en ),
//     .isp_data_num0to7   ( 32'h00130000 ),
//     .isp_data_num8to15  ( 32'h00000040 )
    .isp_data_num0to7  	( isp_data_num0to7  ),
    .isp_data_num8to15  ( isp_data_num8to15 )
);

parameter  HDMI_HPIXEL      = 12'd1920;
parameter  HDMI_VPIXEL      = 12'd1080;

// window #(
//     .WIN_X  	( 11'd4  ),
//     .WIN_Y  	( 11'd8  ),
//     .WIDTH  	( 11'd1936 ),
//     .HEIGHT 	( 11'd1088 ),
//     .HDMI_HPIXEL( HDMI_HPIXEL),
//     .HDMI_VPIXEL( HDMI_VPIXEL)
// )u_window(
//     .clk           	( mux_clk           ),
//     .rstn          	( rst_n             ),
//     .win_data_en   	( post_isp_data_en  ),
//     .win_data      	( post_isp_data     ),//24bit
//     .sdram_data_en 	( sdram_wr_en       ),
//     .sdram_data    	( sdram_wr_data     ) //16bit
// );

window_split #(
    .WIN_X       	( 8     ),
    .WIN_Y       	( 4     ),
    .WIDTH       	( 1936  ),
    .HEIGHT      	( 1088  ),
    .HDMI_HPIXEL 	( 1920  ),
    .HDMI_VPIXEL 	( 1080  )
)u_window_split(
    .clk           	( mux_clk             ),
    .rstn          	( rst_n               ),
    .win_data_en0  	( post_isp_data0_en   ),
    .win_data_en1  	( post_isp_data1_en   ),
    .win_data0     	( post_isp_data0      ),
    .win_data1     	( post_isp_data1      ),
    .split_en           ( isp_ctrl_en         ),
    .sdram_data_en 	( sdram_wr_en         ),
    .split_x            ( 8             ),
    .split_y            ( 4             ),
    .sdram_data    	( sdram_wr_data       )
);


endmodule
