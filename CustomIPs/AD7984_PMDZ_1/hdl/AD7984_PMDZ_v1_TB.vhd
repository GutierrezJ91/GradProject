library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.ENV.ALL;

entity AD7984_PMDZ_v1_TB is
end AD7984_PMDZ_v1_TB;

architecture Behavioral of AD7984_PMDZ_v1_TB is
component AD7984_PMDZ_v1 is
	generic (
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
end component;
constant MPERIOD    : time := 10 ns; -- 100MHz

signal ADC_CSL_TB       : std_logic;
signal ADC_SCLK_TB      : std_logic;
signal ADC_MISO_SDO     : std_logic;

signal MCLK             : std_logic := '1';
signal MRSTN            : std_logic := '1';
signal TVALID           : std_logic;
signal TDATA            : std_logic_vector(15 downto 0);
signal TREADY           : std_logic;

type DATA_t is array (0 to 3) of std_logic_vector(17 downto 0);
signal MyData: DATA_t := ( 
    "111010101111001101",
    "110011100011110000",
    "001100011100001111",
    "000011110001110011"
    );
    
begin

DUT: AD7984_PMDZ_v1
    generic map ( C_M00_AXIS_TDATA_WIDTH => 16)
    port map (  ADC_CSL => ADC_CSL_TB,
                ADC_SCLK => ADC_SCLK_TB,
                ADC_MISO_SDO => ADC_MISO_SDO,
                m00_axis_aclk => MCLK,
                m00_axis_aresetn => MRSTN,
                m00_axis_tvalid => TVALID,
                m00_axis_tdata => TDATA,
                m00_axis_tready => TREADY
                );
              

MCLK <= not MCLK after MPERIOD/2;            -- 100MHz

process
begin
MRSTN <= '0';
wait for MPERIOD;
MRSTN <= '1';
wait;
end process;


process
begin

ADC_MISO_SDO <= 'Z';
TREADY <= '1';

for j in 0 to 3 loop
    wait until ADC_CSL_TB = '1';
    report "CSL = 1";
    wait until ADC_CSL_TB = '0';
    report "CSL = 0";
    report "Recieving Word #" & integer'image(j);
    for i in 0 to 17 loop
        ADC_MISO_SDO<= MyData(j)(17-i);
        wait until falling_edge(ADC_SCLK_TB);
    end loop;
    ADC_MISO_SDO <= 'Z';
end loop;

wait for MPERIOD*10;
finish;
end process;


end Behavioral;
