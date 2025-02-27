--------------------------------------------------------------
 --     Copyright (c) 2012-2023 Anlogic Inc.
 --  All Right Reserved.
--------------------------------------------------------------
 -- Log	:	This file is generated by Anlogic IP Generator.
 -- File	:	E:/Documents/2024/sd_isp_hdmi/td56/al_ip/sdram_wrfifo.vhd
 -- Date	:	2024 04 10
 -- TD version	:	5.6.71036
--------------------------------------------------------------

LIBRARY ieee;
USE work.ALL;
	USE ieee.std_logic_1164.all;
LIBRARY eagle_macro;
	USE eagle_macro.EAGLE_COMPONENTS.all;

ENTITY sdram_fifo IS
PORT (
	di	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);

	rst	: IN STD_LOGIC;
	clkw	: IN STD_LOGIC;
	we	: IN STD_LOGIC;
	clkr	: IN STD_LOGIC;
	re	: IN STD_LOGIC;
	do	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
	empty_flag		: OUT STD_LOGIC;
	aempty_flag		: OUT STD_LOGIC;
	full_flag		: OUT STD_LOGIC;
	afull_flag		: OUT STD_LOGIC
	);
END sdram_fifo;

ARCHITECTURE struct OF sdram_fifo IS

	BEGIN
	fifo_inst : EG_LOGIC_FIFO
		GENERIC MAP (
			DATA_WIDTH_W			=> 16,
			DATA_DEPTH_W			=> 1024,
			DATA_WIDTH_R			=> 16,
			DATA_DEPTH_R			=> 1024,
			ENDIAN				=> "BIG",
			RESETMODE			=> "ASYNC",
			REGMODE_R			=> "NOREG",
			E					=> 0,
			F					=> 1024,
			ASYNC_RESET_RELEASE	=> "SYNC",
			AE					=> 255,
			AF					=> 256
		)
		PORT MAP (
			rst	=> rst,
			di	=> di,
			clkw	=> clkw,
			we	=> we,
			csw	=> "111",
			clkr	=> clkr,
			ore	=> '0',
			re	=> re,
			csr	=> "111",
			do	=> do,
			empty_flag	=> empty_flag,
			aempty_flag	=> aempty_flag,
			full_flag	=> full_flag,
			afull_flag	=> afull_flag
		);

END struct;
