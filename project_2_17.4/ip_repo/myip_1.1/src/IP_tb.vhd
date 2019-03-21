library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity myip_v1_1_tb is
end;

architecture bench of myip_v1_1_tb is

  component myip_v1_1
  	port (
  		m00_axis_aclk	: in std_logic;
  		m00_axis_aresetn	: in std_logic;
  		m00_axis_tvalid	: out std_logic;
  		m00_axis_tdata	: out std_logic_vector(31 downto 0);
  		m00_axis_tready	: in std_logic;
		m00_axis_tstrb	: out std_logic_vector(3 downto 0);
        m00_axis_tlast    : out std_logic;  		
  		
  	    s00_axis_tstrb	: in std_logic_vector(3 downto 0);
        s00_axis_tlast    : in std_logic;
  		s00_axis_aclk	: in std_logic;
  		s00_axis_aresetn	: in std_logic;
  		s00_axis_tready	: out std_logic;
  		s00_axis_tdata	: in std_logic_vector(31 downto 0);
  		s00_axis_tvalid	: in std_logic
  	);
  end component;

  signal m00_axis_aclk: std_logic;
  signal m00_axis_aresetn: std_logic;
  signal m00_axis_tvalid: std_logic;
  signal m00_axis_tdata: std_logic_vector(31 downto 0);
  signal m00_axis_tready: std_logic;
  signal m00_axis_tstrb	: std_logic_vector(3 downto 0);
  signal m00_axis_tlast    : std_logic;  
  signal s00_axis_tlast    : std_logic;
  signal s00_axis_tstrb	: std_logic_vector(3 downto 0);
  signal s00_axis_aclk: std_logic;
  signal s00_axis_aresetn: std_logic;
  signal s00_axis_tready: std_logic;
  signal s00_axis_tdata: std_logic_vector(31 downto 0);
  signal s00_axis_tvalid: std_logic ;

  constant Clk_period : time := 10 ns;

begin

  uut: myip_v1_1 port map ( m00_axis_aclk    => m00_axis_aclk,
                            m00_axis_aresetn => m00_axis_aresetn,
                            m00_axis_tvalid  => m00_axis_tvalid,
                            m00_axis_tdata   => m00_axis_tdata,
                            m00_axis_tready  => m00_axis_tready,
                            m00_axis_tstrb => m00_axis_tstrb,
                            m00_axis_tlast => m00_axis_tlast,
                            s00_axis_aclk    => s00_axis_aclk,
                            s00_axis_aresetn => s00_axis_aresetn,
                            s00_axis_tready  => s00_axis_tready,
                            s00_axis_tdata   => s00_axis_tdata,
                            s00_axis_tstrb => s00_axis_tstrb,
                            s00_axis_tlast => s00_axis_tlast,
                            s00_axis_tvalid  => s00_axis_tvalid );


   Clk_process :process
   begin
		m00_axis_aclk <= '0';
		s00_axis_aclk <= '0';
		wait for Clk_period/2;
		
		m00_axis_aclk <= '1';
		s00_axis_aclk <= '1';
		wait for Clk_period/2;
		
   end process;
   
  stimulus: process
  begin
  
    --Reset (active low)
    m00_axis_aresetn <= '0';
    s00_axis_aresetn <= '0';
    
    --Initialization of signals
    s00_axis_tvalid <= '0';
    s00_axis_tdata <= "00000000000000000000000000000000";
    m00_axis_tready <= '0';
    wait for 10 ns;
    
    --Deassert reset signal
    m00_axis_aresetn <= '1';
    s00_axis_aresetn <= '1';
    wait for 10 ns;
    
    
    --Valid data entering the slave
    --Write 2,3,4 & 5 to FIFO
    
    --Uncomment following line to test simultanious write & read from the FIFO
    --In this scenario, when data is being written to the FIFO, master is reading
    --from FIFO and sending to DMAe slave
    
    m00_axis_tready <= '1';
    
    s00_axis_tvalid <= '1';
    s00_axis_tdata <= "00000000000000000000000000000010";
    wait for 10 ns;
 
    s00_axis_tdata <= "00000000000000000000000000000011";
    wait for 10 ns;   
    
    s00_axis_tdata <= "00000000000000000000000000000100";
    wait for 10 ns;
 
    s00_axis_tdata <= "00000000000000000000000000000101";
    wait for 10 ns;     
    
    --End writing process
    s00_axis_tvalid <= '0';
    
    --Represents rubbish in S_AXIS_DATA 32-bit bus (Slave data input)
    s00_axis_tdata <= "01010000001000000000101000000101";
    wait for 10 ns;
    --Master asserts ready signal to IP for a time window of 50 ns.
    
    m00_axis_tready <= '0';
    wait for 50 ns;
    
    --m00_axis_tready <= '0';
    --wait for 10 ns;    
    
    --Write data until FIFO is full (to check corner case of FIFO being full)
    s00_axis_tvalid <= '1';
    s00_axis_tdata <= "00000000000000000000000000001111";
    wait for 1000 ns;
    
    s00_axis_tvalid <= '0';
    --Then read data until FIFO is empty (to check corner case of FIFO being empty)
    m00_axis_tready <= '1';
    
    wait;
  end process;


end;