----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/10/2016 01:51:08 AM
-- Design Name: 
-- Module Name: Lab2_project_top - Behavioral
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

entity Lab2_project_top is
    Port (  start_button       : in STD_LOGIC;
	        printer_sw         : in STD_LOGIC;
	        LEDS               : out STD_LOGIC_VECTOR (3 downto 0); 
            clk                : in STD_LOGIC
            );
end Lab2_project_top;

architecture Behavioral of Lab2_project_top is

    --New clock for calculator
    signal counter : STD_LOGIC_VECTOR(31 downto 0) := (others =>'0');
    
    --THIS IS THE ACTUAL CALCULATOR IT HAS THE PROVIDED INTERFACES
        component calculator 
            Port ( clk              : in STD_LOGIC;
                   reset            : in STD_LOGIC;
                   enable           : in STD_LOGIC;
                   PC               : out STD_LOGIC_VECTOR (7 downto 0);
                   instruction      : in STD_LOGIC_VECTOR (7 downto 0);
                   print            : out STD_LOGIC_VECTOR (7 downto 0);
                   num_instructions : in STD_LOGIC_VECTOR (7 downto 0));
        end component;
        --Calculator's signals
        signal s_calc_clk :         STD_LOGIC:='0';
        signal s_reset :            STD_LOGIC:='0';
        signal s_enable :           STD_LOGIC:='0';
        signal s_PC :               STD_LOGIC_VECTOR (7 downto 0):= (others =>'0');
        signal s_instruction :      STD_LOGIC_VECTOR (7 downto 0):= (others =>'0');
        signal s_print :            STD_LOGIC_VECTOR (7 downto 0):= (others =>'0');
        signal s_num_instructions:  STD_LOGIC_VECTOR (7 downto 0):= (others =>'0');
    
    --THIS IS THE INSTRUCTIONS MEMORY
    COMPONENT InstructionsMemory  
        generic ( INIT_BRAM_FILE: string );
        Port ( clk :            in STD_LOGIC;
               PC :             in STD_LOGIC_VECTOR (7 downto 0);
               Instruction :    out STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
               reset:           in STD_LOGIC;
               num_instructions: out STD_LOGIC_VECTOR (7 downto 0):=(others => '0') 
               );
    END COMPONENT;
    
    --Button debouncing
        signal deb_counter : STD_LOGIC_VECTOR (31 downto 0):=(others => '0');
        signal button_signal : STD_LOGIC;
        signal prev_button_signal : STD_LOGIC;
begin

    -- INSTANCES
    calc_0: calculator Port map (  clk               => s_calc_clk,
                                   reset             => s_reset,    
                                   enable            => s_enable,    
                                   PC                => s_PC,     
                                   instruction       => s_instruction,    
                                   print             => s_print,    
                                   num_instructions  => s_num_instructions      
                                 );
    
    inst_memory: InstructionsMemory generic map ( INIT_BRAM_FILE        => "../../../../../Instructions/example.txt" )
                                    Port map    (   clk                 => clk,
                                                    PC                  => s_PC, 
                                                    Instruction         => s_instruction,
                                                    reset               => '0',
                                                    num_instructions    => s_num_instructions
                                                    );
    -- connections
    with printer_sw select LEDS <=
                           s_print(7 downto 4) when '1',
                           s_print(3 downto 0) when '0';   

    genClkProc: process (clk) is
    begin

        if (rising_edge(clk)) then 
            counter<= counter +1 ;
            if (counter = x"07735940") then -- for 1Hz clock 
                counter <= (others => '0');
                s_Calc_clk <= not s_Calc_clk;
            end if;
       end if;
    end process;
    
    start_but: process(clk) is 
    begin 
        if (rising_edge (clk)) then
            if (prev_button_signal /= start_button) then
                   deb_counter <= x"00000001";
            end if;
            if (deb_counter > x"00000000") then
                deb_counter <= deb_counter + 1;
                if (deb_counter > x"023C3460") then
                    if (start_button = '1') then
                        deb_counter <= x"00000000";
                        s_enable <= not s_enable;
                    end if;
                end if;
            end if;
            prev_button_signal <= start_button;
         end if;
    end process;
    
    
end Behavioral;
