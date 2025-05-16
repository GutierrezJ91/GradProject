library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AD7984_PMDZ_v1 is
	generic (
		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 16
	);
	port (
		-- Users to add ports here
        ADC_CSL         : out std_logic;
        ADC_SCLK        : out std_logic;
        ADC_MISO_SDO    : in std_logic;
        
		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tready	: in std_logic
	);
end AD7984_PMDZ_v1;

architecture arch_imp of AD7984_PMDZ_v1 is

	-- component declaration
	component AD7984_PMDZ_v1_M00_AXIS is
		generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 16
		);
		port (
		ADC_CSL         : out std_logic;
		ADC_SCLK        : out std_logic;
		ADC_MISO_SDO    : in std_logic;
		M_AXIS_ACLK	    : in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TREADY	: in std_logic
		);
	end component AD7984_PMDZ_v1_M00_AXIS;

begin

-- Instantiation of Axi Bus Interface M00_AXIS
AD7984_PMDZ_v1_M00_AXIS_inst : AD7984_PMDZ_v1_M00_AXIS
	generic map (
		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH
	)
	port map (
	    ADC_CSL    		=> ADC_CSL,
	    ADC_SCLK   		=> ADC_SCLK,
	    ADC_MISO_SDO 	=> ADC_MISO_SDO,
		M_AXIS_ACLK		=> m00_axis_aclk,
		M_AXIS_ARESETN	=> m00_axis_aresetn,
		M_AXIS_TVALID	=> m00_axis_tvalid,
		M_AXIS_TDATA	=> m00_axis_tdata,
		M_AXIS_TREADY	=> m00_axis_tready
	);

	

end arch_imp;
