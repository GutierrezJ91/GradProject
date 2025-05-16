library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use STD.ENV.ALL;

entity MPC3008_ADC_v1_TB is
end MPC3008_ADC_v1_TB;

architecture Behavioral of MPC3008_ADC_v1_TB is

component MPC3008_ADC_v1 is
	generic (
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
        CSL 		: out std_logic;
		SCLK		: out std_logic;
		DIN			: out std_logic;
		DOUT		: in std_logic;
		CLK_50M		: in std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end component;

constant clkperiod :time := 10ns;
constant clkperiod2 :time := 20ns;

signal s00_axi_aclk 	: std_logic := '0';
signal s00_axi_aresetn 	: std_logic := '1';
signal s00_axi_awaddr 	: std_logic_vector(3 downto 0);
signal s00_axi_awprot	: std_logic_vector(2 downto 0);
signal s00_axi_awvalid	: std_logic;
signal s00_axi_awready 	: std_logic;
signal s00_axi_wdata 	: std_logic_vector(31 downto 0);
signal s00_axi_wstrb	: std_logic_vector(3 downto 0);
signal s00_axi_wvalid 	: std_logic;
signal s00_axi_wready 	: std_logic;
signal s00_axi_bresp	: std_logic_vector(1 downto 0);
signal s00_axi_bvalid	: std_logic;
signal s00_axi_bready	: std_logic; 
signal s00_axi_araddr 	: std_logic_vector(3 downto 0);
signal s00_axi_arprot 	: std_logic_vector(2 downto 0);
signal s00_axi_arvalid 	: std_logic;
signal s00_axi_arready 	: std_logic;
signal s00_axi_rdata	: std_logic_vector(31 downto 0);
signal s00_axi_rresp 	: std_logic_vector(1 downto 0);
signal s00_axi_rvalid 	: std_logic;
signal s00_axi_rready	: std_logic; 

signal CSL          :std_logic;
signal SCLK         :std_logic;
signal DIN          :std_logic;
signal DOUT         :std_logic;
signal CLK_50M		:std_logic := '0';

type data_array is array (0 to 7) of std_logic_vector(9 downto 0);
    signal mydata: data_array := ( "1100110011",
                                   "0011001100",
                                   "1011001101",
                                   "0100110011",
                                   "1111000011",
                                   "0000111100",
                                   "1100001111",
                                   "0011110000");

begin
    DUT: MPC3008_ADC_v1
	 generic map(
		C_S00_AXI_DATA_WIDTH => 32,
		C_S00_AXI_ADDR_WIDTH => 4
	)
	 port map(
		CSL => CSL,
		SCLK => SCLK,
		DIN => DIN,
		DOUT => DOUT,
		CLK_50M => CLK_50M,
		s00_axi_aclk => s00_axi_aclk,
		s00_axi_aresetn => s00_axi_aresetn,
		s00_axi_awaddr => s00_axi_awaddr,
		s00_axi_awprot => s00_axi_awprot,
		s00_axi_awvalid => s00_axi_awvalid,
		s00_axi_awready => s00_axi_awready,
		s00_axi_wdata => s00_axi_wdata,
		s00_axi_wstrb => s00_axi_wstrb,
		s00_axi_wvalid => s00_axi_wvalid,
		s00_axi_wready => s00_axi_wready,
		s00_axi_bresp => s00_axi_bresp,
		s00_axi_bvalid => s00_axi_bvalid,
		s00_axi_bready => s00_axi_bready,
		s00_axi_araddr => s00_axi_araddr,
		s00_axi_arprot => s00_axi_arprot,
		s00_axi_arvalid => s00_axi_arvalid,
		s00_axi_arready => s00_axi_arready,
		s00_axi_rdata => s00_axi_rdata,
		s00_axi_rresp => s00_axi_rresp,
		s00_axi_rvalid => s00_axi_rvalid,
		s00_axi_rready => s00_axi_rready
	);


	s00_axi_aclk <= not s00_axi_aclk after clkperiod/2;
	CLK_50M <= not CLK_50M after clkperiod2/2;

	process
	begin
		s00_axi_awaddr 	<= (others => '0');
		s00_axi_awprot 	<= (others => '0');
		s00_axi_awvalid <= '0';
		
		s00_axi_wdata 	<= (others => '0');
		s00_axi_wstrb 	<= (others => '0');
		s00_axi_wvalid 	<= '0';
		s00_axi_bready  <= '0';


		s00_axi_aresetn <= '0';
		wait for clkperiod*10;
		s00_axi_aresetn <= '1';
		wait;
	end process;
	
	
	process
	begin
		DOUT <= 'Z';
		
		for j in 0 to 7 loop
		
			wait until CSL = '0';
			
			for k in 0 to 5 loop
				wait until SCLK = '0';
			end loop;
			
			DOUT <= '0';
			
			for i in 9 downto 0 loop
				wait until SCLK = '0';
				DOUT <= mydata(j)(i);
			end loop;
			wait until SCLK = '0';
			
			DOUT <= 'Z';
			
			wait until CSL = '1';
		end loop;
		
		wait until CSL = '0';
		finish;
	end process;
	
	process
	begin
	s00_axi_araddr 	<= (others => '0');
	s00_axi_arprot 	<= (others => '0');
	s00_axi_arvalid <= '0';
	s00_axi_rready <= '1';
	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';

	wait for clkperiod*20;
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"4";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"8";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"C";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';
	
	wait for clkperiod*20;

	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';
	wait until CSL = '0';
	wait until CSL = '1';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"0";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"4";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"8";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';

	wait for clkperiod*20;
	s00_axi_araddr 	<= x"C";
	s00_axi_arvalid <= '1';
	wait for clkperiod*2;
	s00_axi_arvalid <= '0';
	
	wait for clkperiod*20;
	
	end process;


end Behavioral;
