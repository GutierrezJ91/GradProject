library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MPC3008_ADC_v1_S00_AXI is
	generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		CSL 		: out std_logic;
		SCLK		: out std_logic;
		DIN			: out std_logic;
		DOUT		: in std_logic;
		CLK_50M		: in std_logic;
		
		S_AXI_ACLK		: in std_logic;											    -- Global Clock Signal
		S_AXI_ARESETN	: in std_logic;												-- Global Reset Signal.

		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;

		S_AXI_WDATA		: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB		: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;

		S_AXI_BRESP		: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		
		-- Read Address Channel
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0); 		-- Read Address
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);					  		-- Read Protection Type
		S_AXI_ARVALID	: in std_logic; 									  		-- Read Address Valid
		S_AXI_ARREADY	: out std_logic;									  		-- Read Address Ready

		-- Read Data Channel
		S_AXI_RDATA		: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);		-- Read Data (issued by slave)
		S_AXI_RRESP		: out std_logic_vector(1 downto 0);							-- Read Response.
		S_AXI_RVALID	: out std_logic;											-- Read Valid. 
		S_AXI_RREADY	: in std_logic												-- Read Ready.
	);
end MPC3008_ADC_v1_S00_AXI;

architecture arch_imp of MPC3008_ADC_v1_S00_AXI is

component MPC3008_Control is
		Port (  CLK     : in std_logic;
				RST     : in std_logic;
				AIN0_OUT : out std_logic_vector(9 downto 0);
				AIN1_OUT : out std_logic_vector(9 downto 0);
				AIN2_OUT : out std_logic_vector(9 downto 0);
				AIN3_OUT : out std_logic_vector(9 downto 0);
				CSL     : out std_logic;
				SCLK    : out std_logic;
				DIN     : out std_logic;
				DOUT    : in std_logic;
				DV      : out std_logic
		);
	end component;
	
	-- AXI4LITE signals
	
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- My signals
	signal ADC_CLK			: std_logic;
	signal ADC_DV			: std_logic;
	signal ADC_DV_AXI		: std_logic;
	signal SHIFTREG_P		: std_logic_vector(1 downto 0);
	signal DV_FF			: std_logic_vector(1 downto 0);

	constant ADDR_LSB  			: integer := (C_S_AXI_DATA_WIDTH/32)+ 1;  -- 2
	constant OPT_MEM_ADDR_BITS 	: integer := 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 4
	signal slv_reg0			: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg1			: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg2			: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg3			: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal slv_reg_rden		: std_logic;
	signal reg_data_out		: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal AIN0_OUT            : std_logic_vector(9 downto 0);
	signal AIN1_OUT            : std_logic_vector(9 downto 0);
	signal AIN2_OUT            : std_logic_vector(9 downto 0);
	signal AIN3_OUT            : std_logic_vector(9 downto 0);


begin
	-- I/O Connections assignments

	S_AXI_WREADY    <= '0';
	S_AXI_AWREADY	<= '0';
	S_AXI_BVALID	<= '0';
	S_AXI_BRESP		<= "00";

	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA		<= axi_rdata;
	S_AXI_RRESP		<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;

	--Get Address from Master and Acknowledgement
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '0');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        axi_arready <= '1';
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- 
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1') then
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (slv_reg0, slv_reg1, slv_reg2, slv_reg3, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
	      when b"00" =>
	        reg_data_out <= slv_reg0;
	      when b"01" =>
	        reg_data_out <= slv_reg1;
	      when b"10" =>
	        reg_data_out <= slv_reg2;
	      when b"11" =>
	        reg_data_out <= slv_reg3;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK )
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;

	process(S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if(S_AXI_ARESETN = '0') then 
				slv_reg0 <= (others => '0');
				slv_reg1 <= (others => '0');
				slv_reg2 <= (others => '0');
				slv_reg3 <= (others => '0');
			else
				if(ADC_DV_AXI = '1') then
					slv_reg0 <= x"00000" & "00" & AIN0_OUT;
					slv_reg1 <= x"00000" & "00" & AIN1_OUT;
					slv_reg2 <= x"00000" & "00" & AIN2_OUT;
					slv_reg3 <= x"00000" & "00" & AIN3_OUT;
				end if;
			end if;
		end if;
	end process;

	-- Generate Reset Pulse for ADC Logic	
	process(S_AXI_ACLK)
	begin
		if rising_edge(S_AXI_ACLK) then 
			if(S_AXI_ARESETN = '0') then
				SHIFTREG_P <= "11";
			else
				SHIFTREG_P <= SHIFTREG_P(0) & '0';
			end if;
		end if;
	end process;

	-- Generate Data Valid Pulse in AXI Clock Domain (AXI CLOCK FREQ > ADC CLK FREQ hence edge detector is used)
	process(S_AXI_ACLK, S_AXI_ARESETN)
	begin
		if rising_edge(S_AXI_ACLK) then
			if(S_AXI_ARESETN = '0') then
				DV_FF <= (others => '0');
			else
				DV_FF(0) <= ADC_DV;
				DV_FF(1) <= DV_FF(0);
			end if;
		end if;
	end process;

	ADC_DV_AXI <= DV_FF(0) and not DV_FF(1); -- generates clock width valid pulse
	
	-- Add user logic here
	ADC: MPC3008_Control
	 port map(
		CLK => CLK_50M,
		RST => SHIFTREG_P(1),
		AIN0_OUT => AIN0_OUT,
		AIN1_OUT => AIN1_OUT,
		AIN2_OUT => AIN2_OUT,
		AIN3_OUT => AIN3_OUT,
		CSL => CSL,
		SCLK => SCLK,
		DIN => DIN,
		DOUT => DOUT,
		DV => ADC_DV
	);
	-- User logic ends
	

end arch_imp;
