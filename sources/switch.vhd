library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_unsigned.all;
use work.param_package.all;
use work.util_pkg.all;


entity switch is
      Port (clk: in std_logic;            
            voter_out_i  : in MAC_OUT_ARRAY(SPARE_NUM-1 downto 0); --
            fd_fault_sig_i:in FD_OUT_ARRAY(SPARE_NUM-1 downto 0); --
            mismatch_o: out std_logic;            
            switch_output_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            rdy_i:in FD_OUT_ARRAY(SPARE_NUM-1 downto 0) 
       );
end switch;

architecture Behavioral of switch is
    signal idx_a_s: std_logic_vector(log2c(SPARE_NUM + 1)-1 downto 0):=(others=>'0'); -- parametrized
    signal idx_b_s: std_logic_vector(log2c(SPARE_NUM + 1)-1 downto 0):= std_logic_vector(to_unsigned(1, log2c(SPARE_NUM + 1)));
    signal idx_spare_s, idx_spare_next: std_logic_vector(log2c(SPARE_NUM + 1)-1 downto 0):= std_logic_vector(to_unsigned(2, log2c(SPARE_NUM + 1)));


    signal input_a_s, input_b_s: std_logic_vector(2*INPUT_WIDTH-1 downto 0);
    signal output_a_s, output_b_s: std_logic_vector(2*INPUT_WIDTH-1 downto 0):=(others=>'0');
    
    signal fault_a_s, fault_b_s:std_logic;
    signal error_s: std_logic:='0';
    signal error_detected_s: std_logic :='0';
    signal recovery_finished_s: std_logic :='0';
    -- state machine
	type state_t is (idle, error_detected, recovery  );
	signal state, next_state : state_t := idle;    

    signal out_of_spares: std_logic:= '0';
begin

input_a_s <= voter_out_i(to_integer(unsigned(idx_a_s)));
input_b_s <= voter_out_i(to_integer(unsigned(idx_b_s)));
fault_a_s <= fd_fault_sig_i(to_integer(unsigned(idx_a_s)));
fault_b_s <= fd_fault_sig_i(to_integer(unsigned(idx_b_s)));

-- Flag indicators
error_detected_s <= '1' when (input_a_s /= input_b_s) else '0';
recovery_finished_s <= '1' when (rdy_i(to_integer(unsigned(idx_a_s))) = '1' and rdy_i(to_integer(unsigned(idx_b_s))) = '1')
		 else '0';

-- FSM
 process(state, error_detected_s, recovery_finished_s, error_s)
begin

    -- Defaults
    next_state <= state;
    error_s <= '0';

    case state is

        when idle =>
--            if(out_of_spares = '1' and error_detected_s = '1')then -- ovo dodala
--                error_s <= '1';
--            else
                if(error_detected_s = '1')then
                    next_state <= error_detected;
                    error_s <= '1';
                end if;
--            end if;
            
        when error_detected =>

            error_s <= '1';

            if(recovery_finished_s = '1' and out_of_spares='0')then
                next_state <= recovery;
                --error_s <= '0';
            end if;
       when recovery =>
             if(out_of_spares = '1')then
             error_s <= '1';
             next_state <= idle;
             else
             -- normal
                error_s <= '0';            
                if(recovery_finished_s = '0')then
                    next_state <= idle;
                   -- error_s <= '0';
                end if;
                end if;
        when others =>

            next_state <= idle;
            error_s <= '0';

    end case;

end process;

-- error should be raised when error is detected, it lasts until both ready signals are high
process(clk)
begin
if(rising_edge(clk))then
-- fsm state change	
	state <= next_state;
	idx_spare_s <= idx_spare_next;
-- output determination	
    if(state = error_detected and recovery_finished_s = '1')then
    -- fault A
            if(fault_a_s = '1')then    
                idx_a_s <= idx_spare_s;
                if(to_integer(unsigned(idx_spare_s)) < SPARE_NUM-1)then                  
                  idx_spare_next <= idx_spare_s + '1';     
                else
                    out_of_spares <= '1';      
                end if;
    -- fault B            
            elsif(fault_b_s = '1')then
                idx_b_s <= idx_spare_s;
                if(to_integer(unsigned(idx_spare_s)) < SPARE_NUM-1)then -- ovde bila greska 
                    idx_spare_next <= idx_spare_s + '1'; 
                else
                    out_of_spares <= '1';          
                end if;
            end if;            
             
    elsif(state = idle and error_detected_s = '0')then
        switch_output_o <= input_a_s;      
    end if; --if state
       
end if;--rising edge    
end process;

-- error signal output
 mismatch_o <= error_s;

end Behavioral;