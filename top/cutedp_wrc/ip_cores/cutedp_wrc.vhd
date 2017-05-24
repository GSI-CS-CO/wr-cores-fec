library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

---------------------------------------------------------------------------
-- Basic packages needed for instantiating the WR PTP Core
---------------------------------------------------------------------------
-- Use the General Cores package (for gc_extend_pulse)
use work.gencores_pkg.all;
-- Use the WR Core package, with xwr_core component defined inside.
use work.wrcore_pkg.all;
-- Use the Xilinx White Rabbit platform-specific package (for xwrc_platform_xilinx)
use work.wr_xilinx_pkg.all;
-- Use the Endpoint package inside the WR PTP Core for definitions of
-- record-based PHY interfaces phy8_from_wrc, phy8_to_wrc
use work.endpoint_pkg.all;

---------------------------------------------------------------------------
-- Additional packages needed for other HDL modules in this design
---------------------------------------------------------------------------
-- Use the Gennum GN4124 package for PCIe module (gn4124_core)
use work.gn4124_core_pkg.all;
-- Use the package for Etherbone module (eb_slave_core)
use work.etherbone_pkg.all;
-- Use the WR Fabric package for definitions of the WRPC frame interface used
-- for Etherbone
use work.wr_fabric_pkg.all;
-- Use the Wishbone package for definitions of Wishbone interfaces used to
-- control the WRPC from PCIe and Etherbone cores.
use work.wishbone_pkg.all;

---------------------------------------------------------------------------
-- Simulation packages
---------------------------------------------------------------------------
-- Use library UNISIM for PLL_BASE, IBUFGDS and BUFG simulation components.
library UNISIM;
use UNISIM.vcomponents.all;

entity cutedp_wrc is
  generic
    (
      g_sfp0_enable: boolean:= true;
      g_sfp1_enable: boolean:= false;
      -- future work
      g_multiboot_enable: boolean:= false;
      g_etherbone_enable: boolean:= false;
      -- Simulation mode enable parameter. Set by default (synthesis) to 0, and
      -- changed to non-zero in the instantiation of the top level DUT in the testbench.
      -- Its purpose is to reduce some internal counters/timeouts to speed up simulations.
      g_simulation : integer := 0
     );
  port
    (
      ---------------------------------------------------------------------------
      -- Clock signals
      ---------------------------------------------------------------------------
      -- Clock input, used to derive the DDMTD clock (check out the general presentation
      -- of WR for explanation of its purpose). The clock is produced by the
      -- other VCXO, tuned by the second AD5662 DAC, (which is connected to
      -- dac_helper output of the WR Core)
      clk_20m_i     : in std_logic;
      -- 62.5m dmtd clock, from pll drived by clk_20m_vcxo
      clk_dmtd_i    : in std_logic;
      -- 62.5m system clock, from pll drived by clk_125m_pllref
      clk_sys_i     : in std_logic;     
      -- 125m reference clock, from pll drived by clk_125m_pllref
      clk_ref_i     : in std_logic;
      -- Dedicated clock for the Xilinx GTP transceiver.
      clk_gtp0_i    : in std_logic:='0';
      clk_gtp1_i    : in std_logic:='0';
      rst_n_i  		  : in std_logic;
      -- font panel leds
      sfp0_led_o    : out std_logic;
      sfp1_led_o    : out std_logic;

      dac_hpll_load_p1_o : out std_logic;
      dac_hpll_data_o    : out std_logic_vector(15 downto 0);
      dac_dpll_load_p1_o : out std_logic;
      dac_dpll_data_o    : out std_logic_vector(15 downto 0);

      -- Standard SPI interface for EEPROM. Used for storing
      -- SFP database, configuration of the WRPC, etc.
      fpga_scl_i : in  std_logic;
      fpga_scl_o : out std_logic;
      fpga_sda_i : in  std_logic;
      fpga_sda_o : out std_logic;
      ----------------------------------------
      -- Flash memory SPI
      ---------------------------------------
      fpga_prom_cclk_o       : out std_logic;
      fpga_prom_cso_b_n_o    : out std_logic;
      fpga_prom_mosi_o       : out std_logic;
      fpga_prom_miso_i       : in  std_logic:='1';

      thermo_id_i : in  std_logic;
      thermo_id_o : out std_logic;      -- 1-wire interface to ds18b20

      -------------------------------------------------------------------------
      -- sfp pins
      -------------------------------------------------------------------------
      sfp0_txp_o        : out std_logic;
      sfp0_txn_o        : out std_logic;
      sfp0_rxp_i        : in  std_logic:='0';
      sfp0_rxn_i        : in  std_logic:='0';
      sfp0_mod_def0_i   : in  std_logic:='0';  -- sfp detect
      sfp0_mod_def1_i   : in  std_logic:='0';  -- scl
      sfp0_mod_def1_o   : out std_logic;  -- scl
      sfp0_mod_def2_i   : in  std_logic:='0';  -- sda
      sfp0_mod_def2_o   : out std_logic;  -- sda
      sfp0_rate_select_i: in  std_logic:='0';
      sfp0_rate_select_o: out std_logic;
      sfp0_tx_fault_i   : in  std_logic:='0';
      sfp0_tx_disable_o : out std_logic;
      sfp0_los_i        : in  std_logic:='0';

      -- TX gigabit output
      sfp1_txp_o        : out std_logic;
      sfp1_txn_o        : out std_logic;
      -- RX gigabit input
      sfp1_rxp_i        : in  std_logic:='0';
      sfp1_rxn_i        : in  std_logic:='0';
      -- SFP MOD_DEF0 pin (used as a tied-to-ground SFP insertion detect line)
      sfp1_mod_def0_i   : in  std_logic:='0';
      -- SFP MOD_DEF1 pin (SCL line of the I2C EEPROM inside the SFP)
      sfp1_mod_def1_i   : in  std_logic:='0';
      sfp1_mod_def1_o   : out std_logic:='0';
      -- SFP MOD_DEF2 pin (SDA line of the I2C EEPROM inside the SFP)
      sfp1_mod_def2_i   : in  std_logic:='0';
      sfp1_mod_def2_o   : out std_logic:='0';
      -- SFP RATE_SELECT pin. Unused for most SFPs, in our case tied to 0.
      sfp1_rate_select_i: in  std_logic:='0';
      sfp1_rate_select_o: out std_logic;
      -- SFP laser fault detection pin. Unused in our design.
      sfp1_tx_fault_i   : in  std_logic:='0';
      -- SFP laser disable line.
      sfp1_tx_disable_o : out std_logic;
      -- SFP-provided loss-of-link detection. We don't use it as Ethernet PCS
      -- has its own loss-of-sync detection mechanism.
      sfp1_los_i        : in  std_logic:='0';

      pps_o             : out std_logic;
      pps_p1_o          : out std_logic;
      tm_time_valid_o   : out std_logic;
      tm_tai_o          : out std_logic_vector(39 downto 0);
      tm_cycles_o       : out std_logic_vector(27 downto 0);

      -- UART pins (connected to the mini-USB port)
      uart_rxd_i        : in  std_logic:='0';
      uart_txd_o        : out std_logic;
      ------------------------------------------
      -- external module
      ------------------------------------------
      ext_snk_i         : in  t_wrf_sink_in:=c_dummy_snk_in;
      ext_snk_o         : out t_wrf_sink_out;
      ext_src_o         : out t_wrf_source_out;
      ext_src_i         : in  t_wrf_source_in:=c_dummy_src_in;
      ext_master_i      : in t_wishbone_master_in:=cc_unused_master_in;
      ext_master_o      : out t_wishbone_master_out
      );
end cutedp_wrc;

architecture rtl of cutedp_wrc is

  ------------------------------------------------------------------------------
  -- components declaration
  ------------------------------------------------------------------------------
  -- component ext_pll_10_to_125m
  --   port (
  --     clk_ext_i     : in  std_logic;
  --     clk_ext_mul_o : out std_logic;
  --     rst_a_i       : in  std_logic;
  --     clk_in_stopped_o: out  std_logic;
  --     locked_o      : out std_logic);
  -- end component;

  -- MultiBoot component
  -- -- use: remotely reprogram the FPGA
  -- component wb_xil_multiboot is
  --   port
  --   (
  --     -- Clock and reset input ports
  --     clk_i   : in  std_logic;
  --     rst_n_i : in  std_logic;
  --     -- Wishbone ports
  --     wbs_i   : in  t_wishbone_slave_in;
  --     wbs_o   : out t_wishbone_slave_out;
  --     -- SPI ports
  --     spi_cs_n_o : out std_logic;
  --     spi_sclk_o : out std_logic;
  --     spi_mosi_o : out std_logic;
  --     spi_miso_i : in  std_logic
  --   );
  -- end component wb_xil_multiboot;

  component xcute_core is
    generic(
      g_simulation                : integer                        := 0;
      g_with_external_clock_input : boolean                        := true;
      g_phys_uart                 : boolean                        := true;
      g_virtual_uart              : boolean                        := true;
      g_aux_clks                  : integer                        := 0;
      g_ep_rxbuf_size             : integer                        := 1024;
      g_tx_runt_padding           : boolean                        := true;
      g_dpram_initf               : string                         := "";
      g_dpram_size                : integer                        := 131072/4;  --in 32-bit words
      g_interface_mode            : t_wishbone_interface_mode      := PIPELINED;
      g_address_granularity       : t_wishbone_address_granularity := BYTE;
      g_ext_sdb                   : t_sdb_device                   := c_wrc_periph3_sdb;
      g_softpll_enable_debugger   : boolean                        := false;
      g_vuart_fifo_size           : integer                        := 1024;
      g_pcs_16bit                 : boolean                        := false;
      g_records_for_phy           : boolean                        := false;
      g_diag_id                   : integer                        := 0;
      g_diag_ver                  : integer                        := 0;
      g_diag_ro_size              : integer                        := 0;
      g_diag_rw_size              : integer                        := 0);
    port(
      clk_sys_i               : in  std_logic;
      clk_dmtd_i              : in  std_logic;
      clk_ref_i               : in  std_logic;
      clk_aux_i               : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
      clk_ext_i               : in  std_logic := '0';
      clk_ext_mul_i           : in  std_logic := '0';
      clk_ext_mul_locked_i    : in  std_logic := '1';
      clk_ext_stopped_i       : in  std_logic := '0';
      clk_ext_rst_o           : out std_logic;
      pps_ext_i               : in  std_logic := '0';
      rst_n_i                 : in  std_logic;
      dac_hpll_load_p1_o      : out std_logic;
      dac_hpll_data_o         : out std_logic_vector(15 downto 0);
      dac_dpll_load_p1_o      : out std_logic;
      dac_dpll_data_o         : out std_logic_vector(15 downto 0);
      phy_ref_clk_i           : in  std_logic;
      phy_tx_data_o           : out std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
      phy_tx_k_o              : out std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
      phy_tx_disparity_i      : in  std_logic;
      phy_tx_enc_err_i        : in  std_logic;
      phy_rx_data_i           : in  std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
      phy_rx_rbclk_i          : in  std_logic;
      phy_rx_k_i              : in  std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
      phy_rx_enc_err_i        : in  std_logic;
      phy_rx_bitslide_i       : in  std_logic_vector(f_pcs_bts_width(g_pcs_16bit)-1 downto 0);
      phy_rst_o               : out std_logic;
      phy_rdy_i               : in  std_logic := '1';
      phy_loopen_o            : out std_logic;
      phy_loopen_vec_o        : out std_logic_vector(2 downto 0);
      phy_tx_prbs_sel_o       : out std_logic_vector(2 downto 0);
      phy_sfp_tx_fault_i      : in  std_logic := '0';
      phy_sfp_los_i           : in  std_logic := '0';
      phy_sfp_tx_disable_o    : out std_logic;
      phy8_o                  : out t_phy_8bits_from_wrc;
      phy8_i                  : in  t_phy_8bits_to_wrc  := c_dummy_phy8_to_wrc;
      phy16_o                 : out t_phy_16bits_from_wrc;
      phy16_i                 : in  t_phy_16bits_to_wrc := c_dummy_phy16_to_wrc;
      led_act_o               : out std_logic;
      led_link_o              : out std_logic;
      scl_o                   : out std_logic;
      scl_i                   : in  std_logic := '1';
      sda_o                   : out std_logic;
      sda_i                   : in  std_logic := '1';
      sfp_scl_o               : out std_logic;
      sfp_scl_i               : in  std_logic := '1';
      sfp_sda_o               : out std_logic;
      sfp_sda_i               : in  std_logic := '1';
      sfp_det_i               : in  std_logic;
      btn1_i                  : in  std_logic := '1';
      btn2_i                  : in  std_logic := '1';
      spi_sclk_o              : out std_logic;
      spi_ncs_o               : out std_logic;
      spi_mosi_o              : out std_logic;
      spi_miso_i              : in  std_logic := '0';
      uart_rxd_i              : in  std_logic := '0';
      uart_txd_o              : out std_logic;
      owr_pwren_o             : out std_logic_vector(1 downto 0);
      owr_en_o                : out std_logic_vector(1 downto 0);
      owr_i                   : in  std_logic_vector(1 downto 0) := (others => '1');
      slave_i                 : in  t_wishbone_slave_in := cc_dummy_slave_in;
      slave_o                 : out t_wishbone_slave_out;
      ext_master_o            : out t_wishbone_master_out;
      ext_master_i            : in  t_wishbone_master_in := cc_dummy_master_in;
      ext_src_o               : out t_wrf_source_out;
      ext_src_i               : in  t_wrf_source_in := c_dummy_src_in;
      ext_snk_o               : out t_wrf_sink_out;
      ext_snk_i               : in  t_wrf_sink_in   := c_dummy_snk_in;
      -- etherbone_master_o      : out t_wishbone_master_out;
      -- etherbone_master_i      : in  t_wishbone_master_in := cc_dummy_master_in;
      -- etherbone_src_o         : out t_wrf_source_out;
      -- etherbone_src_i         : in  t_wrf_source_in := c_dummy_src_in;
      -- etherbone_snk_o         : out t_wrf_sink_out;
      -- etherbone_snk_i         : in  t_wrf_sink_in   := c_dummy_snk_in;
      -- aux_master_o            : out t_wishbone_master_out;
      -- aux_master_i            : in  t_wishbone_master_in := cc_dummy_master_in;
      timestamps_o            : out t_txtsu_timestamp;
      timestamps_ack_i        : in  std_logic := '1';
      fc_tx_pause_req_i       : in  std_logic                     := '0';
      fc_tx_pause_delay_i     : in  std_logic_vector(15 downto 0) := x"0000";
      fc_tx_pause_ready_o     : out std_logic;
      tm_link_up_o            : out std_logic;
      tm_dac_value_o          : out std_logic_vector(23 downto 0);
      tm_dac_wr_o             : out std_logic_vector(g_aux_clks-1 downto 0);
      tm_clk_aux_lock_en_i    : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
      tm_clk_aux_locked_o     : out std_logic_vector(g_aux_clks-1 downto 0);
      tm_time_valid_o         : out std_logic;
      tm_tai_o                : out std_logic_vector(39 downto 0);
      tm_cycles_o             : out std_logic_vector(27 downto 0);
      pps_p_o                 : out std_logic;
      pps_p1_o                : out std_logic;
      pps_led_o               : out std_logic;
      rst_aux_n_o             : out std_logic;
      aux_diag_i              : in  t_generic_word_array(g_diag_ro_size-1 downto 0) := (others =>(others=>'0'));
      aux_diag_o              : out t_generic_word_array(g_diag_rw_size-1 downto 0);
      link_ok_o               : out std_logic
      );
  end component;

  ------------------------------------------------------------------------------
  -- signals declaration
  ------------------------------------------------------------------------------  
  signal owr_en : std_logic_vector(1 downto 0);
  signal owr_i  : std_logic_vector(1 downto 0);
  signal pps_led : std_logic;
  signal led_red : std_logic;
  signal led_green : std_logic;

  -- PHY
  signal phy8_to_wrc   : t_phy_8bits_to_wrc;
  signal phy8_from_wrc : t_phy_8bits_from_wrc;
  signal phy1_8_to_wrc   : t_phy_8bits_to_wrc;
  signal phy1_8_from_wrc : t_phy_8bits_from_wrc;
  signal sfp_mod_def0_i   : std_logic:='0';  -- sfp detect
  signal sfp_mod_def1_i   : std_logic:='0';  -- scl
  signal sfp_mod_def1_o   : std_logic;  -- scl
  signal sfp_mod_def2_i   : std_logic:='0';  -- sda
  signal sfp_mod_def2_o   : std_logic;  -- sda
  signal wrc_slave_i : t_wishbone_slave_in;
  signal wrc_slave_o : t_wishbone_slave_out;

  -- signal etherbone_rst_n   : std_logic;
  -- signal etherbone_src_o : t_wrf_source_out;
  -- signal etherbone_src_i  : t_wrf_source_in;
  -- signal etherbone_snk_o : t_wrf_sink_out;
  -- signal etherbone_snk_i  : t_wrf_sink_in;
  -- signal etherbone_wb_o  : t_wishbone_master_out;
  -- signal etherbone_wb_i   : t_wishbone_master_in;
  -- signal etherbone_cfg_slave_i  : t_wishbone_slave_in;
  -- signal etherbone_cfg_slave_o : t_wishbone_slave_out:=cc_unused_master_in;

  -- signal multiboot_in  : t_wishbone_slave_in;
  -- signal multiboot_out : t_wishbone_slave_out;
  -- signal multiboot_wb_in   : t_wishbone_master_in;
  -- signal multiboot_wb_out  : t_wishbone_master_out;

  --signal ext_pll_reset : std_logic;
  --signal clk_ext, clk_ext_mul       : std_logic;
  --signal clk_ext_mul_locked         : std_logic;
  --signal clk_ext_stopped            : std_logic;
  --signal clk_ext_rst                : std_logic;
  --signal clk_ref_div2               : std_logic;

constant c_ext_sdb : t_sdb_device := (
    abi_class     => x"0000",              -- undocumented device
    abi_ver_major => x"01",
    abi_ver_minor => x"01",
    wbd_endian    => c_sdb_endian_big,
    wbd_width     => x"4",                 -- 8/16/32-bit port granularity
    sdb_component => (
    addr_first  => x"0000000000000000",
    addr_last   => x"00000000000000ff",
    product     => (
    vendor_id => x"0000000000001103",  -- thu
    device_id => x"c0413599",
    version   => x"00000001",
    date      => x"20160424",
    name      => "WR-Ext-Config      ")));

-- constant c_wrc_multiboot_sdb : t_sdb_device := (
--     abi_class     => x"0000",              -- undocumented device
--     abi_ver_major => x"01",
--     abi_ver_minor => x"01",
--     wbd_endian    => c_sdb_endian_big,
--     wbd_width     => x"7",                 -- 8/16/32-bit port granularity
--     sdb_component => (
--     addr_first  => x"0000000000000000",
--     addr_last   => x"00000000000000ff",
--     product     => (
--     vendor_id => x"000000000000CE42",  -- CERN
--     device_id => x"deadbeaf",
--     version   => x"00000001",
--     date      => x"20141115",
--    name      => "SPI-flash+Multiboot")));

begin

  --u_ext_pll : ext_pll_10_to_125m
  --  port map (
  --    clk_ext_i        => clk_ext,
  --    clk_ext_mul_o    => clk_ext_mul,
  --    rst_a_i          => ext_pll_reset,
  --    clk_in_stopped_o => clk_ext_stopped,
  --    locked_o         => clk_ext_mul_locked);

  --u_extend_ext_reset : gc_extend_pulse
  --  generic map (
  --    g_width => 1000)
  --  port map (
  --    clk_i      => clk_sys_i,
  --    rst_n_i    => rst_n_i,
  --    pulse_i    => clk_ext_rst,
  --    extended_o => ext_pll_reset);

  thermo_id_o <= owr_en(0);
  owr_i(0)    <= thermo_id_i;
  owr_i(1)    <= '0';
  
  sfp0_led_o <= led_red;
  sfp1_led_o <= led_green;

u_wr_core : xcute_core
generic map (
    g_simulation                => g_simulation,
    g_with_external_clock_input => true,
    g_phys_uart                 => true,
    g_virtual_uart              => true,
    g_aux_clks                  => 0,
    g_ep_rxbuf_size             => 1024,
    g_tx_runt_padding           => true,
    g_pcs_16bit                 => false,
    g_dpram_initf               => "../../../../wrpc_sw/wrc.bram",
    g_dpram_size                => 131072/4,
    g_ext_sdb                   => c_ext_sdb,
    g_interface_mode            => pipelined,
    g_address_granularity       => byte,
    g_softpll_enable_debugger   => FALSE,
    g_vuart_fifo_size           => 1024,
    g_records_for_phy           => true,
    g_diag_id                   => 0,
    g_diag_ver                  => 0,
    g_diag_ro_size              => 0,
    g_diag_rw_size              => 0)
port map (
    clk_sys_i                   => clk_sys_i,
    clk_dmtd_i                  => clk_dmtd_i,
    clk_ref_i                   => clk_ref_i,
    clk_aux_i                   => (others => '0'),
    clk_ext_i                   => '0',
    clk_ext_mul_i               => '0',
    clk_ext_mul_locked_i        => '1',
    clk_ext_stopped_i           => '0',
    clk_ext_rst_o               => open,
    pps_ext_i                   => '0',
    rst_n_i                     => rst_n_i,
    dac_hpll_load_p1_o          => dac_hpll_load_p1_o,
    dac_hpll_data_o             => dac_hpll_data_o,
    dac_dpll_load_p1_o          => dac_dpll_load_p1_o,
    dac_dpll_data_o             => dac_dpll_data_o,
    phy_ref_clk_i               => '0',
    phy_tx_data_o               => open,
    phy_tx_k_o                  => open,
    phy_tx_disparity_i          => '0',
    phy_tx_enc_err_i            => '0',
    phy_rx_data_i               => (others => '0'),
    phy_rx_rbclk_i              => '0',
    phy_rx_k_i                  => (others => '0'),
    phy_rx_enc_err_i            => '0',
    phy_rx_bitslide_i           => (others => '0'),
    phy_rst_o                   => open,
    phy_rdy_i                   => '1',
    phy_loopen_o                => open,
    phy_loopen_vec_o            => open,
    phy_tx_prbs_sel_o           => open,
    phy_sfp_tx_fault_i          => '0',
    phy_sfp_los_i               => '0',
    phy_sfp_tx_disable_o        => open,
    phy8_o                      => phy8_from_wrc,
    phy8_i                      => phy8_to_wrc,
    led_act_o                   => led_red,
    led_link_o                  => led_green,
    scl_o                       => fpga_scl_o,
    scl_i                       => fpga_scl_i,
    sda_o                       => fpga_sda_o,
    sda_i                       => fpga_sda_i,
    btn1_i                      => open,
    btn2_i                      => open,
    spi_sclk_o                  => open,
    spi_ncs_o                   => open,
    spi_mosi_o                  => open,
    spi_miso_i                  => '0',
    sfp_scl_o                   => sfp_mod_def1_o,
    sfp_scl_i                   => sfp_mod_def1_i,
    sfp_sda_o                   => sfp_mod_def2_o,
    sfp_sda_i                   => sfp_mod_def2_i,
    sfp_det_i                   => sfp_mod_def0_i,
    uart_rxd_i                  => uart_rxd_i,
    uart_txd_o                  => uart_txd_o,
    owr_en_o                    => owr_en,
    owr_i                       => owr_i,
    slave_i                     => wrc_slave_i,
    slave_o                     => wrc_slave_o,
    ext_master_o                => ext_master_o,
    ext_master_i                => ext_master_i,
    ext_src_o                   => ext_src_o,
    ext_src_i                   => ext_src_i,
    ext_snk_o                   => ext_snk_o,
    ext_snk_i                   => ext_snk_i,
    -- etherbone_master_o          => etherbone_cfg_slave_i,
    -- etherbone_master_i          => etherbone_cfg_slave_o,
    -- etherbone_src_o             => etherbone_snk_i,
    -- etherbone_src_i             => etherbone_snk_o,
    -- etherbone_snk_o             => etherbone_src_i,
    -- etherbone_snk_i             => etherbone_src_o,
    -- aux_master_o                => multiboot_in,
    -- aux_master_i                => multiboot_out,
    tm_dac_value_o              => open,
    tm_dac_wr_o                 => open,
    tm_clk_aux_lock_en_i        => (others => '0'),
    tm_clk_aux_locked_o         => open,
    tm_time_valid_o             => tm_time_valid_o,
    tm_tai_o                    => tm_tai_o,
    tm_cycles_o                 => tm_cycles_o,
    pps_p_o                     => pps_o,
    pps_p1_o                    => pps_p1_o,
    pps_led_o                   => pps_led,
    rst_aux_n_o                 => open
);

U_WRPC_SFP0: if (g_sfp0_enable = true) generate

  phy8_to_wrc.ref_clk        <= clk_ref_i;
  phy8_to_wrc.sfp_tx_fault   <= sfp0_tx_fault_i;
  phy8_to_wrc.sfp_los        <= sfp0_los_i;
  sfp0_tx_disable_o          <= phy8_from_wrc.sfp_tx_disable;
  sfp_mod_def0_i             <= sfp0_mod_def0_i;
  sfp_mod_def1_i             <= sfp0_mod_def1_i;
  sfp0_mod_def1_o            <= sfp_mod_def1_o;
  sfp_mod_def2_i             <= sfp0_mod_def2_i;
  sfp0_mod_def2_o            <= sfp_mod_def2_o;

u_gtp0 : wr_gtp_phy_spartan6
generic map (
    g_enable_ch0 => 0,
    g_enable_ch1 => 1,
    g_simulation => g_simulation)
port map (
    gtp_clk_i          => clk_gtp0_i,
    ch1_ref_clk_i      => clk_ref_i,
    ch1_tx_data_i      => phy8_from_wrc.tx_data,
    ch1_tx_k_i         => phy8_from_wrc.tx_k(0),
    ch1_tx_disparity_o => phy8_to_wrc.tx_disparity,
    ch1_tx_enc_err_o   => phy8_to_wrc.tx_enc_err,
    ch1_rx_rbclk_o     => phy8_to_wrc.rx_clk,
    ch1_rx_data_o      => phy8_to_wrc.rx_data,
    ch1_rx_k_o         => phy8_to_wrc.rx_k(0),
    ch1_rx_enc_err_o   => phy8_to_wrc.rx_enc_err,
    ch1_rx_bitslide_o  => phy8_to_wrc.rx_bitslide,
    ch1_rst_i          => phy8_from_wrc.rst,
    ch1_loopen_i       => phy8_from_wrc.loopen,
    ch1_loopen_vec_i   => phy8_from_wrc.loopen_vec,
    ch1_tx_prbs_sel_i  => phy8_from_wrc.tx_prbs_sel,
    ch1_rdy_o          => phy8_to_wrc.rdy,
    pad_txn1_o         => sfp0_txn_o,
    pad_txp1_o         => sfp0_txp_o,
    pad_rxn1_i         => sfp0_rxn_i,
    pad_rxp1_i         => sfp0_rxp_i,
    ch0_ref_clk_i      => clk_ref_i,
    ch0_tx_data_i      => x"00",
    ch0_tx_k_i         => '0',
    ch0_tx_disparity_o => open,
    ch0_tx_enc_err_o   => open,
    ch0_rx_data_o      => open,
    ch0_rx_rbclk_o     => open,
    ch0_rx_k_o         => open,
    ch0_rx_enc_err_o   => open,
    ch0_rx_bitslide_o  => open,
    ch0_rst_i          => '1',
    ch0_loopen_i       => '0',
    ch0_loopen_vec_i   => (others=>'0'),
    ch0_tx_prbs_sel_i  => (others=>'0'),
    ch0_rdy_o          => open,
    pad_txn0_o         => open,
    pad_txp0_o         => open,
    pad_rxn0_i         => '0',
    pad_rxp0_i         => '0'
);
end generate;

U_WRPC_SFP1: if (g_sfp1_enable = true) generate
  
  phy8_to_wrc.ref_clk        <= clk_ref_i;
  phy8_to_wrc.sfp_tx_fault   <= sfp1_tx_fault_i;
  phy8_to_wrc.sfp_los        <= sfp1_los_i;
  sfp0_tx_disable_o          <= phy8_from_wrc.sfp_tx_disable;

  sfp_mod_def0_i             <= sfp1_mod_def0_i;
  sfp_mod_def1_i             <= sfp1_mod_def1_i;
  sfp1_mod_def1_o            <= sfp_mod_def1_o;
  sfp_mod_def2_i             <= sfp1_mod_def2_i;
  sfp1_mod_def2_o            <= sfp_mod_def2_o;

  u_gtp1 : wr_gtp_phy_spartan6
  generic map (
      g_enable_ch0 => 0,
      g_enable_ch1 => 1,
      g_simulation => g_simulation)
  port map (
      gtp_clk_i          => clk_gtp1_i,
      ch1_ref_clk_i      => clk_ref_i,
      ch1_tx_data_i      => phy8_from_wrc.tx_data,
      ch1_tx_k_i         => phy8_from_wrc.tx_k(0),
      ch1_tx_disparity_o => phy8_to_wrc.tx_disparity,
      ch1_tx_enc_err_o   => phy8_to_wrc.tx_enc_err,
      ch1_rx_rbclk_o     => phy8_to_wrc.rx_clk,
      ch1_rx_data_o      => phy8_to_wrc.rx_data,
      ch1_rx_k_o         => phy8_to_wrc.rx_k(0),
      ch1_rx_enc_err_o   => phy8_to_wrc.rx_enc_err,
      ch1_rx_bitslide_o  => phy8_to_wrc.rx_bitslide,
      ch1_rst_i          => phy8_from_wrc.rst,
      ch1_loopen_i       => phy8_from_wrc.loopen,
      ch1_loopen_vec_i   => phy8_from_wrc.loopen_vec,
      ch1_tx_prbs_sel_i  => phy8_from_wrc.tx_prbs_sel,
      ch1_rdy_o          => phy8_to_wrc.rdy,
      pad_txn1_o         => sfp1_txn_o,
      pad_txp1_o         => sfp1_txp_o,
      pad_rxn1_i         => sfp1_rxn_i,
      pad_rxp1_i         => sfp1_rxp_i,
      ch0_ref_clk_i      => clk_ref_i,
      ch0_tx_data_i      => x"00",
      ch0_tx_k_i         => '0',
      ch0_tx_disparity_o => open,
      ch0_tx_enc_err_o   => open,
      ch0_rx_data_o      => open,
      ch0_rx_rbclk_o     => open,
      ch0_rx_k_o         => open,
      ch0_rx_enc_err_o   => open,
      ch0_rx_bitslide_o  => open,
      ch0_rst_i          => '1',
      ch0_loopen_i       => '0',
      ch0_loopen_vec_i   => (others=>'0'),
      ch0_tx_prbs_sel_i  => (others=>'0'),
      ch0_rdy_o          => open,
      pad_txn0_o         => open,
      pad_txp0_o         => open,
      pad_rxn0_i         => '0',
      pad_rxp0_i         => '0'
  );

end generate;

-- etherbone : eb_slave_core
-- generic map (
--     g_sdb_address => x"0000000000030000")
-- port map (
--     clk_i       => clk_sys_i,
--     nrst_i      => etherbone_rst_n,
--     src_o       => etherbone_src_o,
--     src_i       => etherbone_src_i,
--     snk_o       => etherbone_snk_o,
--     snk_i       => etherbone_snk_i,
--     cfg_slave_o => etherbone_cfg_slave_o,
--     cfg_slave_i => etherbone_cfg_slave_i,
--     master_o    => etherbone_wb_o,
--     master_i    => etherbone_wb_i
-- );

-- masterbar : xwb_crossbar
-- generic map (
--     g_num_masters => 1,
--     g_num_slaves  => 1,
--     g_registered  => false,
--     g_address     => (0 => x"00000000"),
--     g_mask        => (0 => x"00000000"))
-- port map (
--     clk_sys_i   => clk_sys_i,
--     rst_n_i     => rst_n_i,
--     slave_i(0)  => etherbone_wb_o,
--     slave_o(0)  => etherbone_wb_i,
--     master_i(0) => wrc_slave_o,
--     master_o(0) => wrc_slave_i
-- );

-- cmp_clock_crossing: xwb_clock_crossing
--   port map(
--     slave_clk_i     => clk_sys_i,
--     slave_rst_n_i   => rst_n_i,
--     slave_i         => multiboot_in,
--     slave_o         => multiboot_out,
--     master_clk_i    => clk_20m_i,
--     master_rst_n_i  => rst_n_i,
--     master_i        => multiboot_wb_in,
--     master_o        => multiboot_wb_out
-- );

-- cmp_multiboot : xwb_xil_multiboot
--   port map(
--     clk_i   => clk_20m_i,
--     rst_n_i => rst_n_i,
--     wbs_i   => multiboot_wb_out,
--     wbs_o   => multiboot_wb_in,
--     spi_cs_n_o => fpga_prom_cso_b_n_o,
--     spi_sclk_o => fpga_prom_cclk_o,
--     spi_mosi_o => fpga_prom_mosi_o,
--     spi_miso_i => fpga_prom_miso_i
-- );

end rtl;
