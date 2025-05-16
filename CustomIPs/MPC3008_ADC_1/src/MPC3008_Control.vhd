---------------------------------------------------------------------------------- 
-- Engineer: Jorge Gutierrez
-- Create Date: 02/22/2025 08:00:12 PM

-- Module Name: MPC3008_Control - Behavioral
-- Target Devices: Zybo Z7-10
-- Tool Versions: Vivado 2023.2
-- Description: MPC3008 Firmware Driver
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity MPC3008_Control is
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
end MPC3008_Control;

architecture Behavioral of MPC3008_Control is

constant CLKFREQ            : integer := 50_000_000;
constant FSAMPLE            : integer := 125_000;
constant FSCLK              : integer := 18*FSAMPLE;            -- 18*125000 = 2.25E6
constant TCYC_CNT_MAX       : integer := CLKFREQ/FSAMPLE;       -- 50E6/125000 = 400  (needs 9 bits)
constant SCLK_CNT_MAX       : integer := CLKFREQ/(2*FSCLK);     -- 50E6/(2*2.25E6) = 11 (needs 13 bits)
constant AIN_CNT_MAX        : integer := 4;

signal CLK_CNTR             : unsigned(8 downto 0);
signal SCLK_CNTR            : unsigned(3 downto 0);
signal BIT_CNTR             : unsigned(4 downto 0);
signal AIN_CNTR             : unsigned(1 downto 0);
signal SMPL_CNTR            : unsigned(4 downto 0);
signal TXREG                : std_logic_vector(15 downto 0);
signal RXREG                : std_logic_vector(9 downto 0);
signal TXRX_REG_WriteFlag         : std_logic;
signal RX_REG_ReadFlag            : std_logic;
signal iDV                  :std_logic;
signal iDV_Delayed          :std_logic_vector(1 downto 0);

signal iSCLK                : std_logic;
signal iSCLK_prev           : std_logic;
signal iCSL                 : std_logic;
signal ENA                  : std_logic;

type ain_array is array (0 to 3) of std_logic_vector(9 downto 0);
signal AIN_REG              : ain_array;

signal iAIN0_OUT             : std_logic_vector(9 downto 0);
signal iAIN1_OUT             : std_logic_vector(9 downto 0);
signal iAIN2_OUT             : std_logic_vector(9 downto 0);
signal iAIN3_OUT             : std_logic_vector(9 downto 0);


begin

CNTR_PROC: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if (RST = '1') then
            CLK_CNTR <= (others => '0');
        else
            if(CLK_CNTR < TCYC_CNT_MAX-1) then
                CLK_CNTR <= CLK_CNTR + 1;
            else
                CLK_CNTR <= (others => '0');
            end if;
        end if;
    end if;
end process;


AIN_CNTR_PROC: process(CLK,RST) 
begin
    if rising_edge(CLK) then
        if (RST = '1') then 
            AIN_CNTR <= (others => '0');
        else
            if (CLK_CNTR = TCYC_CNT_MAX-1) then 
                if(AIN_CNTR < AIN_CNT_MAX - 1) then
                    AIN_CNTR <= AIN_CNTR + 1;
                else
                    AIN_CNTR <= (others => '0');
                end if;
            else
                AIN_CNTR <= AIN_CNTR;
            end if;
        end if;
    end if;
end process;


SCLK_GEN: process(CLK,RST)
begin
    if rising_edge(CLK) then 
        if (RST = '1') then 
            SCLK_CNTR <= ( others => '0');
            iSCLK  <= '0';
        else
            if(iCSL = '0') then
                if(SCLK_CNTR < SCLK_CNT_MAX-1) then 
                    SCLK_CNTR <= SCLK_CNTR + 1;
                else
                    SCLK_CNTR <= (others => '0');
                    iSCLK <= not iSCLK;
                end if;
            else
                SCLK_CNTR <= (others => '0');
                iSCLK <= '0';
            end if;
        end if;
    end if;
end process;

TX_DATA_CNTRL: process(CLK,RST)
    begin
        if rising_edge(CLK) then
            if(RST = '1') then
                TXREG <= (others => '0');
            elsif(TXRX_REG_WriteFlag = '1') then
                TXREG <= "110" & std_logic_vector(AIN_CNTR) & "00000000000";
            elsif(iSCLK_prev = '1' and iSCLK = '0') then
                TXREG <= TXREG(14 downto 0) & '0';
            else
                TXREG <= TXREG;
            end if;
        end if;
    end process;

RX_DATA_CNTRL: process(CLK,RST)
begin
    if rising_edge(CLK) then
        if(RST = '1') then
            RXREG <= (others => '0');
            BIT_CNTR <= (others => '0');
        elsif(TXRX_REG_WriteFlag = '1') then
            RXREG <= (others => '0');
            BIT_CNTR <= (others => '0');
        elsif(iSCLK_prev = '0' and iSCLK = '1') then
            BIT_CNTR <= BIT_CNTR + 1;
            if(BIT_CNTR > 6) then
                RXREG <= RXREG(8 downto 0) & DOUT;
            else
                RXREG <= RXREG;
            end if;
        else
            RXREG <= RXREG;
            BIT_CNTR <= BIT_CNTR;
        end if;
    end if;
end process;


PREV_SCLK_PROC: process(CLK,RST)
begin
    if rising_edge(CLK) then 
        if(RST = '1') then 
            iSCLK_prev <= '0';
        else
            iSCLK_prev <= iSCLK;
        end if;
    end if;
end process;

RX_DATA_PROC: process(CLK,RST)
begin
    if rising_edge(CLK) then 
        if(RST = '1') then
            AIN_REG <= (others => (others => '0'));
        else
            if(RX_REG_ReadFlag = '1') then 
                case(AIN_CNTR) is 
                    when "00" => AIN_REG(0) <= RXREG;
                    when "01" => AIN_REG(1) <= RXREG;
                    when "10" => AIN_REG(2) <= RXREG;
                    when "11" => AIN_REG(3) <= RXREG;
                    when others => AIN_REG <= AIN_REG;
                end case;
            else
                AIN_REG <= AIN_REG;
            end if;
        end if;
    end if;
end process;

SMPL_CNT_PROC: process(CLK,RST) 
begin
    if rising_edge(CLK) then 
        if(RST = '1') then
            SMPL_CNTR <= (others => '0');
        else
            if(SMPL_CNTR < 32) then 
                if(AIN_CNTR = AIN_CNT_MAX-1 and CLK_CNTR = TCYC_CNT_MAX-1) then
                    SMPL_CNTR <= SMPL_CNTR + 1;
                else
                    SMPL_CNTR <= SMPL_CNTR;
                end if;
            else
                SMPL_CNTR <= (others => '0');
            end if;
        end if;
    end if;
end process;


OUTPUT_PROC: process(CLK,RST) 
begin
    if rising_edge(CLK) then 
        if(RST = '1') then 
            iAIN0_OUT  <= (others => '0');
            iAIN1_OUT  <= (others => '0');
            iAIN2_OUT  <= (others => '0');
            iAIN3_OUT  <= (others => '0');
        elsif(iDV = '1') then 
            iAIN0_OUT  <= AIN_REG(0);
            iAIN1_OUT  <= AIN_REG(1);
            iAIN2_OUT  <= AIN_REG(2);
            iAIN3_OUT  <= AIN_REG(3);
        else
            iAIN0_OUT  <= iAIN0_OUT;
            iAIN1_OUT  <= iAIN1_OUT;
            iAIN2_OUT  <= iAIN2_OUT;
            iAIN3_OUT  <= iAIN3_OUT;
        end if;
    end if;
end process;

DELAY_DV_FLAG: process(CLK,RST)
begin
    if rising_edge(CLK) then 
        if (RST = '1') then 
            iDV_Delayed <= "00";
        else
            iDV_Delayed(0) <= iDV;
            iDV_Delayed(1) <= iDV_Delayed(0);
        end if;
    end if;
end process;

iDV <= '1' when (SMPL_CNTR = 2 and CLK_CNTR = 5 and AIN_CNTR = 0) else '0';
DIN <= TXREG(15) when (iCSL = '0') else 'Z'; 
TXRX_REG_WriteFlag <= '1' when (CLK_CNTR = 7 and ENA = '1') else '0';
RX_REG_ReadFlag <= '1' when (CLK_CNTR = 399 and ENA = '1') else '0';
iCSL <= '0' when (CLK_CNTR > 15 and ENA = '1') else '1';
ENA <= '1' when (SMPL_CNTR = 1) else '0';
SCLK <= iSCLK when (iCSL = '0') else '0';
CSL <= iCSL;
DV <= iDV_Delayed(1);
AIN0_OUT <= iAIN0_OUT;
AIN1_OUT <= iAIN1_OUT;
AIN2_OUT <= iAIN2_OUT;
AIN3_OUT <= iAIN3_OUT;

end Behavioral;
