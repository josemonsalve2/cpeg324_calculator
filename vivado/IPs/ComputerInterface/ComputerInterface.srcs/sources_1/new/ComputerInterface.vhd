----------------------------------------------------------------------------------
-- Company: CAPSL
-- Engineer: Jose M Monsalve Diaz
-- 
-- Create Date: 04/21/2016
-- Design Name: Commands processing unit for Project 2
-- Module Name: CommandsProcessingUnit
-- Project Name: Project 2 CPEG324
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
use ieee.math_real.all;
use IEEE.NUMERIC_STD.ALL;

entity ComputerInterface is
    generic (
        FIFO_WIDTH : positive := 8;
        FIFO_DEPTH : positive := 512;
        baud       : positive     := 9600;
        clock_frequency: positive :=125000000
    );
    Port (
    --UART PORTS
        UART_RX:                in STD_LOGIC;
        UART_TX:                out STD_LOGIC := '0';
    -- Memory Ports
        memory_Address:         out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        memory_read_port:       in STD_LOGIC_VECTOR(7 downto 0);
        memory_write_port:      out STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
        memory_write_en:        out STD_LOGIC := '0';
    -- Calculator Print Port
        print_value:            in STD_LOGIC_VECTOR(7 downto 0);
    --Other ports
        clk:                    in  STD_LOGIC ;
        enable:                 in  STD_LOGIC ;
        reset:                  in  STD_LOGIC ;
        start_comm:             out STD_LOGIC := '0'
     );
end ComputerInterface;

architecture behavioral of ComputerInterface is


    --UART COMPONENT for cummunication with the PC
        component uart is
        generic (
            baud                : positive;
            clock_frequency     : positive
        );
        port (
            clock               :   in      std_logic;
            reset               :   in      std_logic;    
            data_stream_in      :   in      std_logic_vector(7 downto 0);
            data_stream_in_stb  :   in      std_logic;
            data_stream_in_ack  :   out     std_logic;
            data_stream_out     :   out     std_logic_vector(7 downto 0);
            data_stream_out_stb :   out     std_logic;
            tx                  :   out     std_logic;
            rx                  :   in      std_logic
        );
    end component uart;
    
    ---------------------------------------------------------------------------
    -- UART signals
    ---------------------------------------------------------------------------
    signal uart_data_in : std_logic_vector(7 downto 0);
    signal uart_data_out : std_logic_vector(7 downto 0);
    signal uart_data_in_stb : std_logic := '0';
    signal uart_data_in_ack : std_logic := '0';
    signal uart_data_out_stb : std_logic := '0';
    

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
           reset:                   in STD_LOGIC;
           --For the starting of the calculator
           start_comm:              out STD_LOGIC:= '0'
        );
    end component;
    
      -- signals for  Reading from read buffer
     signal s_read_fifo_r_data:        STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0) := (others => '0');
     signal s_read_fifo_r_data_en:     STD_LOGIC := '0';
     signal s_read_fifo_empty:         STD_LOGIC := '0';
     --signals  for writting to write buffer
     signal s_write_fifo_w_data:       STD_LOGIC_VECTOR(FIFO_WIDTH-1 downto 0) := (others => '0');
     signal s_write_fifo_w_data_en:    STD_LOGIC := '0';
     signal s_write_fifo_full:         STD_LOGIC := '0';
     --signals for going to memory
     signal s_memory_Address:          STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_read_port:        STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_write_port:       STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
     signal s_memory_write_en:         STD_LOGIC := '0';
     --Signals  for getting the print command from the calculator
     signal s_print_value:             STD_LOGIC_VECTOR(7 downto 0) := (others => 'Z');
     
         
    

begin 

    -- Connections
    memory_address    <= s_memory_Address;
    s_memory_read_port  <= memory_read_port;
    memory_write_port <= s_memory_write_port;
    memory_write_en   <= s_memory_write_en;
    s_print_value       <= print_value;
    ---------------------------------------------------------------------------
    -- UART instantiation
    ---------------------------------------------------------------------------
    uart_inst : uart
    generic map (
        baud                => baud,
        clock_frequency     => clock_frequency
    )
    port map    (  
        -- general
        clock               => clk,
        reset               => reset,
        data_stream_in      => uart_data_in,
        data_stream_in_stb  => uart_data_in_stb,
        data_stream_in_ack  => uart_data_in_ack,
        data_stream_out     => uart_data_out,
        data_stream_out_stb => uart_data_out_stb,
        tx                  => UART_TX,
        rx                  => UART_RX
    );


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
       enable                   => enable,
       reset                    => reset,
       start_comm               => start_comm
    );
    
    read_buffer : GENERIC_FIFO
    GENERIC MAP (
             FIFO_WIDTH => FIFO_WIDTH,
             FIFO_DEPTH => FIFO_DEPTH)
    PORT MAP (
             clock       => clk,
             reset       => reset,
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
              reset       => reset,
              write_data  => s_write_fifo_w_data,
              read_data   => write_buffer_read_data,
              write_en    => s_write_fifo_w_data_en,
              read_en     => write_buffer_read_enable,
              full        => s_write_fifo_full,
              empty       => write_buffer_empty,
              level       => write_buffer_level
      );
           
    CompInterface_proc: process (clk) is
    begin 
        if (rising_edge(clk)) then
            if reset = '1' then --reseting the UART
                uart_data_in_stb        <= '0';
                uart_data_in            <= (others => '0');
            else
                --Make sure that the FIFI buffers are acknowledge
                write_buffer_read_enable    <= '0';
                read_buffer_write_enable    <= '0';
                --Read incomming data from the UART and put it in the read buffer
                if uart_data_out_stb = '1' and read_buffer_full = '0' then
                    read_buffer_write_enable    <= '1';
                    read_buffer_write_data        <= uart_data_out;
                end if;
                -- Clear transmission request strobe upon acknowledge.
                if uart_data_in_ack = '1' then
                    uart_data_in_stb    <= '0';
                end if;
                --Take outgoing data from the write buffer and put it in the UART
                if write_buffer_empty = '0' then
                    if uart_data_in_stb = '0' then
                        uart_data_in_stb <= '1';
                        write_buffer_read_enable <= '1';
                        uart_data_in <= write_buffer_read_data;
                    end if;
                end if;
            end if;
        end if;
    end process;


end behavioral ;
