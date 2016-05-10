----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/09/2016 12:13:53 AM
-- Design Name: 
-- Module Name: CommandsProcessingUnit_tb - Behavioral
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
use ieee.math_real.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity CommandsProcessingUnit_tb is
   generic (FIFO_WIDTH: positive := 8;
            FIFO_DEPTH : positive := 1024); 
--  Port ( );
end CommandsProcessingUnit_tb;

architecture Behavioral of CommandsProcessingUnit_tb is
    ---- FIFO COMPONENTS
    component GENERIC_FIFO
    generic (
            FIFO_WIDTH : positive := 32;
            FIFO_DEPTH : positive := 1024
        );
        port (
            clock       : in std_logic;
            reset       : in std_logic;
            write_data  : in std_logic_vector(FIFO_WIDTH-1 downto 0);
            read_data   : out std_logic_vector(FIFO_WIDTH-1 downto 0);
            write_en    : in std_logic;
            read_en     : in std_logic;
            full        : out std_logic;
            empty       : out std_logic;
            level       : out std_logic_vector(
                integer(ceil(log2(real(FIFO_DEPTH))))-1 downto 0
            )
        );
        end component;
    
    --Signal for read buffer;
    signal read_buffer_write_data:  std_logic_vector(FIFO_WIDTH-1 downto 0):= (others => '0');
    signal read_buffer_write_enable: std_logic := '0'; 
    signal read_buffer_full: std_logic := '0'; 
    signal read_buffer_level: std_logic_vector( integer(ceil(log2(real(FIFO_DEPTH))))-1 downto 0):= (others =>'0');

    --Signals for the write buffer
    signal write_buffer_read_data: std_logic_vector (FIFO_WIDTH-1 downto 0):= (others => '0');
    signal write_buffer_read_enable :std_logic := '0';
    signal write_buffer_empty : std_logic := '0';
    signal write_buffer_level: std_logic_vector( integer(ceil(log2(real(FIFO_DEPTH))))-1 downto 0):= (others =>'0');

    
    component CommandsProcessingUnit 
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
           reset:                   in STD_LOGIC
        );
    end component;
    
      -- Ports for Reading from UART buffer
     signal s_read_fifo_r_data:        STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0) := (others => '0');
     signal s_read_fifo_r_data_en:     STD_LOGIC := '0';
     signal s_read_fifo_empty:         STD_LOGIC := '0';
     --Ports for writting to UART buffer
     signal s_write_fifo_w_data:       STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0) := (others => '0');
     signal s_write_fifo_w_data_en:    STD_LOGIC := '0';
     signal s_write_fifo_full:         STD_LOGIC := '0';
     --Ports for going to memory
     signal s_memory_Address:          STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_read_port:        STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_write_port:       STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_write_en:         STD_LOGIC := '0';
     --Ports for getting the print command from the calculator
     signal s_print_value:             STD_LOGIC_VECTOR(7 downto 0) := (others => 'Z');
     -- Other ports
     signal clk:                       STD_LOGIC := '0';
     signal s_enable:                  STD_LOGIC := '0';
     signal s_reset:                   STD_LOGIC := '0';
     
     signal counter : STD_LOGIC_VECTOR (31 downto 0) := (others => '0');
     
begin

    CommandsProcessingUnit_1: CommandsProcessingUnit 
    GENERIC MAP (FIFO_WIDTH => 8)
    PORT MAP (
        -- Ports for Reading from UART buffer
       read_fifo_r_data         => s_read_fifo_r_data,
       read_fifo_r_data_en      => s_read_fifo_r_data_en,
       read_fifo_empty          => s_read_fifo_empty,
       --Ports for writting to UART buffer
       write_fifo_w_data        => s_write_fifo_w_data,
       write_fifo_w_data_en     => s_write_fifo_w_data_en,
       write_fifo_full          => s_write_fifo_full,
       --Ports for going to memory
       memory_Address           => s_memory_Address,
       memory_read_port         => s_memory_read_port,
       memory_write_port        => s_memory_write_port,
       memory_write_en          => s_memory_write_en,
       --Ports for getting the print command from the calculator
       print_value              => s_print_value,
       -- Other ports
       sys_clk                  => clk,
       enable                   => s_enable,
       reset                    => s_reset
    );
    
    
    
    read_buffer : GENERIC_FIFO
    GENERIC MAP (
             FIFO_WIDTH => FIFO_WIDTH,
             FIFO_DEPTH => FIFO_DEPTH)
    PORT MAP (
             clock       => clk,
             reset       => s_reset,
             write_data  => read_buffer_write_data,
             read_data   => s_read_fifo_r_data,
             write_en    => read_buffer_write_enable,
             read_en     => s_read_fifo_r_data_en,
             full        => read_buffer_full,
             empty       => s_read_fifo_empty,
             level       => read_buffer_level
     );
              
    write_buffer : GENERIC_FIFO
     GENERIC MAP (
              FIFO_WIDTH => FIFO_WIDTH,
              FIFO_DEPTH => FIFO_DEPTH)
     PORT MAP (
              clock       => clk,
              reset       => s_reset,
              write_data  => s_write_fifo_w_data,
              read_data   => write_buffer_read_data,
              write_en    => s_write_fifo_w_data_en,
              read_en     => write_buffer_read_enable,
              full        => s_write_fifo_full,
              empty       => write_buffer_empty,
              level       => write_buffer_level
      );
             
     

    clk_process: process is
    begin
            clk <= '0';
            wait for 10 ns;
            clk <= '1';
            wait for 10 ns;
    end process;

    test_bench_proc: process (clk) is
    begin 
        if rising_edge (clk) then 
            read_buffer_write_enable<='0';
            counter <= counter +1;
            if counter = x"0000" & x"0000" then
                s_enable <= '1';
                s_reset <= '1';

            elsif counter = x"0000" & x"000A" then --- testing the print
                s_reset <= '0';
            elsif counter = x"0000" & x"000B" then 
                s_print_value <= "01001101";
            elsif counter = x"0000" & x"0010" then
                read_buffer_write_enable<='1';
                read_buffer_write_data <= "10101010"; --testing the read command
            elsif counter = x"0000" & x"0013" then    
                read_buffer_write_enable<='1';
                read_buffer_write_data <= "11110000";
            elsif counter = x"0000" & x"0020" then
                read_buffer_write_enable<='1';
                read_buffer_write_data <= "01010101"; --testing the write command
            elsif counter = x"0000" & x"0023" then    
                read_buffer_write_enable<='1';
                read_buffer_write_data <= "11110011"; -- write address
                                
            elsif counter = x"0000" & x"0026" then    
                read_buffer_write_enable<='1';
                read_buffer_write_data <= "11100101"; --write value
            elsif counter = x"0000" & x"0000" then
                null;
            end if; 
        end if; 
    end process;

end Behavioral;
