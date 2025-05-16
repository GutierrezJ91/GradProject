library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AD5541A_v1 is
	generic (
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 16
	);
	port (
		DIN				: out std_logic;
		CS_L			: out std_logic;
		LDAC_L 			: out std_logic;
		SCLK 			: out std_logic;

		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tvalid	: in std_logic
	);
end AD5541A_v1;

architecture arch_imp of AD5541A_v1 is

	-- component declaration
	component AD5541A_v1_S00_AXIS is
		generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 16
		);
		port (
		DIN				: out std_logic;
		CS_L			: out std_logic;
		LDAC_L 			: out std_logic;
		SCLK 			: out std_logic;
		S_AXIS_ACLK		: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TVALID	: in std_logic
		);
	end component AD5541A_v1_S00_AXIS;

begin

-- Instantiation of Axi Bus Interface S00_AXIS
AD5541A_v1_S00_AXIS_inst : AD5541A_v1_S00_AXIS
	generic map (
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
		DIN				=> DIN,
		CS_L			=> CS_L,
		LDAC_L 			=> LDAC_L,
		SCLK 			=> SCLK,
		S_AXIS_ACLK		=> s00_axis_aclk,
		S_AXIS_ARESETN	=> s00_axis_aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TVALID	=> s00_axis_tvalid
	);


end arch_imp;
