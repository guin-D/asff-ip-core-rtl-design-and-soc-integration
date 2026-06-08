// Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
// Date        : Sat May  9 06:57:45 2026
// Host        : DESKTOP-RR3HL5V running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/usually_used/ic/Vivado/HLx/ASFF/ASFF_2/ASFF_2.srcs/sources_1/ip/X2_BUF_RAM/X2_BUF_RAM_stub.v
// Design      : X2_BUF_RAM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_2,Vivado 2018.3" *)
module X2_BUF_RAM(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[11:0],dina[31:0],clkb,addrb[11:0],doutb[31:0]" */;
  input clka;
  input [0:0]wea;
  input [11:0]addra;
  input [31:0]dina;
  input clkb;
  input [11:0]addrb;
  output [31:0]doutb;
endmodule
