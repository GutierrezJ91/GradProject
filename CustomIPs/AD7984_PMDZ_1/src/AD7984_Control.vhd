--  AD7984 Control
--  Engineer: Jorge Gutierrez
--  Date: 12/17/2024
--  Description:
--      18-Bit, 1333 kSPS PulSAR� ADC PMOD Evaluation Board
--      This module controls SPI transactions with PMOD (EVAL-AD7984-PMDZ)
--      Uses CS_N Mode, 3-wire without Busy Indicator

library IEEE;
library xil_defaultlib;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use xil_defaultlib.my_pkg.all;

entity AD7984_Control is
    Port (  CLK         : in std_logic;                         -- System Clock Frequency = 50MHz
            RST         : in std_logic;                         -- System Synchronous Reset
            RX_DATA     : out std_logic_vector(17 downto 0);    -- Recieved Data (18 bits)
            CSL         : out std_logic;                        -- Chip Select (CNV)
            SCLK        : out std_logic;                        -- SPI CLK
            MISO_SDO    : in std_logic;                         -- SPI SDO
                                                                -- SPI SDI (Set High in HW, SDI is connected to VIO)
            ADC_READY   : out std_logic;                        -- ADC is ready to transmit data flag
            DV          : out std_logic                         -- Recieved Data Valid
    );  
end AD7984_Control;

architecture Behavioral of AD7984_Control is

constant CLK_FREQ           : integer := 50_000_000;                -- System Clock Frequency (in Hz)
constant CLK_PERIOD         : integer := 20;
constant SAMPLE_RATE        : integer := 44100;                     -- ADC Sample Rate (in Samples/s)
constant CLKS_PER_TRAX      : integer := CLK_FREQ/SAMPLE_RATE;      -- ADC Transaction (in Clocks)
constant CNV_HOLD           : integer := 500/CLK_PERIOD;            -- MAX CONV TIME / CLK_PERIOD (in Clocks)
constant STARTUPDELAY       : integer := 9;                         -- 200us Startup Delay (in TCYC_COUNT)

signal CLK_COUNTER          : unsigned(log2(CLKS_PER_TRAX) downto 0);
signal TCYC_COUNTER         : unsigned(log2(CLKS_PER_TRAX) downto 0);
signal TCYC_COUNT_START     : unsigned(log2(CLKS_PER_TRAX) downto 0);
signal BITCOUNT             : unsigned(log2(RX_DATA'LENGTH) downto 0);

signal iCSL                 : std_logic;
signal iSCLK                : std_logic;
signal iDV                  : std_logic;
signal iDV_Delayed          : std_logic;
signal iRXDATA              : std_logic_vector(17 downto 0);
signal RxData_Shift_Register: std_logic_vector(17 downto 0);
signal RxData_WriteFlag     : std_logic;
signal Enable_ADC_SPI       : std_logic;
signal Enable_ADC_SPI_prev  : std_logic;
signal Enable_ADC_SPI_Pulse : std_logic;

type state_t is (IDLE,CNV,AQUIRE);
signal state: state_t;
                        
begin

SPI_SM: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            iCSL                <= '1';
            iSCLK               <= '0';
            RxData_WriteFlag    <= '0';
            state               <= IDLE;
        else
            case(state) is
                when IDLE =>    iCSL    <= '1';
                                iSCLK   <= '0';
                                RxData_WriteFlag   <= '0';
                                if (Enable_ADC_SPI = '1') then
                                    state   <= CNV;
                                else
                                    state   <= IDLE;
                                end if;
                            
                when CNV =>     iSCLK   <= iSCLK;
                                if(CLK_COUNTER = TCYC_COUNT_START + CNV_HOLD) then
                                    iCSL    <= '0';
                                    state   <= AQUIRE;
                                else
                                    iCSL    <= iCSL;
                                    state   <= CNV;
                                end if;

                when AQUIRE =>  iCSL     <= iCSL;
                                if(BITCOUNT < 18) then
                                   iSCLK    <= not iSCLK;
                                   state    <= AQUIRE;
                                else
                                   iSCLK            <= iSCLK;
                                   state            <= IDLE;
                                   RxData_WriteFlag <= '1';
                                end if;

                when others => state <= IDLE;
            end case;
        end if;
   end if;
end process;

STRT_CNT_PROC: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            TCYC_COUNT_START <= (others => '0');
        else
            if(Enable_ADC_SPI_Pulse = '1') then
                TCYC_COUNT_START <= CLK_COUNTER;
            else
                TCYC_COUNT_START <= TCYC_COUNT_START;
            end if;
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

Enable_ADC_SPI <= '1' when TCYC_COUNTER = STARTUPDELAY else '0';

ENA_PULSE_GEN: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            Enable_ADC_SPI_prev <= '0';
        else
            Enable_ADC_SPI_prev <= Enable_ADC_SPI;
        end if;
    end if;
end process;

Enable_ADC_SPI_Pulse <= Enable_ADC_SPI and not Enable_ADC_SPI_prev;

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
            RxData_Shift_Register <= (others => '0');
            iRXDATA <= (others => '0');
            BITCOUNT <= (others => '0');
        elsif(RxData_WriteFlag = '1') then
            iRXDATA <= RxData_Shift_Register;
            BITCOUNT <= (others => '0');
        elsif(iCSL = '0'and iSCLK = '1') then
            RxData_Shift_Register <= RxData_Shift_Register(16 downto 0) & MISO_SDO;
            BITCOUNT <= BITCOUNT + 1;
        else
            RxData_Shift_Register <= RxData_Shift_Register;
            BITCOUNT <= BITCOUNT;
        end if;
    end if;
end process;

DV_PROC: process(CLK,RST) 
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            iDV <= '0';
            iDV_Delayed <= '0';
        else
            iDV <= RxData_WriteFlag;
            iDV_Delayed <= iDV;
        end if;
    end if;
end process;

CSL    <= iCSL;
SCLK    <= iSCLK;
RX_DATA <= iRXDATA;
DV <= iDV_Delayed when (Enable_ADC_SPI = '1') else '0';
ADC_READY <= Enable_ADC_SPI;

end Behavioral;
