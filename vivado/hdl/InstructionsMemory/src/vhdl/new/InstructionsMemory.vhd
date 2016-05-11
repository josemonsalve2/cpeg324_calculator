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

--RAM INITIALIZATION CODE TAKEN FROM THE 
--XILINX XST User guide for Virtex-4 Virtex-5 Spartan-3 and Newer CPLD Devices

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.textio.all;  --include package textio.vhd

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InstructionsMemory is
    generic ( INIT_BRAM_FILE: string );
    Port ( clk :            in STD_LOGIC;
           PC :             in STD_LOGIC_VECTOR (7 downto 0);
           Instruction :    out STD_LOGIC_VECTOR (7 downto 0):=(others => '0');
           reset:           in STD_LOGIC;
           num_instructions: out STD_LOGIC_VECTOR (7 downto 0):= (others => '0') 
           );
end InstructionsMemory;

architecture Behavioral of InstructionsMemory is
    COMPONENT blk_mem_gen_0
      PORT (
            clka :  IN STD_LOGIC;
            ena :   IN STD_LOGIC;
            wea :   IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            dina :  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
      );
    END COMPONENT;
    
    --- CODE FOR BRAM INITIALIZATION see reference above. Modified
        type RamType is array(0 to 256) of bit_vector(7 downto 0);
           impure function InitRamFromFile (RamFileName : in string) return RamType is
              FILE RamFile : text open READ_MODE is RamFileName;
              variable RamFileLine : line;
              variable RAM : RamType;
              variable I : integer := 0;
           begin
              while (not endfile(RamFile)) loop
                 readline ( RamFile, RamFileLine );
                 read ( RamFileLine, RAM(I) );
                 I:=I+1;
              end loop;
              return RAM;
           end function;
           impure function numInstructions (RamFileName : in string) return std_logic_vector(7 downto 0) is
                FILE RamFile : text is in RamFileName;
                 variable RamFileLine : line;
                 variable I : integer := 0;
                begin
                 while (not endfile(RamFile)) loop
                    readline ( RamFile, RamFileLine );
                    I:=I+1;
                 end loop;
                 return std_logic_vector(to_unsigned(I,8));
           end function;
       -- Signal for telling the system we are initializing the ram
       signal init_ram: STD_LOGIC := '1';
       
       --Ram init state machine and used counters
       type type_ram_init_states is (slow_start, writing, finished);
       signal ram_init_state :      type_ram_init_states := slow_start;
       signal RAM_INIT_COUNTER :    STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
       signal init_counter:         unsigned(7 downto 0) := (others => '0');
              
       --Read value from file
       signal RAM :                 RamType := InitRamFromFile(INIT_BRAM_FILE);
       
       -- Signals going to BRAM       
       signal init_address:         STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   
   --BRAM SIGNALS
       signal write_enable :        STD_LOGIC_VECTOR (0 downto 0) := (others => '1');
       signal data_write :          STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
       signal address :             STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   -- Other signals
       signal s_numInstructions : STD_LOGIC_VECTOR (7 downto 0) := numInstructions(INIT_BRAM_FILE);
begin

    --Connections
    num_instructions <= s_numInstructions;

    bram_0 : blk_mem_gen_0
      PORT MAP (
        clka => clk,
        ena => '1',
        wea => write_enable,
        addra => address,
        dina => data_write,
        douta => Instruction
      );
    
    with init_ram select address <= PC            when '0',
                                    init_address  when '1';
    
    init_bram_process: process (clk,reset) is
    begin
        if (reset = '1') then 
                init_ram<='1';
                ram_init_state <= slow_start;
        end if;
        if (rising_edge(clk) and init_ram = '1') then
            write_enable(0) <= '1';
            case ram_init_state is
                when slow_start =>
                    init_counter <= init_counter + 1;
                    if (init_counter = x"02") then   
                        ram_init_state <= writing;
                        init_counter <= (others => '0'); 
                    end if;    
                when writing =>
                    if (RAM_INIT_COUNTER = s_numInstructions) then 
                        ram_init_state <= finished;
                    else 
                        init_address <= RAM_INIT_COUNTER;
                        data_write <= to_stdLogicVector(RAM(to_integer(unsigned(RAM_INIT_COUNTER))));
                        init_counter <= (init_counter + 1);
                        if (init_counter = x"04") then 
                            RAM_INIT_COUNTER <= RAM_INIT_COUNTER + 1;
                            init_counter <= (others => '0'); 
                        end if;
                    end if;
                when finished =>
                     RAM_INIT_COUNTER <= (others => '0');
                     init_counter <= (others => '0');
                     write_enable(0) <= '0';
                     init_ram <= '0';
                when others =>
            end case;
        end if;
    end process;
    
    instMem_proc: process (reset)
    begin
        
    end process;

end Behavioral;
