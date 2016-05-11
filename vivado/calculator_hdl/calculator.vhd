----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2016 02:10:03 AM
-- Design Name: 
-- Module Name: calculator - Behavioral
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
use IEEE.STD_LOGIC_SIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity calculator is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           enable : in STD_LOGIC;
           PC : out STD_LOGIC_VECTOR (7 downto 0);
           instruction : in STD_LOGIC_VECTOR (7 downto 0);
           print : out STD_LOGIC_VECTOR (7 downto 0);
           num_instructions: in STD_LOGIC_VECTOR (7 downto 0));
end calculator;

architecture Behavioral of calculator is
    signal current_pc: unsigned (7 downto 0 );
begin
    --Connections
    PC<= std_logic_vector(current_pc);
    
    --Process
    clk_process: process (clk)
    begin
        if rising_edge(clk) and enable = '1' then
            if (current_pc < unsigned (num_instructions) + 1) then 
                    current_pc <= current_pc +1;
                    print <= instruction;
            end if;
        end if;
    end process;

end Behavioral;
