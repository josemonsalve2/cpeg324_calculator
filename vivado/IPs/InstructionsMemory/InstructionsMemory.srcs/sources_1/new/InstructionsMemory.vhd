----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/09/2016 02:23:00 PM
-- Design Name: 
-- Module Name: InstructionsMemory - Behavioral
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

entity InstructionsMemory is
    Port ( clk :            in STD_LOGIC;
           PC :             in STD_LOGIC_VECTOR (7 downto 0);
           Instruction :    out STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
           Address :        in STD_LOGIC_VECTOR (7 downto 0);
           data_write :     in STD_LOGIC_VECTOR (7 downto 0);
           data_read :      out STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
           write_enable :   in STD_LOGIC;
           reset:           in STD_LOGIC;
           num_instructions: out STD_LOGIC_VECTOR (7 downto 0):=(others => '0') 
           );
end InstructionsMemory;

architecture Behavioral of InstructionsMemory is
    COMPONENT blk_mem_gen_0
      PORT (
            clka :  IN STD_LOGIC;
            ena :   IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            clkb :  IN STD_LOGIC;
            enb :   IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    END COMPONENT;
        
    --For the PC update
    type type_instruction_change_states is 
    (
        waiting_for_new_PC,
        waiting_for_memory,
        assinging_instruction

    );
    signal instruction_change_state: type_instruction_change_states := waiting_for_new_PC;
    signal prev_PC: STD_LOGIC_VECTOR (7 downto 0) := (others => 'Z');
    --For Instruction update;
    signal sel: STD_LOGIC:= '0'; -- 0 for Address and 1 for PC
    signal s_data_read_mem: STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
    signal s_data_read_address: STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
    signal read_instruction_counter: STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
    signal s_num_instructions : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
    
begin

   --Connections
   with sel select s_data_read_address <= PC when '1',
                                          Address when '0',
                                          (others => 'X') when others;
   with sel select data_read <= s_data_read_mem when '0',
                                "ZZZZZZZZ" when '1',
                                (others => 'X') when others;
   num_instructions<=  s_num_instructions;                           
                            
    bram_0 : blk_mem_gen_0
      PORT MAP (
        clka => clk,
        ena => '1',
        wea(0) => write_enable,
        addra => Address(6 downto 0),
        dina => data_write,
        clkb => clk,
        enb  => '1',
        addrb => s_data_read_address(6 downto 0),
        doutb => s_data_read_mem
      );
    
    instMem_proc: process (clk,PC,reset)
    begin
        if (reset = '1') then -- On reset read the first instruction
                 instruction_change_state <= waiting_for_memory;
        elsif (rising_edge(clk)) then
            case instruction_change_state is
                when waiting_for_new_PC =>
                            read_instruction_counter <= (others => '0'); 
                when waiting_for_memory =>
                    sel <= '1';
                    read_instruction_counter <= read_instruction_counter +1;
                    if read_instruction_counter = "00000110" then
                        instruction_change_state <= assinging_instruction;
                    end if;
                when assinging_instruction =>
                    Instruction <= s_data_read_mem;
                    sel <= '0';
                    instruction_change_state <= waiting_for_new_PC;
                when others => 
                    instruction_change_state <= waiting_for_new_PC;
                    sel <= '0';
             end case;
         end if;
         if (PC /= prev_PC and instruction_change_state = waiting_for_new_PC) then
             prev_PC <= PC;
             instruction_change_state <= waiting_for_memory;
         end if;   
    end process;

    countInstructions: process (write_enable, reset)
    begin
        if (reset = '1') then
            s_num_instructions <= (others => '0');
        elsif (rising_edge(write_enable)) then
            s_num_instructions <= s_num_instructions + 1;
        end if;
    end process;

end Behavioral;
