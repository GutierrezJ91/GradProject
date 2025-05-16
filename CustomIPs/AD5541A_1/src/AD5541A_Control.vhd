

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.my_pkg.all;

entity AD5541A_Control is
  Port (CLK: in std_logic;                                          -- System Clock (50MHz)
        RST: in std_logic;                                          -- System Reset Synchronous
        TX_DATA: in std_logic_vector(15 downto 0);                  -- Data to Transmit
        RD_STRB: out std_logic;                                     -- Read FIFO Data Strobe
        DIN: out std_logic;                                         -- Current Output Bit
        CS_L: out std_logic;                                        -- Chip Select Line
        LDAC_L: out std_logic;                                      -- Load DAC 
        SCLK: out std_logic                                         -- SPI Clock (CLK/2 MHz)
         );
end AD5541A_Control;

architecture Behavioral of AD5541A_Control is

constant CLK_FREQ               : integer := 50_000_000;                -- System Clock Frequency (in Hz)
constant CLK_PERIOD             : integer := 20;
constant UPDATE_RATE            : integer := 44100;                     -- DAC Update Rate (in Samples/s)
constant CLKS_PER_TRAX          : integer := CLK_FREQ/UPDATE_RATE;      -- DAC Transaction (in Clocks)
constant CNV_HOLD               : integer := 500/CLK_PERIOD;            -- MAX CONV TIME / CLK_PERIOD (in Clocks)
constant STARTUPDELAY           : integer := 9;                         -- 200us Startup Delay

signal CLK_COUNTER              : unsigned(log2(CLKS_PER_TRAX) downto 0);
signal TCYC_COUNTER             : unsigned(log2(CLKS_PER_TRAX) downto 0);
signal BITCOUNT                 : unsigned(log2(TX_DATA'LENGTH) downto 0);

signal iCSL                     : std_logic;
signal iSCLK                    : std_logic;
signal TxData_Shift_Register    : std_logic_vector(15 downto 0);
signal TxDataShiftReg_WriteFlag : std_logic;
signal Enable_DAC_SPI           : std_logic;
signal Enable_DAC_SPI_prev      : std_logic;
signal Enable_DAC_SPI_Pulse     : std_logic;

type state_t is (IDLE,CSL,TX);
signal state: state_t;

                        
begin

SPI_SM: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            iCSL <= '1';
            iSCLK <= '0';
            state <= IDLE;
        else
            case(state) is
                when IDLE => iCSL <= '1';                            
                             iSCLK <= '0';
                             if(Enable_DAC_SPI = '1') then 
                                state <= CSL;
                             else
                                state <= IDLE;
                             end if;
                when CSL => iSCLK <= iSCLK;
                            if(CLK_COUNTER = CNV_HOLD) then
                                iCSL    <= '0';
                                state   <= TX;
                            else
                                iCSL    <= iCSL;
                                state   <= CSL;
                            end if;
                when TX =>  iCSL <= iCSL;
                            if(BITCOUNT < 16) then 
                                iSCLK <= not iSCLK;
                                state <= TX;
                            else
                                iSCLK <= iSCLK;
                                state <= IDLE;
                            end if;
                when others => NULL;
            end case;
        end if;
    end if;
end process;

TCYC_CNTR_PROC: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if (RST = '1') then
            TCYC_COUNTER <= (others => '0');
        else
            if(TCYC_COUNTER < STARTUPDELAY) then
                if(CLK_COUNTER = CLKS_PER_TRAX-1) then
                    TCYC_COUNTER <= TCYC_COUNTER + 1;
                else
                    TCYC_COUNTER <= TCYC_COUNTER;
                end if;
            else
                TCYC_COUNTER <= TCYC_COUNTER;
            end if;
        end if;
    end if;
end process;

Enable_DAC_SPI <= '1' when TCYC_COUNTER = STARTUPDELAY else '0';

ENA_PULSE_GEN: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            Enable_DAC_SPI_prev <= '0';
        else
            Enable_DAC_SPI_prev <= Enable_DAC_SPI;
        end if;
    end if;
end process;

Enable_DAC_SPI_Pulse <= Enable_DAC_SPI and not Enable_DAC_SPI_prev;

CLK_CNTR_PROC:process(CLK,RST)
begin
    if rising_edge(CLK) then
        if (RST = '1') then
            CLK_COUNTER <= (others => '0');
        else
            if(CLK_COUNTER  < CLKS_PER_TRAX-1) then
                CLK_COUNTER  <= CLK_COUNTER  + 1;
            else
                CLK_COUNTER  <= (others => '0');
            end if;
        end if;
    end if;
end process;

DATA_CNTRL: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            TxData_Shift_Register <= (others => '0');
            BITCOUNT <= (others => '0');
        elsif(TxDataShiftReg_WriteFlag = '1') then
            TxData_Shift_Register <= TX_DATA;
            BITCOUNT <= (others => '0');
        elsif(iCSL = '0'and iSCLK = '1') then
            TxData_Shift_Register <= TxData_Shift_Register(14 downto 0) & '0';
            BITCOUNT <= BITCOUNT + 1;
        else
            TxData_Shift_Register <= TxData_Shift_Register;
            BITCOUNT <= BITCOUNT;
        end if;
    end if;
end process;

TxDataShiftReg_WriteFlag <= '1'when (CLK_COUNTER = CNV_HOLD-2 and Enable_DAC_SPI = '1') else '0';

CS_L    <= iCSL;
SCLK    <= iSCLK;
DIN     <= TxData_Shift_Register(15) when iCSL = '0' else 'Z';
LDAC_L  <= '1';
RD_STRB <= TxDataShiftReg_WriteFlag;

end Behavioral;
