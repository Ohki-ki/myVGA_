----------------------------------------------------------------------------------
--Author:	Lucy Chikwetu 
--Date Created:	6 February 2016
--Description:	This is a VGA time generatior for 640 x 480-pixel VGA video.
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY myVGA IS
	PORT(	clk: 		IN STD_LOGIC;
			reset_l:	IN STD_LOGIC;
			rxf_l:	IN STD_LOGIC;
			txe_l:	IN STD_LOGIC;
			oe_l:		OUT STD_LOGIC;
			rd_l:		OUT STD_LOGIC;
			wr_l:		OUT STD_LOGIC;
			siwua:	OUT STD_LOGIC;
			d:			INOUT STD_LOGIC_VECTOR(7 DOWNTO 0):= "ZZZZZZZZ";
			--VGA Ports
			r:		OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			g:		OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			b:		OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
			hs:	OUT STD_LOGIC;
			vs:	OUT STD_LOGIC);
END myVGA;

ARCHITECTURE timing OF myVGA IS 
	TYPE states IS (init,s0,s1,s2,s3,s4,s5,s6,s7);
	SIGNAL state:		states := init;
	SIGNAL nextState:	states := init;
	SIGNAL dInternal:	STD_LOGIC_VECTOR(7 DOWNTO 0) := "ZZZZZZZZ"; 
	SIGNAL eni:			STD_LOGIC;
	SIGNAL eno:			STD_LOGIC;
	SIGNAL nextENO:	STD_LOGIC;
	SIGNAL nextOE:		STD_LOGIC;
	SIGNAL nextRD:		STD_LOGIC;
	SIGNAL nextWR:		STD_LOGIC;

	--VGA signals 
	SIGNAL videoON:	STD_LOGIC;
	SIGNAL hVideo:		STD_LOGIC;
	SIGNAL vVideo:		STD_LOGIC;
	SIGNAL hCount:		STD_LOGIC_VECTOR(9 downto 0):="0000000000";
	SIGNAL vCount:		STD_LOGIC_VECTOR(9 downto 0):="0000000000";
	
	SIGNAL vgaClk:		STD_LOGIC;
	SIGNAL dcmClk:		STD_LOGIC;
	
	--clock Manager
	COMPONENT myClockManager
	PORT
	 (-- Clock in ports
	  CLK_IN1: 			IN STD_LOGIC;
	  -- Clock out ports
	  dcmClk: 			OUT STD_LOGIC;
	  vgaClk:			OUT STD_LOGIC);
	END COMPONENT;


BEGIN
	clockManager : myClockManager
	PORT MAP
   (-- Clock in ports
    CLK_IN1 => clk,
    -- Clock out ports
    dcmClk => dcmClk,
    vgaClk => vgaClk);
	--------------------------------------------------------------
	--verticalCounter		
	--------------------------------------------------------------
	PROCESS(vgaClk)
	BEGIN 
		IF (vgaClk'event AND vgaClk='1') THEN --vC rising edge 
			IF (hCount = 799) THEN --799
				IF (vCount = 524) THEN --vCount = 524
					vCount <= (others => '0');
				ELSE
					vCount <= vCount + 1;
				END IF; --vCount = 524
			END IF; --799
		END IF; --vC rising edge
	END PROCESS;
	
	PROCESS(vCount)
	BEGIN
	vVideo <= '0';
	IF (vCount >= 34 AND vCount <= 515) THEN
		vVideo <= '1';
	END IF;
	END PROCESS;
	--------------------------------------------------------------
	
	
	--************************************************************
	--	horizontalCounter:	
	--************************************************************
	PROCESS(vgaClk)
	BEGIN
	IF (vgaClk'event AND vgaClk='1') THEN --hC rising edge 
		IF (hCount = 799) THEN
			hCount <= (others => '0');
		ELSE
			hCount <= hCount + 1;
		END IF;
	END IF; --hC rising edge
	END PROCESS;

	PROCESS(hCount)
	BEGIN
	hVideo <= '0';
	IF (hCount>=143 AND hCount<=783) THEN
		hVideo <= '1';
	END IF;
	END PROCESS;
	--************************************************************
	
	
	--------------------------------------------------------------							
	--	syncing:		
	--------------------------------------------------------------		
	PROCESS(vgaClk)
	BEGIN
	IF (vgaClk'event AND vgaClk = '1') THEN --syncing rising edge
		IF (hCount<=95) THEN --**
			hs <= '0';
		ELSE 
			hs <= '1';
		END IF; --**
		IF (vCount <=1) THEN --++
			vs <= '0';
		ELSE 
			vs <= '1';
		END IF; --++	
	END IF; --syncing rising edge
	END PROCESS;
	--------------------------------------------------------------

	videoON <= hVideo AND vVideo;


	--************************************************************
	--	rgb:		
	--************************************************************
	PROCESS(vgaClk)
	BEGIN 
	IF (vgaClk'event AND vgaClk='1') THEN --rising edge 
		IF (videoON='1') THEN
			r(0) <= hCount(8);
			r(1) <= hCount(5);
			r(2) <= hCount(2);
			g(0) <= hCount(7);
			g(1) <= hCount(4);
			g(2) <= hCount(1);
			b(0) <= hCount(6);
			b(1) <= hCount(3);
			b(2) <= hCount(0);
		END IF;
	END IF; --rising edge
	END PROCESS;
	--************************************************************
	
	--------------------------------------------------------------
	-- LOOPBACK CODE BEGINS HERE!
	--------------------------------------------------------------
	--********************************************************************************
	-- PROCESS TO DETERMINE NEXT STATE
	--********************************************************************************
	
	----------------------------------------------------------------------------------
	-- PROCESS TO IMPLEMENT  THE STATE REGISTER
	----------------------------------------------------------------------------------
	stateRegister: PROCESS(dcmClk)
	BEGIN
	IF (dcmClk'EVENT AND dcmClk = '1') THEN
		IF (reset_l = '0') THEN 
			state <= init;
		ELSE 
			state <= nextState;
		END IF;
	END IF;
	END PROCESS stateRegister;

	----------------------------------------------------------------------------------
	
	stateTransition: PROCESS (rxf_l, txe_l,state)
	BEGIN 
		nextState <= state;
		CASE state IS
			WHEN init =>
				nextState <= s0;
			WHEN s0 => IF (rxf_l = '0') THEN
				nextState <= s1;
			ELSE 
				nextState <= s0;
			END IF;
			WHEN s1 =>
				nextState <= s2;
			WHEN s2 =>
				nextState <= s3;
			--Turn-around cycle
			WHEN s3 => 
				IF (txe_l = '0') THEN 
					nextState <= s4;
				ELSE 
					nextState <= s3;
				END IF;
			WHEN s4 => 
				nextState <= s5;
			WHEN s5 =>
				nextState <= s6;
			WHEN s6 =>
				nextState <= s7;
			WHEN s7 =>
				nextState <= s0;
		END CASE;
	END PROCESS stateTransition;
	nextOE <= '0' WHEN ((state = s0 OR state = s1) AND (rxf_l /= 'U')) ELSE '1';
	nextRD <= '0' WHEN (state = s1) ELSE '1';
	nextWR <= '0' WHEN (state = s3) ELSE '1';
	eni  <= '1' WHEN (state = s2) ELSE '0';
	nextENO <= '0' WHEN (state = s3) ELSE '1';
	siwua <= '0' WHEN (state = s7) ELSE '1';

	--********************************************************************************

	----------------------------------------------------------------------------------
	-- DATA PATH
	----------------------------------------------------------------------------------
	dataPath: PROCESS(dcmClk)
	BEGIN
		IF (dcmClk'EVENT AND dcmClk='1') THEN 
			IF (eni = '1') THEN 
				dInternal <= d;
			END IF;
		END IF;
	END PROCESS dataPath;
	d <= dInternal WHEN (eno = '0') ELSE "ZZZZZZZZ";
	----------------------------------------------------------------------------------

	--********************************************************************************
	-- nextENO
	--********************************************************************************
	enoFF: PROCESS(dcmClk)
	BEGIN
		IF (dcmClk'EVENT AND dcmClk='1') THEN 
				oe_l <= nextOE;
				rd_l <= nextRD;
				wr_l <= nextWR;
				eno  <= nextENO; 
		END IF;
	END PROCESS enoFF;
	--********************************************************************************
	
	--------------------------------------------------------------
	-- LOOPBACK CODE ENDS HERE!
	--------------------------------------------------------------

END timing;

