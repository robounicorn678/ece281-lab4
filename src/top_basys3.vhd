library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
    signal w_clk_cntrlr : std_logic;
    signal w_clk_tdm: std_logic;
    signal w_floor_1 : std_logic_vector(3 downto 0);
    signal w_floor_2 : std_logic_vector(3 downto 0);
    signal w_clk_reset : std_logic;
    signal w_controller_reset : std_logic;
    signal w_curr_digit : std_logic_vector(3 downto 0);
    signal w_sel : std_logic_vector(3 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    	controller_inst_1: elevator_controller_fsm
    port map(
        i_reset => w_controller_reset,
        is_stopped => sw(0),
        go_up_down => sw(1),
        i_clk => w_clk_cntrlr,
        o_floor => w_floor_1
    );
    
        	controller_inst_2: elevator_controller_fsm
    port map(
        i_reset => w_controller_reset,
        is_stopped => sw(14),
        go_up_down => sw(15),
        i_clk => w_clk_cntrlr,
        o_floor => w_floor_2
    );
	
	    clockdiv_inst: clock_divider
    generic map ( k_DIV => 25000000 )
    port map(
        i_clk => clk,
        i_reset => w_clk_reset,
        o_clk => w_clk_cntrlr
    );
    
        TDM_clockdiv_inst: clock_divider
    generic map (k_DIV => 100000)
    port map(
        i_clk => clk,
        i_reset => '0',
        o_clk => w_clk_tdm
    );
	
	TDM_inst: TDM4
    generic map ( k_WIDTH => 4) -- bits in input and output
    port map(
        i_clk => w_clk_tdm,
        i_reset => '0',
        i_D0 => w_floor_1,
        i_D1 => x"F",
        i_D2 => w_floor_2,
        i_D3 => x"F",
        o_data => w_curr_digit,
        o_sel => w_sel
    );
    
    
    	decoder_inst: sevenseg_decoder
	port map(
	   i_Hex => w_curr_digit,
	   o_seg_n => seg
	);
	
	-- CONCURRENT STATEMENTS ----------------------------
	
--	w_digit_2 <= "1000" when (w_floor = x"8") else 
--            x"7" when (w_floor = x"7") else
--            x"6" when (w_floor = x"6") else
--            x"5" when (w_floor = x"5") else
--            x"4" when (w_floor = x"4") else
--            x"3" when (w_floor = x"3") else
--            x"2" when (w_floor = x"2") else
--            x"1" when (w_floor = x"1") else
--            x"2";

--    w_digit_1 <= x"8" when (w_floor = x"8") else
--            x"7" when (w_floor = x"7") else
--            x"6" when (w_floor = x"6") else
--            x"5" when (w_floor = x"5") else
--            x"4" when (w_floor = x"4") else
--            x"3" when (w_floor = x"3") else
--            x"2" when (w_floor = x"2") else
--            x"1" when (w_floor = x"1") else
--            x"2";
	
	
	
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= w_clk_cntrlr;
	led(14) <= '0';
	led(13) <= '0';
	led(12) <= '0';
	led(11) <= '0';
	led(10) <= '0';
	led(9) <= '0';
	led(8) <= '0';
	led(7) <= '0';
	led(6) <= '0';
	led(5) <= '0';
	led(4) <= '0';
	led(3) <= '0';
	led(2) <= '0';
	led(1) <= '0';
	led(0) <= '0';
	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	an(3) <= w_sel(3);
	an(2) <= w_sel(2);
	an(1) <= w_sel(1);
	an(0) <= w_sel(0);
	
	-- reset signals
	w_clk_reset <= btnU or btnL;
    w_controller_reset <= btnR or btnU;
    
    
end top_basys3_arch;
