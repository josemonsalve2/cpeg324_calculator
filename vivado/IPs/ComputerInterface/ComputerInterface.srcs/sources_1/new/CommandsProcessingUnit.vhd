----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/03/2016 08:54:47 PM
-- Design Name: 
-- Module Name: CompInterface - Behavioral
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
--use IEEE.STD_LOGIC_ARITH.ALL
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use ieee.math_real.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CommandsProcessingUnit is
    generic (FIFO_WIDTH: positive := 8);
    port (
       -- Ports for Reading from UART buffer
       read_fifo_r_data:        in STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0);
       read_fifo_r_data_en:     out STD_LOGIC := '0';
       read_fifo_empty:         in STD_LOGIC;
       --Ports for writting to UART buffer
       write_fifo_w_data:       out STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0) := (others => '0');
       write_fifo_w_data_en:    out STD_LOGIC := '0';
       write_fifo_full:         in STD_LOGIC;
       --Ports for going to memory
       memory_Address:          out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
       memory_read_port:        in STD_LOGIC_VECTOR(7 downto 0);
       memory_write_port:       out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
       memory_write_en:         out STD_LOGIC := '0';
       --Ports for getting the print command from the calculator
       print_value:             in STD_LOGIC_VECTOR(7 downto 0);
       -- Other ports
       sys_clk:                 in STD_LOGIC;
       enable:                  in STD_LOGIC;
       reset:                   in STD_LOGIC;
       --For the starting of the calculator
       start_comm:              out STD_LOGIC:= '0'
    );
end CommandsProcessingUnit;

architecture Behavioral of CommandsProcessingUnit is

    --- Type and signal for the state machine
    type type_processing_states is (
        waiting_state,              --Nothing to be done
        new_command,                --A new command in the read queue
        write_memory_command,       --The new command is a write to memory, wait for the address to write
        write_memory_value,         --Address obtained, waiting for value that we are writing to
        writting_to_memory,         --Interaction with memory 
        read_memory_command,        --The new command is a read from memory, wait for the addres to read from
        reading_from_memory,        --Read memory from this address
        sending_read_value_2_uart,  --After reading we need to put the value in the UART write FIFO
        printing_value,             --A new print value. The value of the print port is different to the previous
        start_command               --To enable the calculator
        );
        --State 
    signal processing_state : type_processing_states := waiting_state;
       
       
    -- For new command
        signal incoming_command: STD_LOGIC_VECTOR(7 downto 0) := (others => '0');     

    -- For reading command
        constant READ_COMMAND_CODE    : STD_LOGIC_VECTOR (7 downto 0) := "10101010";
        signal   reading_from_address : STD_LOGIC_VECTOR (7 downto 0) := "ZZZZZZZZ";
        signal   counter_for_reading  : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
        signal   read_value           : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

    -- For writing command
        constant WRITE_COMMAND_CODE   : STD_LOGIC_VECTOR (7 downto 0) := "01010101";
        signal   writing_to_address   : STD_LOGIC_VECTOR (7 downto 0) := "ZZZZZZZZ";
        signal   value_to_write       : STD_LOGIC_VECTOR (7 downto 0) := "ZZZZZZZZ";
        signal   counter_for_writing  : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
    
    --For start command
        constant START_COMMAND_CODE   : STD_LOGIC_VECTOR (7 downto 0) := "11111111";
        
    
    -- For printing
        signal printed_value: STD_LOGIC_VECTOR (7 downto 0) := (others => 'Z') ;
        
    -- Watchdog of the state machine, to avoid being stall on certain places
        signal watchdog_states: STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
        constant watchdog_count_to : STD_LOGIC_VECTOR (31 downto 0) := x"00" & x"BEBC20"; --For 100 ms (taking into account 125 MHz;
begin

    com_proc: process (sys_clk) is
        --For decoding a command:
    begin
        
        if rising_edge(sys_clk) and enable = '1' then
            if reset = '1' then --Reseting the command processing unit
                processing_state <= waiting_state;
                read_fifo_r_data_en  <= '0';
                write_fifo_w_data <= (others => '0');
                write_fifo_w_data_en <= '0';
                memory_Address <= (others => '0');
                memory_write_port <= (others => '0');
                memory_write_en <= '0';
                start_comm<= '0';
                printed_value <= print_value;
            elsif (watchdog_states = watchdog_count_to) then
                processing_state <= waiting_state;
                processing_state <= waiting_state;
                read_fifo_r_data_en  <= '0';
                write_fifo_w_data <= (others => '0');
                write_fifo_w_data_en <= '0';
                memory_Address <= (others => '0');
                memory_write_port <= (others => '0');
                memory_write_en <= '0';
                printed_value <= print_value;
                start_comm<= '0';
            else  
                --Make sure to put down the read and write strobes from the fifo
                read_fifo_r_data_en <= '0';
                write_fifo_w_data_en <= '0';
                watchdog_states <= watchdog_states + 1;
                start_comm<= '0';
                --State machine functionality
                case (processing_state) is
                
                    when waiting_state => -- Waiting for a command to process or a printing value
                       --For printing order:  Printing has priority over UART commands
                       if (not (unsigned (print_value) = unsigned (printed_value))) and ( not(unsigned (print_value) = "ZZZZZZZZ") ) then 
                            processing_state <= printing_value;
                       --There is some command to read from the FIFO
                       elsif (read_fifo_empty = '0') then  
                            incoming_command <= read_fifo_r_data;
                            processing_state <= new_command;
                            -- ACK The read value from the FIFO
                            read_fifo_r_data_en <= '1';
                       end if;
                       watchdog_states <= (others => '0');
                    
                   --When a new command arrives
                   when new_command => -- Decode the new command
                       if (incoming_command = READ_COMMAND_CODE) then -- The new command is a read from memory
                           processing_state <= read_memory_command;
                       elsif (incoming_command = WRITE_COMMAND_CODE) then -- The new command is a write to memory
                           processing_state <= write_memory_command;
                       elsif (incoming_command = START_COMMAND_CODE) then
                           processing_state <= start_command;
                       else --Unrecognized command
                           processing_state <= waiting_state; 
                       end if;
                       incoming_command <= (others => '0');
                   
                   -- For writing to memory
                   when write_memory_command => -- The decoded command was a write to memory ... wait for the address
                       if (read_fifo_empty = '0') then --Assume the top value contains the address
                            writing_to_address <= read_fifo_r_data;
                            -- ACK The read value from the FIFO  
                            read_fifo_r_data_en <= '1';
                            processing_state <= write_memory_value;
                            counter_for_writing <= (others => '0'); -- reset the writting counter
                       end if;
                   when write_memory_value => -- The decoded command was a write to memory ... wait for the address
                       -- Since we are reading two values consecutively from the FIFO we have to wait some time
                       if counter_for_writing < "0011" then
                            counter_for_writing <= counter_for_writing + 1;
                       elsif (read_fifo_empty = '0') then --Assume the top value contains the address
                           value_to_write <= read_fifo_r_data;
                           -- ACK The read value from the FIFO  
                           read_fifo_r_data_en <= '1';
                           processing_state <= writting_to_memory;
                           counter_for_writing <= (others => '0'); -- reset the writting counter
                      end if;
                   when writting_to_memory => -- Time to write to memory. Set the address and the value, wait 3 cycles, set the write enable, wait three cycles finish writing 
                       if (counter_for_writing = "0000") then 
                          memory_Address <= writing_to_address;
                          memory_write_port <= value_to_write;
                       elsif (counter_for_writing = "0011") then --after 3 cycles enable the writing
                          memory_write_en <= '1';
                       elsif (counter_for_writing = "0110") then --After another 3 cycles, we assume the write is done
                          memory_write_en <= '0';
                          processing_state <= waiting_state;
                       end if;
                       -- increment counter
                       counter_for_writing <= counter_for_writing + 1;
                   -- For reading from memory
                   when read_memory_command => -- Waiting for the address
                       if (read_fifo_empty = '0') then --Assume the top value contains the address
                          reading_from_address <= read_fifo_r_data;
                          -- ACK The read value from the FIFO  
                          read_fifo_r_data_en <= '1';
                          processing_state <= reading_from_memory;
                          counter_for_reading <= (others => '0'); -- reset the writting counter
                       end if;
                   when reading_from_memory => -- reading from the memory
                       if (counter_for_reading = "0000") then 
                         memory_Address <= reading_from_address;
                      elsif (counter_for_reading = "0011") then --after 3 cycles we can assume the value is in the reading port
                         read_value <= memory_read_port;
                      elsif (counter_for_reading = "0110") then 
                          processing_state <= sending_read_value_2_uart;
                      end if;
                      -- increment counter
                      counter_for_reading <= counter_for_reading + 1;
                   when sending_read_value_2_uart =>
                      if (write_fifo_full = '0') then
                        write_fifo_w_data_en <= '1';
                        write_fifo_w_data <= read_value;
                        processing_state <= waiting_state;
                      end if;
                  
                   --For printing the calculated value
                   when printing_value =>
                      printed_value <= print_value;
                      if (write_fifo_full = '0') then
                        write_fifo_w_data_en <= '1';
                        write_fifo_w_data <= print_value;
                        processing_state <= waiting_state;
                      end if;
                      
                   --For starting the calculator 
                   when start_command =>
                      start_comm<= '1';
                  when others =>
                      processing_state <= waiting_state;
               end case;
            end if;
        end if;
    end process; 


end Behavioral;
