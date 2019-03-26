library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myip_v1_1_M00_AXIS is
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- 
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(31 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((32/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic;
		
		
		FIFO_RD_EN : out std_logic;
		FIFO_EMPTY : in std_logic;
		FIFO_RD_DATA : in std_logic_vector(31 downto 0)
	);
end myip_v1_1_M00_AXIS;

architecture implementation of myip_v1_1_M00_AXIS is
	-- Total number of output data                                              
	constant NUMBER_OF_OUTPUT_WORDS : integer := 64;                                                                                                                                  

	 -- WAIT_COUNT_BITS is the width of the wait counter.                       
	 constant  WAIT_COUNT_BITS  : integer := 5;               
	                                                                                  
	-- In this example, Depth of FIFO is determined by the greater of                 
	-- the number of input words and output words.                                    
	constant depth : integer := NUMBER_OF_OUTPUT_WORDS;                               
	                                                                                  
	-- bit_num gives the minimum number of bits needed to address 'depth' size of FIFO
	constant bit_num : integer := 6;                                      
	                                                                                  
	-- Define the states of state machine                                             
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO                                   
	type state is ( IDLE,        -- This is the initial/idle state
	                SEND_STREAM,STALL_STATE);  -- In this state the                               
	                             -- stream data is output through M_AXIS_TDATA        
	-- State variable                                                                 
	signal  mst_exec_state : state;                                                   
	-- Example design FIFO read pointer                                               
	signal read_pointer : integer range 0 to bit_num-1;                               

	-- AXI Stream internal signals
	--wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
	signal count	: std_logic_vector(WAIT_COUNT_BITS-1 downto 0);
	--streaming data valid
	signal axis_tvalid	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--Last of the streaming data 
	signal axis_tlast	: std_logic;
	--Last of the streaming data delayed by one clock cycle
	signal axis_tlast_delay	: std_logic;
	--FIFO implementation signals
	--signal stream_data_out	: std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_en	: std_logic;
	--The master has issued all the streaming data stored in FIFO
	signal tx_done	: std_logic;


begin
	-- I/O Connections assignments

	M_AXIS_TVALID	<= axis_tvalid_delay;
	--M_AXIS_TDATA	<= stream_data_out;
	--M_AXIS_TLAST	<= axis_tlast_delay;
	--M_AXIS_TSTRB	<= (others => '1');


	-- Control state machine implementation                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      mst_exec_state      <= IDLE;                                                          
	      count <= (others => '0');                                                             
	    else                                                                                    
	      case (mst_exec_state) is                                                              
	        when IDLE     =>                                                                    
	          -- The slave starts accepting tdata when                                          
	          -- there tvalid is asserted to mark the                                           
	          -- presence of valid streaming data                                               
	          --if (count = "0")then
	          
	          --if (FIFO_EMPTY = '0') then
	          if ((M_AXIS_TREADY = '1'))  then                                                   
	            mst_exec_state <= SEND_STREAM;
	          
	          --elsif (FIFO_EMPTY = '0')  then
	          --  mst_exec_state <= STALL_STATE;
	          elsif (FIFO_EMPTY = '1') then
	            mst_exec_state <= IDLE;                                                         
	          end if;                                                                                                                                              
	                                                                                            
	        when SEND_STREAM  =>                                                                
	          -- The example design streaming master functionality starts                       
	          -- when the master drives output tdata from the FIFO and the slave                
	          -- has finished storing the S_AXIS_TDATA                                          
	          if ((M_AXIS_TREADY = '0') or (axis_tvalid = '0')) then                                                           
	            mst_exec_state <= IDLE;                                                         
	          elsif (axis_tvalid = '1' and M_AXIS_TREADY = '1') then
	            M_AXIS_TDATA <= FIFO_RD_DATA;
	          --else                                                                          
	            mst_exec_state <= SEND_STREAM;                                                  
	          end if;                                                                           
	        
	        when STALL_STATE =>
	           mst_exec_state <= SEND_STREAM;
	                                                                                            
	        when others    =>                                                                   
	          mst_exec_state <= IDLE;                                                           
	                                                                                            
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                


	--tvalid generation
	--axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	--number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	
	axis_tvalid <= '1' when ((mst_exec_state = SEND_STREAM) and (FIFO_EMPTY = '0')) else '0';
	--axis_tvalid <= '1' when ((mst_exec_state = SEND_STREAM) and (read_pointer < NUMBER_OF_OUTPUT_WORDS) and (FIFO_EMPTY = '0')) else '0';                   
	--axis_tvalid <= '1' when (FIFO_EMPTY = '0') else '0';                                                                     
	
	-- Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	-- to match the latency of M_AXIS_TDATA                                                        
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      axis_tvalid_delay <= '0';                                                                
	      axis_tlast_delay <= '0';                                                                 
	    else                                                                                       
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end if;                                                                                    
	  end if;                                                                                      
	end process;                                                                                   


	--read_pointer pointer

	process(M_AXIS_ACLK)                                                       
	begin                                                                            
	  if (rising_edge (M_AXIS_ACLK)) then                                            
	    if(M_AXIS_ARESETN = '0') then                                                
	      read_pointer <= 0;                                                         
	      tx_done  <= '0';                                                           
	    else                                                                         
	      if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1) then                         
	        if (tx_en = '1') then                                                    
	          -- read pointer is incremented after every read from the FIFO          
	          -- when FIFO read signal is enabled.                                   
	          read_pointer <= read_pointer + 1;                                      
	          tx_done <= '0';                                                        
	        end if;                                                                  
	      elsif (read_pointer = NUMBER_OF_OUTPUT_WORDS) then                         
	        -- tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
	        -- has been out.                                                         
	        tx_done <= '1';                                                          
	      end  if;                                                                   
	    end  if;                                                                     
	  end  if;                                                                       
	end process;                                                                     


	--FIFO read enable generation 

	tx_en <= M_AXIS_TREADY and axis_tvalid and (not FIFO_EMPTY);

	-- Add user logic here
    FIFO_RD_EN <= tx_en;
    --FIFO_EMPTY <=
    --M_AXIS_TDATA <= FIFO_RD_DATA;
	-- User logic ends

end implementation;
