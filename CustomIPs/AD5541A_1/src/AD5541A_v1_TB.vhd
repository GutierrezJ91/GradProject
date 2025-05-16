----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/12/2025 10:29:12 PM
-- Design Name: 
-- Module Name: AD5541A_v1_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use STD.ENV.ALL;

entity AD5541A_v1_TB is
end AD5541A_v1_TB;

architecture Behavioral of AD5541A_v1_TB is

component AD5541A_v1 is
    generic (
        C_S00_AXIS_TDATA_WIDTH	: integer	:= 16
    );
    port (
        DIN				: out std_logic;
        CS_L			: out std_logic;
        LDAC_L 			: out std_logic;
        SCLK 			: out std_logic;

        s00_axis_aclk	    : in std_logic;
        s00_axis_aresetn	: in std_logic;
        s00_axis_tready	    : out std_logic;
        s00_axis_tdata	    : in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
        s00_axis_tvalid	    : in std_logic
    );
end component;

constant clkperiod      : time := 10ns;
signal DIN              : std_logic;
signal CS_L             : std_logic;
signal LDAC_L           : std_logic;
signal SCLK             : std_logic;
signal s00_axis_aclk    : std_logic := '0';
signal s00_axis_aresetn : std_logic := '1';
signal s00_axis_tready  : std_logic;
signal s00_axis_tdata   : std_logic_vector(15 downto 0);
signal s00_axis_tvalid  : std_logic;

type DATA_t is array (0 to 3) of std_logic_vector(15 downto 0);
signal MyData: DATA_t := ( 
    x"BABE",
    x"FEED",
    x"DEAD",
    x"BEAD"
    );

begin

    DUT: AD5541A_v1
     generic map(
        C_S00_AXIS_TDATA_WIDTH => 16
    )
     port map(
        DIN                 => DIN,
        CS_L                => CS_L,
        LDAC_L              => LDAC_L,
        SCLK                => SCLK,
        s00_axis_aclk       => s00_axis_aclk,
        s00_axis_aresetn    => s00_axis_aresetn,
        s00_axis_tready     => s00_axis_tready,
        s00_axis_tdata      => s00_axis_tdata,
        s00_axis_tvalid     => s00_axis_tvalid
    );

s00_axis_aclk <= not s00_axis_aclk after clkperiod/2;

process 
begin
    s00_axis_aresetn <= '0';
    wait for clkperiod*10;
    s00_axis_aresetn <= '1';
    wait;
end process;

process
begin
    wait until s00_axis_aresetn = '1';

    for i in 0 to 3 loop
        s00_axis_tdata <= MyData(i);
        s00_axis_tvalid <= '1';
        wait until s00_axis_tready = '1';
        wait until s00_axis_tready = '0';
        wait for clkperiod*2;
    end loop;
    wait;
end process;



end Behavioral;
