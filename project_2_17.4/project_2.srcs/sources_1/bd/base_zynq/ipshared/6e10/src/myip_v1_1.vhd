library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity myip_v1_1 is
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(31 downto 0);
		m00_axis_tstrb	: out std_logic_vector(3 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(31 downto 0);
		s00_axis_tstrb	: in std_logic_vector(3 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic
	);
end myip_v1_1;

architecture arch_imp of myip_v1_1 is

	component myip_v1_1_M00_AXIS is
		port (
		M_AXIS_ACLK	: in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(31 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector(3 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic;

		FIFO_RD_EN : out std_logic;
		FIFO_EMPTY : in std_logic;
		FIFO_RD_DATA : in std_logic_vector(31 downto 0)
		);
	end component myip_v1_1_M00_AXIS;

	component myip_v1_1_S00_AXIS is
		port (
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(31 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector(3 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic;
		
  		FIFO_WR_EN : out std_logic;
        FIFO_FULL : in std_logic;
        FIFO_WR_DATA : out std_logic_vector(31 downto 0)
		);
	end component myip_v1_1_S00_AXIS;

	component FIFO is
      port (
        i_rst_sync : in std_logic;
        i_clk      : in std_logic;
     
        -- FIFO Write Interface
        i_wr_en   : in  std_logic;
        i_wr_data : in  std_logic_vector(31 downto 0);
        o_full    : out std_logic;
     
        -- FIFO Read Interface
        i_rd_en   : in  std_logic;
        o_rd_data : out std_logic_vector(31 downto 0);
        o_empty   : out std_logic
        );
	end component FIFO;

--Slave-FIFO Interface
signal slave2FIFOWrEn, FIFO2SlaveFull: std_logic;
signal slave2FIFOWrData: std_logic_vector (31 downto 0);

--Master FIFO Interface
signal master2FIFORdEn, FIFO2MasterEmpty: std_logic;
signal FIFO2MasterRdData: std_logic_vector(31 downto 0);

begin

myip_v1_1_M00_AXIS_inst : myip_v1_1_M00_AXIS
	port map (
		M_AXIS_ACLK	=> m00_axis_aclk,
		M_AXIS_ARESETN	=> m00_axis_aresetn,
		M_AXIS_TVALID	=> m00_axis_tvalid,
		M_AXIS_TDATA	=> m00_axis_tdata,
		M_AXIS_TSTRB	=> m00_axis_tstrb,
		M_AXIS_TLAST	=> m00_axis_tlast,
		M_AXIS_TREADY	=> m00_axis_tready,
		FIFO_RD_EN => master2FIFORdEn,
        FIFO_EMPTY => FIFO2MasterEmpty,
        FIFO_RD_DATA => FIFO2MasterRdData
	);

-- Instantiation of Axi Bus Interface S00_AXIS
myip_v1_1_S00_AXIS_inst : myip_v1_1_S00_AXIS
	port map (
		S_AXIS_ACLK	=> s00_axis_aclk,
		S_AXIS_ARESETN	=> s00_axis_aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TSTRB	=> s00_axis_tstrb,
		S_AXIS_TLAST	=> s00_axis_tlast,
		S_AXIS_TVALID	=> s00_axis_tvalid,
		FIFO_WR_EN => slave2FIFOWrEn,
        FIFO_FULL => FIFO2SlaveFull,
        FIFO_WR_DATA => slave2FIFOWrData
	);

myFIFO : FIFO
      port map(
        i_rst_sync => s00_axis_aresetn,
        i_clk => s00_axis_aclk,
        i_wr_en => slave2FIFOWrEn,
        i_wr_data => slave2FIFOWrData,
        o_full => FIFO2SlaveFull,
        i_rd_en => master2FIFORdEn,
        o_rd_data => FIFO2MasterRdData,
        o_empty => FIFO2MasterEmpty
        );

end arch_imp;