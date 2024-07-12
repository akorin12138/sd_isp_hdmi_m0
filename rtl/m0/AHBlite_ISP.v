module AHBlite_ISP(
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

    output reg    [31:0] isp_data_num0to7,
    output reg    [31:0] isp_data_num8to15,
    output reg           isp_ctrl_en,
    output wire   [10:0] split_x,
    output wire   [10:0] split_y

);

assign HRESP = 1'b0;
assign HREADYOUT = 1'b1;

wire write_en;
assign write_en = HSEL & HTRANS[1] & HWRITE & HREADY;

wire read_en;
assign read_en = HSEL & HTRANS[1]&(~HWRITE)&HREADY;

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

reg [21:0] split_x_y;
always@(posedge HCLK or negedge HRESETn) begin
    if(~HRESETn) begin
      isp_data_num0to7 <= 32'd0;
      isp_data_num8to15 <= 32'd0;
      isp_ctrl_en <= 1'b0;
      split_x_y <= 22'd0;
    end
    else if(wr_en_reg & addr_reg == 4'h0) begin
        isp_data_num0to7 <= HWDATA;
    end
    else if(wr_en_reg & addr_reg == 4'h4) begin
        isp_data_num8to15 <= HWDATA;
    end
    else if(wr_en_reg & addr_reg == 4'h8) begin
        isp_ctrl_en <= HWDATA;
    end
    else if(wr_en_reg & addr_reg == 4'hc) begin
        split_x_y <= HWDATA;
    end
    else begin
      isp_data_num0to7 <= isp_data_num0to7;
      isp_data_num8to15 <= isp_data_num8to15;
      isp_ctrl_en <= isp_ctrl_en;
      split_x_y <= split_x_y;
    end
end
assign split_x = split_x_y[21:11];
assign split_y = split_x_y[10:0];
// assign HRDATA = (rd_en_reg  & (addr_reg == 4'h0)) ? {28'b0,} : 32'd0;

// initial
// begin 
//   isp_data_num0to7 =  32'h00320000;
//   isp_data_num8to15 = 32'h00000040;
// end

endmodule