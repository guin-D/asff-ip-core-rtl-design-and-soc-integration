-- Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
-- Date        : Fri May  8 15:07:18 2026
-- Host        : DESKTOP-RR3HL5V running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               D:/usually_used/ic/Vivado/HLx/ASFF/ASFF_2/ASFF_2.srcs/sources_1/ip/SIW_BUF_RAM_2/SIW_BUF_RAM_2_stub.vhdl
-- Design      : SIW_BUF_RAM_2
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity SIW_BUF_RAM_2 is
  Port ( 
    clka : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 10 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 31 downto 0 );
    clkb : in STD_LOGIC;
    addrb : in STD_LOGIC_VECTOR ( 10 downto 0 );
    doutb : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );

end SIW_BUF_RAM_2;

architecture stub of SIW_BUF_RAM_2 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,wea[0:0],addra[10:0],dina[31:0],clkb,addrb[10:0],doutb[31:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_2,Vivado 2018.3";
begin
end;
