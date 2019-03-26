library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myip_v1_1_M00_AXIS is
	port (
	    --Clock and Reset
		M_AXIS_ACLK	: in std_logic;
		--WARNING: Reset is active low
		M_AXIS_ARESETN	: in std_logic;
		
		-- Master Stream Ports. TVALID indicates that the master is 
		--driving a valid transfer, A transfer takes place when both 
		--TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the 
		--data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(31 downto 0);
		-- TREADY indicates that the slave can accept a transfer
		--in the current cycle.
        M_AXIS_TREADY    : in std_logic;
        
        
		--TSTRB & TLAST exist but are not implemented in the current design.
		-- TSTRB is the byte qualifier that indicates whether the 
		--content of the associated byte of TDATA is processed as a 
		--data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((32/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;

		
		--New signals. Now there is established communication
		--with a FIFO memory module
		--FIFO Read Enable
		FIFO_RD_EN : out std_logic;
		--Signal indicating FIFO is empty
		FIFO_EMPTY : in std_logic;
		--Data bus
		FIFO_RD_DATA : in std_logic_vector(31 downto 0)
	);
end myip_v1_1_M00_AXIS;

architecture implementation of myip_v1_1_M00_AXIS is
    -- IDLE:        This is the initial/idle state
    -- SEND_STREAM: Transmision of data between master&slave
    --INITIATE_TRANSACTION: Master asserts that he has valid data to send.                                                                                                             
	type state is ( IDLE,
	                SEND_STREAM,INITIATE_TRANSACTION);
	-- State variable                                                                 
	signal  mst_exec_state : state;                                                                                                                               

	signal axis_tvalid	: std_logic;
	signal axis_tvalid_delay	: std_logic;
	signal axis_tlast_delay	: std_logic;
	signal tx_en	: std_logic;

begin
                                         
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      mst_exec_state      <= IDLE;                                                                                                                   
	    else                                                                                    
	      case (mst_exec_state) is                                                              
	        when IDLE     =>                                                                    
	          if ((M_AXIS_TREADY = '1'))  then                                                   
	            mst_exec_state <= SEND_STREAM;

	          elsif (FIFO_EMPTY = '1') then
	            mst_exec_state <= IDLE;
	          elsif (FIFO_EMPTY = '0') then
	            mst_exec_state <= INITIATE_TRANSACTION;                                                     
	          end if;                                                                                                                                              
	                                                                                            
	        when SEND_STREAM  =>                                                                                                        
	          if ((M_AXIS_TREADY = '0') or (axis_tvalid = '0')) then                                                           
	            mst_exec_state <= IDLE;                                                         
	          elsif (axis_tvalid = '1' and M_AXIS_TREADY = '1') then
	            M_AXIS_TDATA <= FIFO_RD_DATA;                                                                        
	            mst_exec_state <= SEND_STREAM;                                                  
	          end if;              
	                                                                       
	        when INITIATE_TRANSACTION =>
	           M_AXIS_TDATA <= FIFO_RD_DATA;
	           if(M_AXIS_TREADY = '1') then
	               mst_exec_state <= SEND_STREAM;
	           end if;
	                                                                                               
	        when others    =>                                                                   
	          mst_exec_state <= IDLE;                                                           
	                                                                                            
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;
    
                                        
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      axis_tvalid_delay <= '0';                                                                                                                                
	    else                                                                                       
	      axis_tvalid_delay <= axis_tvalid;                                                                                                                 
	    end if;                                                                                    
	  end if;                                                                                      
	end process;                                                                                   
                                                                   


	axis_tvalid <= '1' when (((mst_exec_state = SEND_STREAM) or (mst_exec_state = INITIATE_TRANSACTION)) and (FIFO_EMPTY = '0')) else '0';
    M_AXIS_TVALID	<= axis_tvalid_delay;

	tx_en <= M_AXIS_TREADY and axis_tvalid and (not FIFO_EMPTY);
    FIFO_RD_EN <= tx_en;

end implementation;
