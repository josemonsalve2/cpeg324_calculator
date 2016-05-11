----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/09/2016 11:44:29 PM
-- Design Name: 
-- Module Name: InstructionMemory_tb - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InstructionMemory_tb is
--  Port ( );
end InstructionMemory_tb;

architecture Behavioral of InstructionMemory_tb is

    constant clk_period : time := 8 ns;

    component InstructionsMemory 
        Port ( clk :            in STD_LOGIC;
               PC :             in STD_LOGIC_VECTOR (7 downto 0);
               Instruction :    out STD_LOGIC_VECTOR (7 downto 0);
               Address :        in STD_LOGIC_VECTOR (7 downto 0);
               data_write :     in STD_LOGIC_VECTOR (7 downto 0);
               data_read :      out STD_LOGIC_VECTOR (7 downto 0);
               write_enable :   in STD_LOGIC;
               reset:           in STD_LOGIC;
               num_instructions: out STD_LOGIC_VECTOR (7 downto 0):=(others => '0') 
               );
    end component;
       

    SIGNAL clk :                STD_LOGIC:='0';
    SIGNAL PC :                 STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    SIGNAL Instruction :        STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    SIGNAL Address :            STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    SIGNAL data_write :         STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    SIGNAL data_read :          STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    SIGNAL write_enable :       STD_LOGIC:='0';
    SIGNAL reset:               STD_LOGIC:='0';
    SIGNAL num_instructions:    STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
    
    signal counter :            STD_LOGIC_VECTOR (31 downto 0):=(others => '0');
    
begin
    instMem_0: InstructionsMemory
    PORT MAP (
        clk                 => clk,
        PC                  => PC,
        Instruction         => Instruction,
        Address             => Address,
        data_write          => data_write,
        data_read           => data_read,
        write_enable        => write_enable,
        reset               => reset,
        num_instructions    => num_instructions
    );
    
    clk_proc_0: process is 
        begin 
                clk <= '0';
                wait for clk_period/2;  --for 0.5 ns signal is '0'.
                clk <= '1';
                wait for clk_period/2;  --for next 0.5 ns signal is '1'.
        end process;
        
   inst_mem_proc: process (clk)
        begin
        counter <= counter +1;
        if counter = x"0000" & x"0000" then
            reset <= '1';
        elsif counter = x"0000" & x"000A" then
            reset <= '0';
        elsif counter = x"0000" & x"001C" then
            Address <= "00000001";
            data_write <= "10101010";
            write_enable <= '1';
        elsif counter = x"0000" & x"0020" then
            write_enable <= '0';
        elsif counter = x"0000" & x"0035" then
            PC<= PC + 1;
        elsif counter = x"0000" & x"000A" then
        elsif counter = x"0000" & x"000A" then
        
        end if;

    end process;
end Behavioral;
