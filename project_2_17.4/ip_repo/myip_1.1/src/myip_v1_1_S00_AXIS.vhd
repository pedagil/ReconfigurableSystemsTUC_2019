library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myip_v1_1_S00_AXIS is
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(31 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector(3 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic;
		
		--fifo write enable
		FIFO_WR_EN : out std_logic;
		--signal indicating fifo is full
		FIFO_FULL : in std_logic;
		--data to be written in fifo
		FIFO_WR_DATA : out std_logic_vector(31 downto 0)
	);
end myip_v1_1_S00_AXIS;

architecture arch_imp of myip_v1_1_S00_AXIS is 

	-- Total number of input data.
	constant NUMBER_OF_INPUT_WORDS  : integer := 64;
	
	-- Define the states of state machine
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO
	type state is ( RESET_STATE,IDLE,        -- This is the initial/idle state 
	                WRITE_FIFO); -- In this state FIFO is written with the
	                             -- input stream data S_AXIS_TDATA 
	signal axis_tready	: std_logic;
	-- State variable
	signal  mst_exec_state : state;  
	-- FIFO implementation signals
	signal  byte_index : integer;    
	-- FIFO write enable
	signal fifo_wren : std_logic;
	-- FIFO write pointer
	signal write_pointer : integer range 0 to 5;
	-- sink has accepted all the streaming data and stored in FIFO
	signal writes_done : std_logic;

begin
	-- I/O Connections assignments

	S_AXIS_TREADY	<= axis_tready;
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      -- Synchronous reset (active low)
	      mst_exec_state      <= RESET_STATE;
	    else
	      case (mst_exec_state) is
	        when RESET_STATE =>
	        	 
	             mst_exec_state <= IDLE;
	             
	        when IDLE     => 
	          -- The sink starts accepting tdata when 
	          -- there tvalid is asserted to mark the
	          -- presence of valid streaming data 
	          if (S_AXIS_TVALID = '1')then
	            mst_exec_state <= WRITE_FIFO;
	          else
	            mst_exec_state <= IDLE;
	          end if;
	      
	        when WRITE_FIFO => 
	          -- When the sink has accepted all the streaming input data,
	          -- the interface swiches functionality to a streaming master
	          if (S_AXIS_TVALID = '0') then
	            mst_exec_state <= IDLE;
	          else
	            -- The sink accepts and stores tdata 
	            -- into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end if;
	        
	        when others    => 
	          mst_exec_state <= IDLE;
	        
	      end case;
	    end if;  
	  end if;
	end process;
	-- AXI Streaming Sink 
	-- 
	-- The example design sink is always ready to accept the S_AXIS_TDATA  until
	-- the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	
	--axis_tready <= '1' when ((mst_exec_state = WRITE_FIFO) and (write_pointer <= NUMBER_OF_INPUT_WORDS-1) and (FIFO_FULL = '0')) else '0';
    axis_tready <= '1' when ((not (mst_exec_state = RESET_STATE)) and (FIFO_FULL = '0')) else '0';
   
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      write_pointer <= 0;
	      writes_done <= '0';
	    else
	      if (write_pointer <= NUMBER_OF_INPUT_WORDS-1) then
	        if (fifo_wren = '1') then
	          -- write pointer is incremented after every write to the FIFO
	          -- when FIFO write signal is enabled.
	          write_pointer <= write_pointer + 1;
	          writes_done <= '0';
	        end if;
	        if ((write_pointer = NUMBER_OF_INPUT_WORDS-1)) then
	        --if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
	          -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
	          -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
	          writes_done <= '1';
	        end if;
	      end  if;
	    end if;
	  end if;
	end process;

	-- FIFO write enable generation
	fifo_wren <= S_AXIS_TVALID and axis_tready;
	
	
    FIFO_WR_EN <= fifo_wren;
    FIFO_WR_DATA <= S_AXIS_TDATA;
end arch_imp;
