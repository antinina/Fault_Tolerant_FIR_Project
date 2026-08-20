library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.param_package.all;

entity redundancy_voter is
  Port (
            clk: in std_logic;
            r_voter_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            r_voter_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            error_signal_i:in std_logic;
            fault_signal_o: out std_logic;
            rdy_o: out std_logic
   );
end redundancy_voter;

architecture Behavioral of redundancy_voter is

-- wiring signals
signal voter_i_s :  MAC_OUT_ARRAY(MODULE_NUM-1 downto 0); -- !mux
signal test_signal_s:  MAC_OUT_ARRAY(MODULE_NUM-1 downto 0); -- !mux
signal voter_o_s : std_logic_vector(2*INPUT_WIDTH-1 downto 0);
signal clk_s: std_logic;

signal sw_error_signal_s: std_logic;
signal sel_mod_s: std_logic;
signal fault_signal_s: std_logic;


signal rdy_s: std_logic;

-- majority voter unit
component voter is
      Port (
            voter_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            voter_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0) 
       );
end component;
-- fault detection unit
component fault_detector is
      Port (clk: in std_logic;
            error_signal_i  : in std_logic;
            voter_out_i: in std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            test_signal_o : out MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            sel_mode_o:out std_logic; -- selects input to voter: 0 - mac module outputs(normal) 1 - test vector(test)
            fault_signal_o: out std_logic; -- high if fault is detected
            rdy_o: out std_logic
       );
end component;



begin

-- voter input mux
voter_input_mux:
with sel_mod_s select
voter_i_s <=
        r_voter_i when '0',
        test_signal_s when others;
        
-- voter component
voter_unit: voter port map(
 voter_i  => voter_i_s,    -- inter signal
 voter_o => voter_o_s 

);

-- fault detection unit
fd_unit: fault_detector port map(
            clk => clk_s,
            error_signal_i => error_signal_i, -- from switch comparator
            voter_out_i => voter_o_s,
            test_signal_o => test_signal_s,
            sel_mode_o => sel_mod_s,
            fault_signal_o => fault_signal_s,
            rdy_o => rdy_s);
            
-- wiring            
clk_s <= clk;
r_voter_o <= voter_o_s;
fault_signal_o <= fault_signal_s;

rdy_o <= rdy_s;

end Behavioral;
