// Copyright 1986-2014 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2014.4 (win64) Build 1071353 Tue Nov 18 18:29:27 MST 2014
// Date        : Tue Nov 24 15:45:11 2015
// Host        : bamousse-MOBL2 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/bamousse/Documents/PSU/ECE540/DDR2_MIG_Demo/DDR2_MIG_Demo.srcs/sources_1/ip/fifo_rd_adx_stack/fifo_rd_adx_stack_stub.v
// Design      : fifo_rd_adx_stack
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v12_0,Vivado 2014.4" *)
module fifo_rd_adx_stack(clk, srst, din, wr_en, rd_en, dout, full, almost_full, empty, data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[26:0],wr_en,rd_en,dout[26:0],full,almost_full,empty,data_count[5:0]" */;
  input clk;
  input srst;
  input [26:0]din;
  input wr_en;
  input rd_en;
  output [26:0]dout;
  output full;
  output almost_full;
  output empty;
  output [5:0]data_count;
endmodule
