library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
use work.txt_util.all;
use work.util_pkg.all;
use work.param_package.all;

entity fir_tb is
end fir_tb;

architecture Behavioral of fir_tb is

    constant period : time := 20 ns;

    signal clk_i_s : std_logic := '0';

    file input_test_vector   : text open read_mode is "../../../../input.txt";
    file output_check_vector : text open read_mode is "../../../../expected.txt";
    file input_coef          : text open read_mode is "../../../../coef.txt";

    signal start_check : std_logic := '0';
    signal tmp_s : std_logic_vector(INPUT_WIDTH-1 downto 0) := (others => '0');

    ------------------------------------------------------------------
    -- Coefficient interface
    ------------------------------------------------------------------

    signal we_i_s : std_logic := '0';

    signal coef_addr_i_s :
        std_logic_vector(log2c(FIR_ORDER+1)-1 downto 0);

    signal coef_i_s :
        std_logic_vector(INPUT_WIDTH-1 downto 0);

    ------------------------------------------------------------------
    -- AXI4-Stream Slave
    ------------------------------------------------------------------

    signal s_axis_tdata_i_s  :
        std_logic_vector(INPUT_WIDTH-1 downto 0);

    signal s_axis_tvalid_i_s : std_logic := '0';

    signal s_axis_tready_o_s : std_logic;

    ------------------------------------------------------------------
    -- AXI4-Stream Master
    ------------------------------------------------------------------

    signal m_axis_tdata_o_s :
        std_logic_vector(OUTPUT_WIDTH-1 downto 0);

    signal m_axis_tvalid_o_s : std_logic;

    signal m_axis_tready_i_s : std_logic := '1';

    ------------------------------------------------------------------
    -- DUT
    ------------------------------------------------------------------

--    component test_fir is
    component fir is
    generic(
        fir_ord : natural := FIR_ORDER;
        input_data_width : natural := INPUT_WIDTH;
        output_data_width : natural := INPUT_WIDTH
    );
    Port(
        clk_i : in STD_LOGIC;

        we_i : in STD_LOGIC;
        coef_addr_i : in std_logic_vector(log2c(fir_order + 1)-1 downto 0);
        coef_i : in STD_LOGIC_VECTOR(input_width-1 downto 0);

        s_axis_tdata_i  : in std_logic_vector(input_width-1 downto 0);
        s_axis_tvalid_i : in std_logic;
        s_axis_tready_o : out std_logic;

        m_axis_tdata_o  : out std_logic_vector(output_width-1 downto 0);
        m_axis_tvalid_o : out std_logic;
        m_axis_tready_i : in std_logic
    );
    end component;

begin

--------------------------------------------------------------------
-- DUT
--------------------------------------------------------------------

--uut : test_fir
uut : fir
generic map(
    fir_ord           => FIR_ORDER,
    input_data_width  => INPUT_WIDTH,
    output_data_width => OUTPUT_WIDTH
)
port map(

    clk_i => clk_i_s,

    we_i        => we_i_s,
    coef_addr_i => coef_addr_i_s,
    coef_i      => coef_i_s,

    s_axis_tdata_i  => s_axis_tdata_i_s,
    s_axis_tvalid_i => s_axis_tvalid_i_s,
    s_axis_tready_o => s_axis_tready_o_s,

    m_axis_tdata_o  => m_axis_tdata_o_s,
    m_axis_tvalid_o => m_axis_tvalid_o_s,
    m_axis_tready_i => m_axis_tready_i_s
);

--------------------------------------------------------------------
-- Clock
--------------------------------------------------------------------

clk_process : process
begin
    while true loop
        clk_i_s <= '0';
        wait for period/2;
        clk_i_s <= '1';
        wait for period/2;
    end loop;
end process;

--------------------------------------------------------------------
-- Stimulus
--------------------------------------------------------------------

stim_process : process

    variable tv : line;

begin

    ---------------------------------------------------------------
    -- Load coefficients
    ---------------------------------------------------------------

    wait until falling_edge(clk_i_s);

    for i in 0 to FIR_ORDER loop

        we_i_s <= '1';

        coef_addr_i_s <=
            std_logic_vector(to_unsigned(i, coef_addr_i_s'length));

        readline(input_coef, tv);
        coef_i_s <= to_std_logic_vector(string(tv));

        wait until falling_edge(clk_i_s);

    end loop;

    we_i_s <= '0';

    wait until falling_edge(clk_i_s);

    start_check <= '1';

    ---------------------------------------------------------------
    -- Stream input samples
    ---------------------------------------------------------------

    while not endfile(input_test_vector) loop

        readline(input_test_vector, tv);

        s_axis_tdata_i_s <= to_std_logic_vector(string(tv));
        s_axis_tvalid_i_s <= '1';

        loop

            wait until rising_edge(clk_i_s);

            exit when
                s_axis_tvalid_i_s = '1' and
                s_axis_tready_o_s = '1';

        end loop;

        s_axis_tvalid_i_s <= '0';

    end loop;

    wait for 500 ns;

    report "Verification completed.";

    wait;

end process;

--------------------------------------------------------------------
-- Output checker
--------------------------------------------------------------------

check_process : process

    variable check_v  : line;
    variable expected : std_logic_vector(OUTPUT_WIDTH-1 downto 0);

    variable sample : integer := 0;

begin

    wait until start_check = '1';

    while true loop

        wait until rising_edge(clk_i_s);
         
         if endfile(output_check_vector) then
                    report "Verification completed." severity error;
                    wait;
                end if;
                
        
        if m_axis_tvalid_o_s = '1' and m_axis_tready_i_s = '1' then

            readline(output_check_vector, check_v);

            expected := to_std_logic_vector(string(check_v));

            tmp_s <= expected;
     
        wait until rising_edge(clk_i_s);

            if abs(signed(expected) - signed(m_axis_tdata_o_s)) > to_signed(7, OUTPUT_WIDTH) then

                report "Mismatch at sample "
                    & integer'image(sample);
--                    --severity error;

            end if;

            sample := sample + 1;


end if;

    end loop;

end process;




end Behavioral;