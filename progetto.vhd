-- +------------------------------------------------------+
-- |                                                      |
-- | Progetto realizzato da Riccardo Motta e Matteo Negro |
-- |                                                      |
-- +------------------------------------------------------+

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Project interface
entity project_reti_logiche is
    port (
        i_clk     : in  std_logic;
        i_rst     : in  std_logic;
        i_start   : in  std_logic;
        i_data    : in  std_logic_vector(7  downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done    : out std_logic;
        o_en      : out std_logic;
        o_we      : out std_logic;
        o_data    : out std_logic_vector(7  downto 0)
    );
end project_reti_logiche;

architecture codec of project_reti_logiche is

-- Machines states
type fsm_state_type     is (S0, S1, S2, S3);
type machine_state_type is (DECODE, READ, READ_ITERATIONS, READ_PREPARE, READ_WAITING, READ_WAITING_ITERATIONS, RESET, WRITE);

-- Machines-related signals
signal current_state  : fsm_state_type;
signal machine_state  : machine_state_type;
signal process_state  : std_logic;
signal iterations     : integer range 255 downto -1;

-- Read/write-related signals
signal read_count     : std_logic_vector(7  downto 0);
signal read_time      : std_logic;
signal first_byte     : std_logic;
signal write_count    : std_logic_vector(3  downto 0);

-- Addresses
signal input_address  : std_logic_vector(15 downto 0);
signal output_address : std_logic_vector(15 downto 0);

-- Data store
signal input_data     : std_logic_vector(7  downto 0);
signal output_data    : std_logic_vector(7  downto 0);

-- RAM enable signals (I/O)
signal enable         : std_logic;
signal write_enable   : std_logic;

-- Reset-related signals
signal reset_signal   : std_logic;
signal reset_feedback : std_logic;

begin

    o_en       <= enable;
    o_we       <= write_enable;
    o_data     <= output_data;

    -- Reset process
    process(i_rst, reset_feedback)
    begin
        if i_rst = '1' then
            reset_signal <= '1';
        elsif reset_feedback = '1' then
            reset_signal <= '0';
        end if;
    end process;

    -- Main process
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            reset_feedback                <= '0';
            if reset_signal = '1' then
                machine_state             <= RESET;
                reset_feedback            <= '1';
            elsif i_start = '1' then
                case machine_state is
                    when DECODE =>
                        if write_count(3) = '1' then
                            machine_state <= WRITE;
                        else
                            machine_state <= DECODE;
                        end if;
                    when READ =>
                        machine_state     <= DECODE;
                    when READ_ITERATIONS =>
                        machine_state     <= READ_PREPARE;
                    when READ_PREPARE =>
                        if iterations = 0 then
                            machine_state <= RESET;
                        else
                            machine_state <= READ_WAITING;
                        end if;
                    when READ_WAITING =>
                        machine_state     <= READ;
                    when READ_WAITING_ITERATIONS =>
                        machine_state     <= READ_ITERATIONS;
                    when RESET =>
                        machine_state <= READ_WAITING_ITERATIONS;
                    when WRITE =>
                        if read_count(7) = '1' then
                            machine_state <= READ_PREPARE;
                        else
                            machine_state <= DECODE;
                        end if;
                    when others =>
                        -- Do nothing: it never gets here
                end case;
            end if;
        end if;
    end process;

    -- FSM process
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            case machine_state is
                when DECODE =>
                    output_data                <= std_logic_vector(unsigned(output_data) sll 2);
                    case current_state is
                        when S0 =>
                            if input_data(7) = '0' then
                                current_state  <= S0;
                                output_data(1) <= '0';
                                output_data(0) <= '0';
                            else
                                current_state  <= S2;
                                output_data(1) <= '1';
                                output_data(0) <= '1';
                            end if;
                        when S1 =>
                            if input_data(7) = '0' then
                                current_state  <= S0;
                                output_data(1) <= '1';
                                output_data(0) <= '1';
                            else
                                current_state  <= S2;
                                output_data(1) <= '0';
                                output_data(0) <= '0';
                            end if;
                        when S2 =>
                            if input_data(7) = '0' then
                                current_state  <= S1;
                                output_data(1) <= '0';
                                output_data(0) <= '1';
                            else
                                current_state  <= S3;
                                output_data(1) <= '1';
                                output_data(0) <= '0';
                            end if;
                        when S3 =>
                            if input_data(7) = '0' then
                                current_state  <= S1;
                                output_data(1) <= '1';
                                output_data(0) <= '0';
                            else
                                current_state  <= S3;
                                output_data(1) <= '0';
                                output_data(0) <= '1';
                            end if;
                    end case;
                when RESET =>
                    current_state              <= S0;
                when others =>
                    -- Do nothing: in all the other cases we don't need the component to do anything, so this preservs the state
            end case;
        end if;
    end process;

    -- Memory process
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            case machine_state is
                when DECODE =>
                    enable         <= '0';
                    write_enable   <= '0';
                when READ_ITERATIONS =>
                    o_address      <= input_address;
                when READ_PREPARE =>
                    o_address      <= input_address;
                    input_address  <= std_logic_vector(to_unsigned(to_integer(unsigned(input_address)) + 1, 16));
                    enable         <= '1';
                    write_enable   <= '0';
                when RESET =>
                    o_address      <= (others => '0');
                    input_address  <= (15 downto 1 => '0', 0 => '1');
                    output_address <= std_logic_vector(to_unsigned(1000, 16));
                    enable         <= '1';
                    write_enable   <= '0';
                when WRITE =>
                    o_address      <= output_address;
                    output_address <= std_logic_vector(to_unsigned(to_integer(unsigned(output_address)) + 1, 16));
                    enable         <= '1';
                    write_enable   <= '1';
                when others =>
                    -- Do nothing: in all the other cases we don't need the component to do anything, so this preservs the state
            end case;
        end if;
    end process;

    -- Management process
    process(i_clk)
    begin
        if rising_edge(i_clk) then
            case machine_state is
                when DECODE =>
                    input_data     <= std_logic_vector(unsigned(input_data) sll 1);
                    write_count    <= std_logic_vector(unsigned(write_count) sll 1);
                    if read_count(7) = '0' then
                        read_count <= std_logic_vector(unsigned(read_count) sll 1);
                    end if;
                when READ =>
                    input_data     <= i_data;
                when READ_ITERATIONS =>
                    iterations     <= to_integer(unsigned(i_data));
                    if to_integer(unsigned(i_data)) = 0 then
                        o_done     <= '1';
                    end if;
                when READ_PREPARE =>
                    if iterations = 0 then
                        o_done     <= '1';
                    else
                        iterations <= iterations - 1;
                        read_count <= (7 downto 1 => '0', 0 => '1');
                    end if;
                when RESET =>
                    iterations     <= -1;
                    o_done         <= '0';
                    read_count     <= (7 downto 1 => '0', 0 => '1');
                    write_count    <= (3 downto 1 => '0', 0 => '1');
                when WRITE =>
                    write_count    <= (3 downto 1 => '0', 0 => '1');
                when others =>
                    -- Do nothing: in all the other cases we don't need the component to do anything, so this preservs the state
            end case;
        end if;
    end process;

end architecture;