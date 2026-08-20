library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.std_logic_unsigned.all;
use work.param_package.all;


entity fault_detector is
      Port (clk: in std_logic;
            error_signal_i  : in std_logic;
            voter_out_i: in std_logic_vector(2*INPUT_WIDTH-1 downto 0);
            test_signal_o : out MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            sel_mode_o:out std_logic; -- selects input to voter: 0 - mac module outputs(normal) 1 - test vector(test)
            fault_signal_o: out std_logic; -- high if fault is detected
            rdy_o: out std_logic
            
       );
end fault_detector;

architecture Behavioral of fault_detector is

-- Detects faulty component based on BIST algorithm( Built-In-Self-Test)
-- if mismatch of voter output occurs, it examines the component with predefined test vector
-- If the output differs from expected, it means that the fault is detected

signal bist_cnt : std_logic_vector(1 downto 0) := "00"; --idle

signal test1_s : MAC_OUT_ARRAY(MODULE_NUM-1 downto 0) := (others => (TEST_VECTOR1));
signal test2_s : MAC_OUT_ARRAY(MODULE_NUM-1 downto 0) := (others => (TEST_VECTOR2));

signal sel_mode_s: std_logic:='0';
signal fault_signal_s: std_logic:='0';


-- signal -> fault_type
signal sa0_flag_s, sa1_flag_s: std_logic:='0';
signal rdy_s:std_logic:='0';

begin

process(clk)

begin

sa0_flag_s<='0'; sa1_flag_s<='0';

if(rising_edge(clk))then
 
    rdy_s <= '0';
        case bist_cnt is
    
            when "00" =>
            --IDLE
            if error_signal_i='1' then
                -- test vector 1
            sel_mode_s <= '1'; -- Test mode begins
            test_signal_o <= test1_s; -- test value -- output will be checked in the next clock cycle
            bist_cnt <= bist_cnt + '1';
            end if;
            when "01" =>
            if(voter_out_i /=   EXPECTED1)then
            fault_signal_s <= '1';
            sa0_flag_s <= '1';            
            end if;
                -- test vector 2
           sel_mode_s <= '1'; -- Test mode        
           test_signal_o <= test2_s; -- test value -- output will be checked in the next clock cycle
            bist_cnt <= bist_cnt + '1';
            when "10" =>
                -- comparison
                
            if(voter_out_i /=   EXPECTED2 )then
            fault_signal_s <= '1';
            sa1_flag_s <= '1';
            end if;                
            rdy_s <= '1';
            bist_cnt <= bist_cnt + '1';
            
            when "11" =>
                -- fault_A/B, reset bistcounter
              fault_signal_s <= '0'; 
              bist_cnt <= "00";
              sel_mode_s<= '0';
              rdy_s <= '0';
            when others =>
                    report "Invalid state";
        end case;
        
end if;

end process;



-- wire
sel_mode_o <= sel_mode_s;
fault_signal_o <= fault_signal_s;
rdy_o <= rdy_s;


end Behavioral;