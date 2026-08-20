library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.NUMERIC_STD.all;
--use work.util_pkg;

package param_package is 
-- spec parameters
    constant OUTPUT_WIDTH : natural := 24;  -- Output signal width
    constant INPUT_WIDTH : natural := 24;   -- Input signal width
    constant FIR_ORDER : natural := 7;      -- Order of a single fir module
-- redundancy parameters
    constant MODULE_NUM : natural := 5 ;           -- Number of (MAC) modules in N modular redundancy 
    constant SPARE_NUM : natural := 4;      -- Number of voters = 2(active pair) + spare_voters
    
-- multiple inputs from redundent mac
    type MAC_OUT_ARRAY is array (integer range <>) of std_logic_vector(2*INPUT_WIDTH-1 downto 0);
    type FD_OUT_ARRAY is array (integer range <>) of std_logic;
    
-- BIST  - test vectors and expected outputs
constant TEST_VECTOR1 :std_logic_vector(2*INPUT_WIDTH-1 downto 0):= (others => '1');
constant EXPECTED1 :std_logic_vector(2*INPUT_WIDTH-1 downto 0):= (others => '1');

constant TEST_VECTOR2 :std_logic_vector(2*INPUT_WIDTH-1 downto 0):= (others => '0');
constant EXPECTED2 :std_logic_vector(2*INPUT_WIDTH-1 downto 0):= (others => '0');

end param_package;
