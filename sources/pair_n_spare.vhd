library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.std_logic_unsigned.all;
use work.param_package.all;

entity pair_n_spare is
  Port (
            clk: in std_logic;
            mac_out_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            output_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            error_signal_o:out std_logic
            
   );
end pair_n_spare;

architecture Behavioral of pair_n_spare is

-- signals
signal clk_s: std_logic;
--signal voter_i  :  MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
signal output_s : std_logic_vector(2*INPUT_WIDTH-1 downto 0);
signal error_mismatch_s: std_logic;
--signal fault_signal_s:  std_logic;

signal voter_out_s : MAC_OUT_ARRAY(SPARE_NUM-1 downto 0);

signal fault_out_s: FD_OUT_ARRAY(SPARE_NUM-1 downto 0);
signal rdy_out_s: FD_OUT_ARRAY(SPARE_NUM-1 downto 0);

-- add registers on input/ output of pair_n_spare block
signal input_reg, input_next:MAC_OUT_ARRAY(MODULE_NUM-1 downto 0):=( others => ( others => '0'));
signal output_reg, output_next: std_logic_vector(2*INPUT_WIDTH-1 downto 0) := (others => '0');


-- voter +  fault detector
component redundancy_voter is
  Port (
            clk: in std_logic;
            r_voter_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            r_voter_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            error_signal_i:in std_logic;
            fault_signal_o: out std_logic;
            rdy_o: out std_logic
   );
end component;
-- switch
component switch is
      Port (clk: in std_logic;            
            voter_out_i  : in MAC_OUT_ARRAY(SPARE_NUM-1 downto 0); --
            fd_fault_sig_i:in FD_OUT_ARRAY(SPARE_NUM-1 downto 0); --
            mismatch_o: out std_logic;            
            switch_output_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            rdy_i:in FD_OUT_ARRAY(SPARE_NUM-1 downto 0) 
       );
end component;
--
attribute dont_touch : string;
attribute dont_touch of voter_out_s : signal is "true";
attribute dont_touch of fault_out_s : signal is "true";
attribute dont_touch of rdy_out_s : signal is "true";
begin

-- input reg
--en_s <= error_mismatch_s;

input_register:process(clk)
begin
    if(rising_edge(clk))then
        if(error_mismatch_s/='1')then
        input_reg <= input_next;
        end if;
    end if;
end process;
input_next <= mac_out_i;

-- voters
gen_voter : for i in 0 to SPARE_NUM-1 generate
  
    voter_inst : redundancy_voter
    port map (
        clk   => clk_s,
        --r_voter_i => mac_out_i,
        r_voter_i => input_reg,
        r_voter_o => voter_out_s(i),
        error_signal_i => error_mismatch_s,
        fault_signal_o => fault_out_s(i),
        rdy_o=> rdy_out_s(i)
    );
end generate;

-- switch
switch_inst: switch 
    port map(
    clk => clk_s,            
    voter_out_i => voter_out_s,
     fd_fault_sig_i => fault_out_s,
     mismatch_o => error_mismatch_s,            
     switch_output_o => output_s,
     rdy_i => rdy_out_s    
    
    );


--output reg
output_register:process(clk)
begin
    if(rising_edge(clk))then
        if(error_mismatch_s/='1')then
        output_reg <= output_next;
        end if;
    end if;
end process;
output_next <= output_s;


-- wiring
clk_s <= clk;
output_o <= output_reg; -- here!
error_signal_o <= error_mismatch_s;



end Behavioral;
