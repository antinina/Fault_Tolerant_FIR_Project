library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.param_package.all;


entity voter is
      Port (
            voter_i  : in MAC_OUT_ARRAY(MODULE_NUM-1 downto 0);
            voter_o : out std_logic_vector(2*INPUT_WIDTH-1 downto 0) 
       );
end voter;

architecture Behavioral of voter is
    signal majority_vote: std_logic_vector(2*INPUT_WIDTH-1 downto 0):= (others => '0');
begin

-- bitwise voting: voter counts number of 1s and 0s in column - bigger count configures the result
-- Ex. for 3 - modular redundancy: 
-- 0101,
-- 0101,
-- 1101
-- ____
-- 0101  
process(voter_i)
    variable ones : integer;
begin

    for bit in 0 to 2*INPUT_WIDTH-1 loop
        ones := 0;
        
        for mod_idx in 0 to MODULE_NUM-1 loop
            if voter_i(mod_idx)(bit) = '1' then
                ones := ones + 1;
            end if;
        end loop;
        if ones > MODULE_NUM/2 then
            majority_vote(bit) <= '1';
        else
            majority_vote(bit) <= '0';
        end if;
        
    end loop;

end process;

voter_o <= majority_vote;

end Behavioral;