--+----------------------------------------------------------------------------
--| 
--| COPYRIGHT 2017 United States Air Force Academy All rights reserved.
--| 
--| United States Air Force Academy     __  _______ ___    _________ 
--| Dept of Electrical &               / / / / ___//   |  / ____/   |
--| Computer Engineering              / / / /\__ \/ /| | / /_  / /| |
--| 2354 Fairchild Drive Ste 2F6     / /_/ /___/ / ___ |/ __/ / ___ |
--| USAF Academy, CO 80840           \____//____/_/  |_/_/   /_/  |_|
--| 
--| ---------------------------------------------------------------------------
--|
--| FILENAME      : thunderbird_fsm_tb.vhd (TEST BENCH)
--| AUTHOR(S)     : Capt Phillip Warner
--| CREATED       : 03/2017
--| DESCRIPTION   : This file tests the thunderbird_fsm modules.
--|
--|
--+----------------------------------------------------------------------------
--|
--| REQUIRED FILES :
--|
--|    Libraries : ieee
--|    Packages  : std_logic_1164, numeric_std
--|    Files     : thunderbird_fsm_enumerated.vhd, thunderbird_fsm_binary.vhd, 
--|				   or thunderbird_fsm_onehot.vhd
--|
--+----------------------------------------------------------------------------
--|
--| NAMING CONVENSIONS :
--|
--|    xb_<port name>           = off-chip bidirectional port ( _pads file )
--|    xi_<port name>           = off-chip input port         ( _pads file )
--|    xo_<port name>           = off-chip output port        ( _pads file )
--|    b_<port name>            = on-chip bidirectional port
--|    i_<port name>            = on-chip input port
--|    o_<port name>            = on-chip output port
--|    c_<signal name>          = combinatorial signal
--|    f_<signal name>          = synchronous signal
--|    ff_<signal name>         = pipeline stage (ff_, fff_, etc.)
--|    <signal name>_n          = active low signal
--|    w_<signal name>          = top level wiring signal
--|    g_<generic name>         = generic
--|    k_<constant name>        = constant
--|    v_<variable name>        = variable
--|    sm_<state machine type>  = state machine type definition
--|    s_<signal name>          = state name
--|
--+----------------------------------------------------------------------------
library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  
entity thunderbird_fsm_tb is
end thunderbird_fsm_tb;

architecture test_bench of thunderbird_fsm_tb is 
	
	component thunderbird_fsm is 
	  port(
		i_clk, i_reset  : in    std_logic;
        i_left, i_right : in    std_logic;
        o_lights_L      : out   std_logic_vector(2 downto 0);
        o_lights_R      : out   std_logic_vector(2 downto 0)
	  );
	end component thunderbird_fsm;

	-- Test I/O signals
	--Inputs
	signal w_iL : std_logic := '0';--input for left
	signal w_iR : std_logic := '0';--input for right
	signal w_reset : std_logic := '0';
	signal w_clk : std_logic := '0';
	--Outputs
	signal w_oL : std_logic_vector(2 downto 0) := "000";--The left light output is set default to 0
	signal w_oR : std_logic_vector(2 downto 0) := "000";
	
	-- Constants
	-- Clock period definitions
	constant k_clk_period : time := 10 ns;
	
begin
	-- PORT MAPS ----------------------------------------
	-- Instantiate the Unit Under Test (UUT)
   uut: thunderbird_fsm port map (
          i_left => w_iL,
          i_right => w_iR,
          i_reset => w_reset,
          i_clk => w_clk,
          o_lights_L => w_oL,
          o_lights_R => w_oR
        );
	-----------------------------------------------------
	
	-- PROCESSES ----------------------------------------	
    -- Clock process ------------------------------------
    clk_proc : process
	begin
		w_clk <= '0';
        wait for k_clk_period/2;
		w_clk <= '1';
		wait for k_clk_period/2;
	end process;
	-----------------------------------------------------
	
	-- Test Plan Process --------------------------------
	-- Simulation process
	-- Use 220 ns for simulation
	sim_proc: process
	begin
	   -- sequential timing, set the reset so in stable state
	   --test reset	
		w_reset <= '1';
		wait for k_clk_period*1;
		  assert w_oL = "000" report "bad reset left" severity failure;
		  assert w_oR = "000" report "bad reset right" severity failure;
		
		w_reset <= '0';
		wait for k_clk_period*1;
		
		--start test cases:
		--assert that after pressing left, after 1 clock cycle, the output for left is 001 (only LA is lit up)
		w_iL <= '1'; wait for k_clk_period;--input left and wait a cycle
		  assert (w_oL = "001" AND w_oR = "000") report "bad LA" severity failure;
		--assert that after another cycle, the output for left is 011 (LA+LB is lit up)
		wait for k_clk_period;
		  assert (w_oL = "011" AND w_oR = "000") report "bad LB" severity failure;
	   --assert that after another cycle, the output for left is 111 (LA+LB+LC is lit up)
		wait for k_clk_period;
		  assert (w_oL = "111" AND w_oR = "000") report "bad LC" severity failure;
		--assert that after another cycle, the output for both is 0 (goes back to off state)
		wait for k_clk_period;
		  assert (w_oL = "000" AND w_oR = "000") report "bad off after LC" severity failure;
		
		w_iL <= '0';--reset the left input
		wait for k_clk_period;--extra wait 
		
		--Same tests as above but for right side
		w_iR <= '1'; wait for k_clk_period;--input right and wait a cycle
		  assert (w_oR = "001" AND w_oL = "000") report "bad RA" severity failure;
		--RB
		wait for k_clk_period;
		  assert (w_oR = "011" AND w_oL = "000") report "bad RB" severity failure;
	   --RC
		wait for k_clk_period;
		  assert (w_oR = "111" AND w_oL = "000") report "bad RC" severity failure;
		--assert that after another cycle, the output for both is 0 (goes back to off state)
		wait for k_clk_period;
		  assert (w_oL = "000" AND w_oR = "000") report "bad off after RC" severity failure;
		
		w_iR <= '0';--reset the right input
		wait for k_clk_period;--extra wait
		
		--Test hazards
		w_iR <= '1';
		w_iL <= '1';--turn on both inputs
		
		wait for k_clk_period;
		  assert (w_oR = "111" AND w_oL = "111") report "bad Hazards" severity failure;
		
		--At this point, the core functionality of left and right work as intended. We now must test edge cases
		
		w_iR <= '0';
		w_iL <= '0';--turn back off both inputs
		wait for k_clk_period;
		--test that if left is hit, it runs through all left lights even if left is changed to off
		w_iL <= '1';--hit left
		wait for k_clk_period;--wait a cycle (LA should be on)
		
		w_iL <= '0'; wait for k_clk_period;--turn left off, wait (still should be on LB)
		  assert (w_oL = "011" AND w_oR = "000") report "bad edge" severity failure;
		
		
		
		wait;
	end process;
	-----------------------------------------------------	
	
end test_bench;
