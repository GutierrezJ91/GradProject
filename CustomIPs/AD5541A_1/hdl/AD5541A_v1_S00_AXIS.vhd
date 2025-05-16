library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AD5541A_v1_S00_AXIS is
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
end AD5541A_v1_S00_AXIS;

architecture arch_imp of AD5541A_v1_S00_AXIS is
	
component AD5541A_Control is
	Port (	CLK: in std_logic;                                          -- System Clock (50MHz)
			RST: in std_logic;                                          -- System Reset Synchronous
			TX_DATA: in std_logic_vector(15 downto 0);                  -- Data to Transmit
			RD_STRB: out std_logic;                                     -- Read FIFO Data Strobe
			DIN: out std_logic;                                         -- Current Output Bit
			CS_L: out std_logic;                                        -- Chip Select Line
			LDAC_L: out std_logic;                                      -- Load DAC 
			SCLK: out std_logic                                         -- SPI Clock (CLK/2 MHz)
			);
end component;

signal DAC_CLK			: std_logic;
signal DAC_TXD  		: std_logic_vector(15 downto 0);
signal DAC_STRB_PREV 	: std_logic;
signal DAC_STRB			: std_logic;
signal SHIFTREG_P		: std_logic_vector(1 downto 0);

signal TREADY           : std_logic;

begin

S_AXIS_TREADY <= TREADY;

--Grab Data from Interface
process(S_AXIS_ACLK,S_AXIS_ARESETN) 
begin
	if rising_edge(S_AXIS_ACLK) then
		if(S_AXIS_ARESETN = '0') then
			DAC_TXD <= (others => '0');
		else
			if(S_AXIS_TVALID = '1' and TREADY = '1') then
				DAC_TXD <= S_AXIS_TDATA;
			else
				DAC_TXD <= DAC_TXD;
			end if;
		end if;
	end if;
end process;

--Generate Clk for DAC
process(S_AXIS_ACLK, S_AXIS_ARESETN) 
begin
	if rising_edge(S_AXIS_ACLK) then 
		if(S_AXIS_ARESETN = '0') then 
			DAC_CLK <= '0';
		else
			DAC_CLK <= not DAC_CLK;
		end if;
	end if;
end process;

-- Generate Reset Pulse for ADC Logic		
process(S_AXIS_ACLK,S_AXIS_ARESETN)
begin
	if rising_edge(S_AXIS_ACLK) then 
		if(S_AXIS_ARESETN = '0') then
			SHIFTREG_P <= "11";
		else
			SHIFTREG_P <= SHIFTREG_P(0) & '0';
		end if;
	end if;
end process;

process(S_AXIS_ACLK,S_AXIS_ARESETN)
begin
	if rising_edge(S_AXIS_ACLK) then 
		if(S_AXIS_ARESETN = '0') then
			DAC_STRB_PREV <= '0';
		else
			DAC_STRB_PREV <= DAC_STRB;
		end if;
	end if;
end process;

TREADY <= not DAC_STRB_PREV and DAC_STRB;


DAC: AD5541A_Control
 port map(
	CLK 	=> DAC_CLK,
	RST 	=> SHIFTREG_P(1),
	TX_DATA => DAC_TXD,
	RD_STRB => DAC_STRB,
	DIN 	=> DIN,
	CS_L 	=> CS_L,
	LDAC_L 	=> LDAC_L,
	SCLK 	=> SCLK
);

	

end arch_imp;
