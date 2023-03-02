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

    -- Ram declaration
    type ram_type is array (65535 downto 0) of std_logic_vector(7 downto 0);

    -- Ram instance
    signal RAM: ram_type := (0      => std_logic_vector(to_unsigned( 6 , 8)),
                             1      => "10100011",
                             2      => "00101111",
                             3      => "00000100",
                             4      => "01000000",
                             5      => "01000011",
                             6      => "00001101",
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
        i_clk      => tb_clk,
        i_start    => tb_start,
        i_rst      => tb_rst,
        i_data     => ram_o_data,
        o_address  => ram_address,
        o_done     => tb_done,
        o_en   	   => enable_wire,
        o_we 	   => ram_we,
        o_data     => ram_i_data
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
                if ram_we = '1' then
                    RAM(conv_integer(ram_address)) <= ram_i_data;
                    ram_o_data                     <= ram_i_data after 2 ns;
                else
                    ram_o_data                     <= RAM(conv_integer(ram_address)) after 2 ns;
                end if;
            end if;
        end if;
    end process;

    test : process is
    begin 
        wait for 100 ns;

        wait for c_CLOCK_PERIOD;
        tb_rst   <= '1';
        wait for c_CLOCK_PERIOD;
        tb_rst   <= '0';
        wait for c_CLOCK_PERIOD;
        tb_start <= '1';

        wait for c_CLOCK_PERIOD;
        wait for 500 ns;    --FirstResetTime
        tb_rst   <= '1';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_rst   <= '0';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_start <= '1';

        wait for c_CLOCK_PERIOD;
        wait for 500 ns;    --SecondResetTime
        tb_rst   <= '1';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_rst   <= '0';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_start <= '1';

        wait for c_CLOCK_PERIOD;
        wait for 500 ns;    --ThirdResetTime
        tb_rst   <= '1';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_rst   <= '0';
        wait for c_CLOCK_PERIOD;
        wait for 100 ns;
        tb_start <= '1';

        wait for c_CLOCK_PERIOD;
        wait until tb_done = '1';

        wait for c_CLOCK_PERIOD;
        tb_start <= '0';
        wait until tb_done = '0';
        wait for 100 ns;


        -- Checking behavoir: 
        assert RAM(1000) = "11010001" report "UNSUCCESSFUL TEST: #0 byte in RAM -> add: 1000; right value: 11010001; found value: " & integer'image(to_integer(unsigned(RAM(1000)))) severity failure;
        assert RAM(1001) = "11001110" report "UNSUCCESSFUL TEST: #1 byte in RAM -> add: 1001; right value: 11001110; found value: " & integer'image(to_integer(unsigned(RAM(1001)))) severity failure;
        assert RAM(1002) = "10111101" report "UNSUCCESSFUL TEST: #2 byte in RAM -> add: 1002; right value: 10111101; found value: " & integer'image(to_integer(unsigned(RAM(1002)))) severity failure;
        assert RAM(1003) = "00100101" report "UNSUCCESSFUL TEST: #3 byte in RAM -> add: 1003; right value: 00100101; found value: " & integer'image(to_integer(unsigned(RAM(1003)))) severity failure;
        assert RAM(1004) = "10110000" report "UNSUCCESSFUL TEST: #4 byte in RAM -> add: 1004; right value: 10110000; found value: " & integer'image(to_integer(unsigned(RAM(1004)))) severity failure;
        assert RAM(1005) = "00110111" report "UNSUCCESSFUL TEST: #5 byte in RAM -> add: 1005; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM(1005)))) severity failure;
        assert RAM(1006) = "00110111" report "UNSUCCESSFUL TEST: #6 byte in RAM -> add: 1006; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM(1006)))) severity failure;
        assert RAM(1007) = "00000000" report "UNSUCCESSFUL TEST: #7 byte in RAM -> add: 1007; right value: 00000000; found value: " & integer'image(to_integer(unsigned(RAM(1007)))) severity failure;
        assert RAM(1008) = "00110111" report "UNSUCCESSFUL TEST: #8 byte in RAM -> add: 1008; right value: 00110111; found value: " & integer'image(to_integer(unsigned(RAM(1008)))) severity failure;
        assert RAM(1009) = "00001110" report "UNSUCCESSFUL TEST: #9 byte in RAM -> add: 1009; right value: 00001110; found value: " & integer'image(to_integer(unsigned(RAM(1009)))) severity failure;
        assert RAM(1010) = "10110000" report "UNSUCCESSFUL TEST: #10 byte in RAM -> add: 1010; right value: 10110000; found value: " & integer'image(to_integer(unsigned(RAM(1010))))severity failure;
        assert RAM(1011) = "11101000" report "UNSUCCESSFUL TEST: #11 byte in RAM -> add: 1011; right value: 11101000; found value: " & integer'image(to_integer(unsigned(RAM(1011))))severity failure;
    
        assert false report "SUCCESSFUL TEST: Simulation Ended!" severity failure;
    end process test;
end projecttb; 