library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.param_package.all;

entity redundancy_unit is
      Port (
           clk: in std_logic;
           u_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           b_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           sec_i : in STD_LOGIC_VECTOR (2*INPUT_WIDTH-1 downto 0);
           sec_o : out STD_LOGIC_VECTOR (2*INPUT_WIDTH-1 downto 0);
           error_o: out std_logic
       );
end redundancy_unit;

architecture Behavioral of redundancy_unit is
-- signals
signal clk_s: std_logic;
signal u_i_s, b_i_s: STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
signal mac_out_s: MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
signal output_o_s : std_logic_vector(2*INPUT_WIDTH-1 downto 0);
signal error_s: std_logic;


--!
attribute dont_touch : string;
    attribute dont_touch of mac_out_s : signal is "true";
    --attribute dont_touch of switch_in_original : signal is "true";
   -- attribute dont_touch of switch_in_spares : signal is "true";
    --attribute dont_touch of switch_out : signal is "true";

-- mac unit
component mac is
    Port (
        clk_i : in  STD_LOGIC;
        u_i   : in  STD_LOGIC_VECTOR(INPUT_WIDTH-1 downto 0);
        b_i   : in  STD_LOGIC_VECTOR(INPUT_WIDTH-1 downto 0);
        sec_i : in  STD_LOGIC_VECTOR(2*INPUT_WIDTH-1 downto 0);
        sec_o : out STD_LOGIC_VECTOR(2*INPUT_WIDTH-1 downto 0)
    );
end component;

-- voter -> pair and a spare redundancy technique
component pair_n_spare is
  Port (
            clk: in std_logic;
            mac_out_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            output_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            error_signal_o:out std_logic
            
   );
end component;


begin
 
-- N-modular redundancy: generate MODULE_NUM identical mac units that compute output in parallel
  gen_mac : for i in 0 to MODULE_NUM-1 generate--MODULE_NUM-1

        mac_inst : mac
            port map (
                clk_i => clk_s,
                u_i   => u_i,
                b_i   => b_i,
                sec_i => sec_i,
                sec_o => mac_out_s(i)
            );

    end generate;

-- Pair and a spare voter
pair_n_spare_voter:
    pair_n_spare port map(
            clk => clk_s,
            mac_out_i  => mac_out_s,
            output_o => output_o_s, 
            error_signal_o => error_s        
    );
-- wiring
clk_s <= clk;
sec_o <= output_o_s;
error_o <= error_s;

end Behavioral;
