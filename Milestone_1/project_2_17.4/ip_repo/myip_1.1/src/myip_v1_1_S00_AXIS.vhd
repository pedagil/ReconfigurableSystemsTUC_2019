library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myip_v1_1_S00_AXIS is
	port (
	    --Slave clock & reset.
	    --WARNING: Reset is active low.
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		
		--AXI4-Stream basic implementation signals
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TVALID	: in std_logic;
		S_AXIS_TDATA	: in std_logic_vector(31 downto 0);
		
		--S_AXIS_TSTRB & S_AXIS_TLAST exist, but are not implemented in the
		--current version of the design. They only exist so they can be connected
		--to the DMA, because otherwise vivado will throw errors for non-connected ports.
		S_AXIS_TSTRB	: in std_logic_vector(3 downto 0);
		S_AXIS_TLAST	: in std_logic;
		
		--New signals to support communication with FIFO module.
		--FIFO write enable
		FIFO_WR_EN : out std_logic;
		--Signal indicating FIFO is full
		FIFO_FULL : in std_logic;
		--Data to be written in FIFO
		FIFO_WR_DATA : out std_logic_vector(31 downto 0)
	);
end myip_v1_1_S00_AXIS;

architecture arch_imp of myip_v1_1_S00_AXIS is 
	
	type state is ( RESET_STATE,IDLE,
	                WRITE_FIFO);
	                
	signal axis_tready	: std_logic;
	-- State variable
	signal  mst_exec_state : state;     
	-- FIFO write enable
	signal fifo_wren : std_logic;

begin

	
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      -- Synchronous reset (active low)
	      mst_exec_state <= RESET_STATE;
	    else
	      case (mst_exec_state) is
	        when RESET_STATE =>
	             mst_exec_state <= IDLE;
	             
	        when IDLE     => 
	          if (S_AXIS_TVALID = '1')then
	            mst_exec_state <= WRITE_FIFO;
	          else
	            mst_exec_state <= IDLE;
	          end if;
	      
	        when WRITE_FIFO => 
	          if (S_AXIS_TVALID = '0') then
	            mst_exec_state <= IDLE;
	          else
	            mst_exec_state <= WRITE_FIFO;
	          end if;
	        
	        when others    => 
	          mst_exec_state <= IDLE;
	        
	      end case;
	    end if;  
	  end if;
	end process;
	
	--Logic for the outputs of the slave module
	--FIFO write enable
	fifo_wren <= S_AXIS_TVALID and axis_tready;
	FIFO_WR_EN <= fifo_wren;
	
	--S_AXIS_TREADY to be sent to the DMA
	axis_tready <= '1' when ((not (mst_exec_state = RESET_STATE)) and (FIFO_FULL = '0')) else '0';
	S_AXIS_TREADY	<= axis_tready;
    
    --Data hust passing from slave to FIFO.
    FIFO_WR_DATA <= S_AXIS_TDATA;
    
end arch_imp;
