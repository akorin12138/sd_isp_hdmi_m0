module AHBlite_Sdcard(
    input  wire          HCLK,    
    input  wire          HRESETn, 
    input  wire          HSEL,    
    input  wire   [31:0] HADDR,   
    input  wire    [1:0] HTRANS,  
    input  wire    [2:0] HSIZE,   
    input  wire    [3:0] HPROT,   
    input  wire          HWRITE,  
    input  wire   [31:0] HWDATA,  
    input  wire          HREADY,  
    output wire          HREADYOUT, 
    output wire   [31:0] HRDATA,  
    output wire          HRESP,

    output reg           sd_rd_en,
    output reg    [31:0] startADDRESS,
    input  wire          sd_state,
    output reg           interrupt_en
);

assign HRESP = 1'b0;
assign HREADYOUT = 1'b1;

wire write_en;
assign write_en = HSEL & HTRANS[1] & HWRITE & HREADY;

wire read_en;
assign read_en=HSEL&HTRANS[1]&(~HWRITE)&HREADY;

reg [3:0] addr_reg;
always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) addr_reg <= 4'h0;
  else if(read_en || write_en) addr_reg <= HADDR[3:0];
end

reg rd_en_reg;
always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) rd_en_reg <= 1'b0;
  else if(read_en) rd_en_reg <= 1'b1;
  else rd_en_reg <= 1'b0;
end

reg wr_en_reg;
always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) wr_en_reg <= 1'b0;
  else if(write_en) wr_en_reg <= 1'b1;
  else  wr_en_reg <= 1'b0;
end

// always@(*) begin
//   if(rd_en_reg) begin
//     if(addr_reg == 4'h4) HRDATA <= {24'b0,iData};
//     else HRDATA <= 32'd0;
//     end 
//     else HRDATA <= 32'd0;
// end]

// assign HRDATA = (rd_en_reg  & (addr_reg == 4'h4)) ? {24'd0,iData} : 32'd0;

always@(posedge HCLK or negedge HRESETn) begin
    if(~HRESETn) begin
        interrupt_en <= 1'b0;
        startADDRESS <= 32'd0;
        sd_rd_en <= 1'd0;
    end
    else if(wr_en_reg & addr_reg == 4'h0)  sd_rd_en <= HWDATA[0];
    else if(wr_en_reg & addr_reg == 4'h4)  startADDRESS <= HWDATA;
    else if(wr_en_reg & addr_reg == 4'hc)  interrupt_en <= HWDATA[0];
end
    
assign HRDATA = (rd_en_reg & (addr_reg == 4'h8)) ? {31'd0,sd_state} : 32'd0;
    


endmodule