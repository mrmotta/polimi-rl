-- +--------------------------------------------------------+
-- |                                                        |
-- | Test bench realizzato da Riccardo Motta e Matteo Negro |
-- |                                                        |
-- +--------------------------------------------------------+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity project_tb is
end project_tb;

architecture projecttb of project_tb is
    -- Signals declartion
    constant c_CLOCK_PERIOD		    : time := 100 ns;                                    -- ClockPeriod 
    signal   tb_done		        : std_logic;                                         -- Done
    signal   ram_address		    : std_logic_vector (15 downto 0) := (others => '0'); -- RamAddress
    signal   tb_rst	                : std_logic := '0';                                  -- Reset
    signal   tb_start		        : std_logic := '0';                                  -- Start
    signal   tb_clk		            : std_logic := '0';                                  -- Clock
    signal   ram_i_data	            : std_logic_vector (7 downto 0);                     -- RamInputData
    signal   ram_o_data         	: std_logic_vector (7 downto 0);                     -- RamOutputData
    signal   enable_wire  		    : std_logic;                                         -- EnableWire
    signal   ram_we		            : std_logic;                                         -- RamEnableWrite

    -- Controller 
    signal i: std_logic_vector(1 downto 0) := "00";

    -- Ram declaration
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);

    -- Ram instance
    signal RAM0: ram_type := (0      => std_logic_vector(to_unsigned( 1 , 8)),
                              1      => "10100010",
                              others => (others =>'0'));

    signal RAM1: ram_type := (0      => std_logic_vector(to_unsigned( 2 , 8)),
                              1      => "10100010",
                              2      => "01001011",
                              others => (others =>'0'));

    signal RAM2: ram_type := (0      => std_logic_vector(to_unsigned( 6 , 8)),
                              1      => "10100011",
                              2      => "00101111",
                              3      => "00000100",
                              4      => "01000000",
                              5      => "01000011",
                              6      => "00001101",
                              others => (others =>'0'));
    
    signal RAM3: ram_type := (0      => std_logic_vector(to_unsigned(3, 8)),
                              1      => "01110000",
                              2      => "10100100",
                              3      => "00101101",
                              others => (others =>'0'));

    -- Project Interface Component 
    component project_reti_logiche is
    port (
        i_clk         : in  std_logic;
        i_start       : in  std_logic;
        i_rst         : in  std_logic;
        i_data        : in  std_logic_vector(7 downto 0);
        o_address     : out std_logic_vector(15 downto 0);
        o_done        : out std_logic;
        o_en          : out std_logic;
        o_we          : out std_logic;
        o_data        : out std_logic_vector (7 downto 0)
        );
    end component project_reti_logiche;

    begin
    UUT: project_reti_logiche
    port map (
            i_clk     => tb_clk,
            i_start   => tb_start,
            i_rst     => tb_rst,
            i_data    => ram_o_data,
            o_address => ram_address,
            o_done    => tb_done,
            o_en   	  => enable_wire,
            o_we 	  => ram_we,
            o_data    => ram_i_data
            );

    -- Generation Clock Process
    p_CLK_GEN : process is
    begin
        wait for c_CLOCK_PERIOD/2;
        tb_clk <= not tb_clk;
    end process p_CLK_GEN;

    -- Ram processing
    RAM_process : process(tb_clk)
    begin
        if tb_clk'event and tb_clk = '1' then
            if enable_wire = '1' then
                if i = "00" then
                    if ram_we = '1' then
                        RAM0(conv_integer(ram_address)) <= ram_i_data;
                        ram_o_data                      <= ram_i_data after 1 ns;
                    else
                        ram_o_data <= RAM0(conv_integer(ram_address)) after 1 ns;
                    end if;
                elsif i ="01" then
                    if ram_we = '1' then
                        RAM1(conv_integer(ram_address)) <= ram_i_data;
                        ram_o_data                      <= ram_i_data after 1 ns;
                    else
                        ram_o_data <= RAM1(conv_integer(ram_address)) after 1 ns;
                    end if;
                elsif i = "10" then 
                    if ram_we = '1' then
                        RAM2(conv_integer(ram_address)) <= ram_i_data;
                        ram_o_data                      <= ram_i_data after 1 ns;
                    else
                        ram_o_data <= RAM2(conv_integer(ram_address)) after 1 ns;
                    end if;
                elsif i = "11" then 
                    if ram_we = '1' then
                        RAM3(conv_integer(ram_address)) <= ram_i_data;
                        ram_o_data                      <= ram_i_data after 1 ns;
                    else
                        ram_o_data <= RAM3(conv_integer(ram_address)) after 1 ns;
                    end if;
                end if;
            end if;
        end if;
    end process;

    test : process is
    begin 
        wait for 100 ns;
        wait for c_CLOCK_PERIOD;
        tb_rst <= '1';
        wait for c_CLOCK_PERIOD;
        tb_rst <= '0';
        wait for c_CLOCK_PERIOD;
        tb_start <= '1';
        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';
        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';
        i <= "01";

        wait for 100 ns;
        tb_start <= '1';
        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';
        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';
        wait for 100 ns;
        i <= "10";

        wait for 100 ns;
        tb_start <= '1';
        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';
        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';
        wait for 100 ns;
        i <= "11";

        wait for 100 ns;
        tb_start <= '1';
        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';
        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';
        wait for 100 ns;

        -- Checking behaviour RAM0: 
        assert RAM0(1000) = "11010001" report "UNSUCCESSFUL TEST: #0 byte in RAM0 -> add: 1000; right value: 11010001; found value: " & integer'image(to_integer(unsigned(RAM0(1000)))) severity failure;
        assert RAM0(1001) = "11001101" report "UNSUCCESSFUL TEST: #1 byte in RAM0 -> add: 1001; right value: 11001101; found value: " & integer'image(to_integer(unsigned(RAM0(1001)))) severity failure;

        -- Checking behaviour RAM1: 
        assert RAM1(1000) = "11010001" report "UNSUCCESSFUL TEST: #0 byte in RAM1 -> add: 1000; right value: 11010001; found value: " & integer'image(to_integer(unsigned(RAM1(1000)))) severity failure;
        assert RAM1(1001) = "11001101" report "UNSUCCESSFUL TEST: #1 byte in RAM1 -> add: 1001; right value: 11001101; found value: " & integer'image(to_integer(unsigned(RAM1(1001)))) severity failure;
        assert RAM1(1002) = "11110111" report "UNSUCCESSFUL TEST: #2 byte in RAM1 -> add: 1002; right value: 11110111; found value: " & integer'image(to_integer(unsigned(RAM1(1002)))) severity failure;
        assert RAM1(1003) = "11010010" report "UNSUCCESSFUL TEST: #3 byte in RAM1 -> add: 1003; right value: 11010010; found value: " & integer'image(to_integer(unsigned(RAM1(1003)))) severity failure;

        -- Checking behaviour RAM2: 
        assert RAM2(1000) = "11010001" report "UNSUCCESSFUL TEST: #0 byte in RAM2 -> add: 1000; right value: 11010001; found value: " & integer'image(to_integer(unsigned(RAM2(1000)))) severity failure;
        assert RAM2(1001) = "11001110" report "UNSUCCESSFUL TEST: #1 byte in RAM2 -> add: 1001; right value: 11001110; found value: " & integer'image(to_integer(unsigned(RAM2(1001)))) severity failure;
        assert RAM2(1002) = "10111101" report "UNSUCCESSFUL TEST: #2 byte in RAM2 -> add: 1002; right value: 10111101; found value: " & integer'image(to_integer(unsigned(RAM2(1002)))) severity failure;
        assert RAM2(1003) = "00100101" report "UNSUCCESSFUL TEST: #3 byte in RAM2 -> add: 1003; right value: 00100101; found value: " & integer'image(to_integer(unsigned(RAM2(1003)))) severity failure;
        assert RAM2(1004) = "10110000" report "UNSUCCESSFUL TEST: #4 byte in RAM2 -> add: 1004; right value: 10110000; found value: " & integer'image(to_integer(unsigned(RAM2(1004)))) severity failure;
        assert RAM2(1005) = "00110111" report "UNSUCCESSFUL TEST: #5 byte in RAM2 -> add: 1005; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM2(1005)))) severity failure;
        assert RAM2(1006) = "00110111" report "UNSUCCESSFUL TEST: #6 byte in RAM2 -> add: 1006; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM2(1006)))) severity failure;
        assert RAM2(1007) = "00000000" report "UNSUCCESSFUL TEST: #7 byte in RAM2 -> add: 1007; right value: 00000000; found value: " & integer'image(to_integer(unsigned(RAM2(1007)))) severity failure;
        assert RAM2(1008) = "00110111" report "UNSUCCESSFUL TEST: #8 byte in RAM2 -> add: 1008; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM2(1008)))) severity failure;
        assert RAM2(1009) = "00001110" report "UNSUCCESSFUL TEST: #9 byte in RAM2 -> add: 1009; right value: 00001110; found value: " & integer'image(to_integer(unsigned(RAM2(1009)))) severity failure;
        assert RAM2(1010) = "10110000" report "UNSUCCESSFUL TEST: #10 byte in RAM2 -> add: 1010; right value: 10110000; found value: " & integer'image(to_integer(unsigned(RAM2(1010)))) severity failure;
        assert RAM2(1011) = "11101000" report "UNSUCCESSFUL TEST: #11 byte in RAM2 -> add: 1011; right value: 11101000; found value: " & integer'image(to_integer(unsigned(RAM2(1011)))) severity failure;

        -- Checking behaviour RAM3:
        assert RAM3(1000) = "00111001" report "UNSUCCESSFUL TEST: #0 byte in RAM3 -> add: 1000; right value: 00111001; found value: " & integer'image(to_integer(unsigned(RAM3(1000)))) severity failure;
        assert RAM3(1001) = "10110000" report "UNSUCCESSFUL TEST: #1 byte in RAM3 -> add: 1001; right value: 10110000; found value: " & integer'image(to_integer(unsigned(RAM3(1001)))) severity failure;
        assert RAM3(1002) = "11010001" report "UNSUCCESSFUL TEST: #2 byte in RAM3 -> add: 1002; right value: 11010001; found value: " & integer'image(to_integer(unsigned(RAM3(1002)))) severity failure;
        assert RAM3(1003) = "11110111" report "UNSUCCESSFUL TEST: #3 byte in RAM3 -> add: 1003; right value: 11110111; found value: " & integer'image(to_integer(unsigned(RAM3(1003)))) severity failure;
        assert RAM3(1004) = "00001101" report "UNSUCCESSFUL TEST: #4 byte in RAM3 -> add: 1004; right value: 00001101; found value: " & integer'image(to_integer(unsigned(RAM3(1004)))) severity failure;
        assert RAM3(1005) = "00101000" report "UNSUCCESSFUL TEST: #5 byte in RAM3 -> add: 1005; right value: 00101000; found value: " & integer'image(to_integer(unsigned(RAM3(1005)))) severity failure;
    
        assert false report "SUCCESSFUL TEST: Simulation Ended!" severity failure;
    end process test;
end projecttb;
