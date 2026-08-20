-- novi kod
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.param_package.all;
use work.util_pkg.all;

entity fir is
    generic(fir_ord : natural := FIR_ORDER;
            input_data_width : natural := INPUT_WIDTH;
            output_data_width : natural := INPUT_WIDTH);
    Port ( 
           clk_i : in STD_LOGIC;
    
        -- coeff loading
           we_i : in STD_LOGIC;
           coef_addr_i : std_logic_vector(log2c(fir_order + 1)-1 downto 0);
           coef_i : in STD_LOGIC_VECTOR (input_width-1 downto 0);
           
        -- AXI4-Stream Slave
            s_axis_tdata_i  : in  std_logic_vector(input_width-1 downto 0);
            s_axis_tvalid_i : in  std_logic;
            s_axis_tready_o : out std_logic;
        
        -- AXI4-Stream Master
            m_axis_tdata_o  : out std_logic_vector(output_width-1 downto 0);
            m_axis_tvalid_o : out std_logic;
            m_axis_tready_i : in  std_logic
                         
           
           );
end fir;

architecture Behavioral of fir is

    type std_2d is array (fir_ord downto 0) of std_logic_vector(2*input_width-1 downto 0);
    signal mac_inter : std_2d :=(others=>(others=>'0'));
    type coef_t is array (fir_ord downto 0) of std_logic_vector(input_width-1 downto 0);
    signal b_s : coef_t := (others=>(others=>'0')); 


    signal s_axis_tready_s, m_axis_tvalid_s:std_logic:='0';    
    signal data_i, data_o: std_logic_vector(input_width-1 downto 0);  
    signal coeff_loaded: std_logic:= '0';

-- fault tolerant mac component
component redundancy_unit is
      Port (
           clk: in std_logic;
           u_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           b_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           sec_i : in STD_LOGIC_VECTOR (2*INPUT_WIDTH-1 downto 0);
           sec_o : out STD_LOGIC_VECTOR (2*INPUT_WIDTH-1 downto 0);
           error_o: out std_logic
       );
end component;

-- signal from ft mac component
signal error_array: FD_OUT_ARRAY(FIR_ORDER downto 0);

-- state machine
type state_t is ( init, wait_input, run_pipe, output, wait_output, recovery );
signal state, next_state : state_t := init;    

-- FIR pipeline latency
signal stall_cnt  : std_logic_vector(10 downto 0) := (others => '0');-- stall counter
signal stall_cycles  : std_logic_vector(10 downto 0) := (others => '0'); 

constant PHASE_LATENCY : natural := 0;                                     
constant FIR_LATENCY : natural := 5;--4*FIR_ORDER;                                     
signal result_reg : std_logic_vector(output_data_width-1 downto 0) := (others => '0');                                     
            
signal first_time: std_logic:='0';            
signal fault_flag: std_logic:='0';                                 


-------------- LOGIC ------------                                                      
begin

--Load coeffs
    process(clk_i)
    begin
        if(rising_edge(clk_i))then
            if we_i = '1' then
                b_s(to_integer(unsigned(coef_addr_i))) <= coef_i;
                
           if(to_integer(unsigned(coef_addr_i)) = FIR_ORDER)then -- upisani su koeficijenti
                coeff_loaded <= '1';
           end if;     
                
            end if;
        end if;
    end process;


-- state machine:
-- state reg
    process(clk_i)
    begin
        if rising_edge(clk_i) then
                state <= next_state;
        end if;
    end process;

-- PIPE COUNTER
process(clk_i)
begin
    if rising_edge(clk_i) then

        if state = run_pipe then

            if unsigned(stall_cnt) < unsigned(stall_cycles) then
                stall_cnt <= std_logic_vector(
                    unsigned(stall_cnt) + 1
                );
            end if;

        else
            stall_cnt <= (others => '0');

        end if;

    end if;
end process;

-- FSM:
    process(state, coeff_loaded, s_axis_tvalid_i, s_axis_tready_s, stall_cnt, data_o, m_axis_tready_i, error_array)
    
    begin
    -- default values
    next_state      <= state;

    s_axis_tready_s <= '0';
    m_axis_tvalid_s <= '0';

    case state is

--	INITIAL STATE
        when init =>
            first_time <= '1';
            if coeff_loaded = '1' then
                s_axis_tready_s <= '1';

                next_state <= wait_input;
            end if;
            

-- 	WAIT INPUT - wait for new sample
        when wait_input =>

            s_axis_tready_s <= '1';

-- Priority
           if unsigned(error_array) /= 0 then
                next_state <= recovery;
            else
                if(first_time = '1')then
                --first_time <= '0';
                stall_cycles <= std_logic_vector(to_unsigned(FIR_LATENCY, 11));
                else
                stall_cycles <= std_logic_vector(to_unsigned(PHASE_LATENCY, 11));
                end if;
                if s_axis_tvalid_i = '1' then
                    next_state <= run_pipe; -- sample taken
                end if;
            end if;
--	RUN PIPE: sample accepted, waiting for FIR response
        when run_pipe =>
        if(first_time = '1')then
            first_time <= '0';
        end if;
            s_axis_tready_s <= '0';
            m_axis_tvalid_s <= '0';
-- priority
           if unsigned(error_array) /= 0 then
                next_state <= recovery;
            else    
            if unsigned(stall_cnt) >= unsigned(stall_cycles) then
                next_state <= output;
            end if;
        end if;
--	OUTPUT: output is ready
        when output =>

            s_axis_tready_s <= '0';
            m_axis_tvalid_s <= '1';

            if m_axis_tready_i = '1' then
                next_state <= recovery;
            else
                next_state <= wait_output;
            end if;


--	WAIT OUTPUT : waiting for dowstream to accept the result ? probably not necessary
        when wait_output =>

            s_axis_tready_s <= '0';
            m_axis_tvalid_s <= '1';
           if unsigned(error_array) /= 0 then
                next_state <= recovery;
           else     
            if m_axis_tready_i = '1' then
                next_state <= recovery;
            end if;
        end if;
--	RECOVERY - fault logic 
        when recovery =>

            s_axis_tready_s <= '0';
            m_axis_tvalid_s <= '0';
            
            if unsigned(error_array) /= 0 then
                next_state <= recovery;
            else
                next_state <= wait_input;
            end if;

    end case;

end process;


------------------------------------------

-- MAC modules instances    
    first_section:
    redundancy_unit port map(clk=>clk_i,
             u_i=>data_i,
             b_i=>b_s(fir_ord),
             sec_i=>(others=>'0'),
             sec_o=>mac_inter(0),
             error_o => error_array(0)
             );
                     
    other_sections:
    for i in 1 to fir_order generate
        fir_section:
        redundancy_unit port map(clk=>clk_i,
                 u_i=>data_i,
                 b_i=>b_s(fir_ord-i),
                 sec_i=>mac_inter(i-1),
                 sec_o=>mac_inter(i),
                 error_o => error_array(i)
                 );
    end generate;


--  FIR input  
    process(clk_i)
    begin
    if(rising_edge(clk_i))then
    
        if (s_axis_tvalid_i = '1' and s_axis_tready_s = '1' and state=wait_input)then
            data_i <= s_axis_tdata_i;
                   
        end if;
    
    end if;
    end process;
    
-- FIR output    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
    
            if state = run_pipe then
    
                if unsigned(stall_cnt) = unsigned(stall_cycles) then
    
                    result_reg <= mac_inter(fir_ord)(
                        2*input_data_width-2 downto
                        2*input_data_width-output_data_width-1
                    );
    
                end if;
    
            end if;
    
        end if;
    end process;
    m_axis_tdata_o <= result_reg;
 
 -- handshake wire
 s_axis_tready_o <= s_axis_tready_s;
 m_axis_tvalid_o <= m_axis_tvalid_s;
 
 
end Behavioral;