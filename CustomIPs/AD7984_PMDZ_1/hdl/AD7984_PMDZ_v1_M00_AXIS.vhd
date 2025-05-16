library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AD7984_PMDZ_v1_M00_AXIS is
	generic (
		C_M_AXIS_TDATA_WIDTH	: integer	:= 16
	);
	port (
		-- Users to add ports here
        ADC_CSL         :out std_logic;
        ADC_SCLK        :out std_logic;
        ADC_MISO_SDO    :in std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TREADY	: in std_logic
	);
end AD7984_PMDZ_v1_M00_AXIS;

architecture implementation of AD7984_PMDZ_v1_M00_AXIS is
	component AD7984_Control is
    Port (  CLK         : in std_logic;                         -- System Clock Frequency = 50MHz
            RST         : in std_logic;                         -- System Synchronous Reset
            RX_DATA     : out std_logic_vector(17 downto 0);    -- Recieved Data (18 bits)
            CSL         : out std_logic;                        -- Chip Select (CNV)
            SCLK        : out std_logic;                        -- SPI CLK
            MISO_SDO    : in std_logic;                         -- SPI SDO
                                                                -- SPI SDI (Set High in HW, SDI is connected to VIO)
            ADC_READY   : out std_logic;
            DV          : out std_logic                         -- Recieved Data Valid
    );  
    end component;
    
    -- Define the states of state machine                                             
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO                                   
	type state is ( IDLE,        -- This is the initial/idle state     
	                SEND_STREAM);  -- In this state the                               
	                             -- stream data is output through M_AXIS_TDATA        
	-- State variable                                                                 
	signal  mst_exec_state : state;                                                                                 

	-- AXI Stream internal signals
	--streaming data valid
	signal axis_tvalid	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--FIFO implementation signals
	signal stream_data_out	: std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_en	: std_logic;
	--The master has issued all the streaming data stored in FIFO
	signal tx_done	: std_logic;
	
	-- User Defined Signals
	signal ADC_RX_DATA	: std_logic_vector(17 downto 0);
	signal ADC_DV		: std_logic;
	signal DV_FF	 	: std_logic_vector(1 downto 0);
	signal ADC_READY	: std_logic;
	signal SHIFTREG_P	: std_logic_vector(1 downto 0);
	signal ADC_CLK 		: std_logic;


begin
	-- I/O Connections assignments

	M_AXIS_TVALID	<= axis_tvalid_delay;
	M_AXIS_TDATA	<= stream_data_out;

	-- Control state machine implementation                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      mst_exec_state <= IDLE;                                                                                                                     
	    else                                                                                    
	      case (mst_exec_state) is                                                              
			when IDLE     => 		if (tx_en = '1' and ADC_READY = '1') then 
										mst_exec_state <= SEND_STREAM;
									else
										mst_exec_state <= IDLE;
									end if;                                                                            
	        when SEND_STREAM  => 	if (tx_done = '1') then                                                           
										mst_exec_state <= IDLE;                                                         
									else                                                                              
										mst_exec_state <= SEND_STREAM;                                                  
									end if;                                                                                                                                              
	        when others    =>                                                                   
	          					mst_exec_state <= IDLE;                                                                                  
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                     
	                                                                                               
	-- Delay the axis_tvalid signal by one clock cycle                              
	-- to match the latency of M_AXIS_TDATA                                                        
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      axis_tvalid_delay <= '0';                                      
	    else                                                                                       
	      axis_tvalid_delay <= axis_tvalid;                                                                                                               
	    end if;                                                                                    
	  end if;                                                                                      
	end process;                                                                                   


	-- direct processing single sample

	process(M_AXIS_ACLK)                                                       
	begin                                                                            
	  if (rising_edge (M_AXIS_ACLK)) then                                            
	    if(M_AXIS_ARESETN = '0') then                                           
	      tx_done  <= '0';                                                           
	    else                                                                                  
	        if (tx_en = '1') then                                                                                      
	        	tx_done <= '1';                                                        
	        else                                                                                         
	        	tx_done <= '0';                                                          
	      end  if;                                                                   
	    end  if;                                                                     
	  end  if;                                                                       
	end process;                                                                     


	--FIFO read enable generation 

	tx_en <= M_AXIS_TREADY and axis_tvalid;                                   
	                                                                                
	-- FIFO Implementation                                                          
	                                                                                
	-- Streaming output data read from ADC                                   
	  process(M_AXIS_ACLK)                                                                                                    
	  begin                                                                         
	    if (rising_edge (M_AXIS_ACLK)) then                                         
	      if(M_AXIS_ARESETN = '0') then                                             
	    	stream_data_out <= (others => '0');
	      elsif (tx_en = '1') then            
	        stream_data_out <= ADC_RX_DATA(17 downto 2);
	      end if;                                                                   
	     end if;                                                                    
	   end process;                                                                 

	-- Add user logic here
	
	-- Generate Data Valid Pulse in AXI Clock Domain (AXI CLOCK FREQ > ADC CLK FREQ hence edge detector is used)
	process(M_AXIS_ACLK, M_AXIS_ARESETN)
	begin
		if rising_edge(M_AXIS_ACLK) then
			if(M_AXIS_ARESETN = '0') then
				DV_FF <= (others => '0');
			else
				DV_FF(0) <= ADC_DV;
				DV_FF(1) <= DV_FF(0);
			end if;
		end if;
	end process;

	axis_tvalid <= DV_FF(0) and not DV_FF(1); -- generates clock width valid pulse 

	-- Generate Reset Pulse for ADC Logic		
	
	process(M_AXIS_ACLK,M_AXIS_ARESETN)
	begin
		if rising_edge(M_AXIS_ACLK) then 
			if(M_AXIS_ARESETN = '0') then
				SHIFTREG_P <= "11";
			else
				SHIFTREG_P <= SHIFTREG_P(0) & '0';
			end if;
		end if;
	end process;

	process(M_AXIS_ACLK,M_AXIS_ARESETN)
	begin 
		if rising_edge(M_AXIS_ACLK) then      
			if(M_AXIS_ARESETN = '0') then   
				ADC_CLK <= '0';
			else
				ADC_CLK <= not ADC_CLK;
			end if;
		end if;
	end process;                                                             

	-- Add user logic here
	MYADC: AD7984_Control
	 port map( CLK         => ADC_CLK,
	           RST         => SHIFTREG_P(1),
	           RX_DATA     => ADC_RX_DATA,
	           CSL         => ADC_CSL,
	           SCLK        => ADC_SCLK,
	           MISO_SDO    => ADC_MISO_SDO,
	           ADC_READY   => ADC_READY,
	           DV          => ADC_DV
	           );
	-- User logic ends
    

end implementation;
