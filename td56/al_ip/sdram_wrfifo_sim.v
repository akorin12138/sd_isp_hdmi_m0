// Verilog netlist created by Tang Dynasty v5.6.71036
// Wed Apr 10 11:52:33 2024

`timescale 1ns / 1ps
module sdram_fifo  // sdram_wrfifo.v(14)
  (
  clkr,
  clkw,
  di,
  re,
  rst,
  we,
  aempty_flag,
  afull_flag,
  do,
  empty_flag,
  full_flag
  );

  input clkr;  // sdram_wrfifo.v(25)
  input clkw;  // sdram_wrfifo.v(24)
  input [15:0] di;  // sdram_wrfifo.v(23)
  input re;  // sdram_wrfifo.v(25)
  input rst;  // sdram_wrfifo.v(22)
  input we;  // sdram_wrfifo.v(24)
  output aempty_flag;  // sdram_wrfifo.v(28)
  output afull_flag;  // sdram_wrfifo.v(29)
  output [15:0] do;  // sdram_wrfifo.v(27)
  output empty_flag;  // sdram_wrfifo.v(28)
  output full_flag;  // sdram_wrfifo.v(29)

  wire empty_flag_syn_2;  // sdram_wrfifo.v(28)
  wire full_flag_syn_2;  // sdram_wrfifo.v(29)

  EG_PHY_CONFIG #(
    .DONE_PERSISTN("ENABLE"),
    .INIT_PERSISTN("ENABLE"),
    .JTAG_PERSISTN("DISABLE"),
    .PROGRAMN_PERSISTN("DISABLE"))
    config_inst ();
  not empty_flag_syn_1 (empty_flag_syn_2, empty_flag);  // sdram_wrfifo.v(28)
  EG_PHY_FIFO #(
    .AE(32'b00000000000000000000011111111000),
    .AEP1(32'b00000000000000000000100000000000),
    .AF(32'b00000000000000000000100000000000),
    .AFM1(32'b00000000000000000000011111111000),
    .ASYNC_RESET_RELEASE("SYNC"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .E(32'b00000000000000000000000000000000),
    .EP1(32'b00000000000000000000000000001000),
    .F(32'b00000000000000000010000000000000),
    .FM1(32'b00000000000000000001111111111000),
    .GSR("DISABLE"),
    .MODE("FIFO8K"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("ASYNC"))
    fifo_inst_syn_3 (
    .clkr(clkr),
    .clkw(clkw),
    .csr({2'b11,empty_flag_syn_2}),
    .csw({2'b11,full_flag_syn_2}),
    .dia(di[8:0]),
    .orea(1'b0),
    .oreb(1'b0),
    .re(re),
    .rprst(rst),
    .rst(rst),
    .we(we),
    .aempty_flag(aempty_flag),
    .afull_flag(afull_flag),
    .dob(do[8:0]),
    .empty_flag(empty_flag),
    .full_flag(full_flag));  // sdram_wrfifo.v(43)
  EG_PHY_FIFO #(
    .AE(32'b00000000000000000000011111111000),
    .AEP1(32'b00000000000000000000100000000000),
    .AF(32'b00000000000000000000100000000000),
    .AFM1(32'b00000000000000000000011111111000),
    .ASYNC_RESET_RELEASE("SYNC"),
    .DATA_WIDTH_A("9"),
    .DATA_WIDTH_B("9"),
    .E(32'b00000000000000000000000000000000),
    .EP1(32'b00000000000000000000000000001000),
    .F(32'b00000000000000000010000000000000),
    .FM1(32'b00000000000000000001111111111000),
    .GSR("DISABLE"),
    .MODE("FIFO8K"),
    .REGMODE_A("NOREG"),
    .REGMODE_B("NOREG"),
    .RESETMODE("ASYNC"))
    fifo_inst_syn_4 (
    .clkr(clkr),
    .clkw(clkw),
    .csr({2'b11,empty_flag_syn_2}),
    .csw({2'b11,full_flag_syn_2}),
    .dia({open_n65,open_n66,di[15:9]}),
    .orea(1'b0),
    .oreb(1'b0),
    .re(re),
    .rprst(rst),
    .rst(rst),
    .we(we),
    .dob({open_n87,open_n88,do[15:9]}));  // sdram_wrfifo.v(43)
  not full_flag_syn_1 (full_flag_syn_2, full_flag);  // sdram_wrfifo.v(29)

endmodule 

