module AHblite_key(
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
    input  wire   [3:0]  key_data
);
    
assign HRESP = 1'b0;
assign HREADYOUT = 1'b1;
//握手
wire write_en;
assign write_en=HSEL&HTRANS[1]&(HWRITE)&HREADY;
wire read_en;
assign read_en=HSEL&HTRANS[1]&(~HWRITE)&HREADY;
reg wr_en_reg;
always@(posedge HCLK or negedge HRESETn) begin
  if(~HRESETn) wr_en_reg <= 1'b0;
  else if(write_en) wr_en_reg <= 1'b1;
  else wr_en_reg <= 1'b0;
end

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

assign HRDATA = (rd_en_reg  & (addr_reg == 4'h0)) ? {28'b0,key_data} : 32'd0;
endmodule //AHblite_key

