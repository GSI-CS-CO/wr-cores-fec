-------------------------------------------------------------------------------
-- Title      : WhiteRabbit PTP Core
-- Project    : WhiteRabbit
-------------------------------------------------------------------------------
-- File       : xcute_core.vhd
-- Author     : Grzegorz Daniluk
-- Company    : Elproma
-- Created    : 2011-02-02
-- Last update: 2014-07-15
-- Platform   : FPGA-generics
-- Standard   : VHDL
-------------------------------------------------------------------------------
-- Description:
-- WR PTP Core is a HDL module implementing a complete gigabit Ethernet 
-- interface (MAC + PCS + PHY) with integrated PTP slave ordinary clock 
-- compatible with White Rabbit protocol. It performs subnanosecond clock 
-- synchronization via WR protocol and also acts as an Ethernet "gateway", 
-- providing access to TX/RX interfaces of the built-in WR MAC.
--
-- Starting from version 2.0 all modules are interconnected with pipelined
-- wishbone interface (using wb crossbar and bus fanout). Separate pipelined
-- wishbone bus is used for passing packets between Endpoint, Mini-NIC
-- and External MAC interface.
-------------------------------------------------------------------------------
--
-- Copyright (c) 2011, 2012 Elproma Elektronika
-- Copyright (c) 2012, 2013 CERN
--
-- This source file is free software; you can redistribute it   
-- and/or modify it under the terms of the GNU Lesser General   
-- Public License as published by the Free Software Foundation; 
-- either version 2.1 of the License, or (at your option) any   
-- later version.                                               
--
-- This source is distributed in the hope that it will be       
-- useful, but WITHOUT ANY WARRANTY; without even the implied   
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      
-- PURPOSE.  See the GNU Lesser General Public License for more 
-- details.                                                     
--
-- You should have received a copy of the GNU Lesser General    
-- Public License along with this source; if not, download it   
-- from http://www.gnu.org/licenses/lgpl-2.1.html
--
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author          Description
-- 2011-02-02  1.0      greg.d          Created
-- 2011-10-25  2.0      greg.d          Redesigned and wishbonized
-- 2016-08-20  4.0      hongming        Add wb & wbf interface
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.wrcore_pkg.all;
use work.genram_pkg.all;
use work.wishbone_pkg.all;
use work.endpoint_pkg.all;
use work.wr_fabric_pkg.all;
use work.sysc_wbgen2_pkg.all;
use work.softpll_pkg.all;

entity xcute_core is
  generic(
    --if set to 1, then blocks in PCS use smaller calibration counter to speed 
    --up simulation
    g_simulation                : integer                        := 0;
    g_with_external_clock_input : boolean                        := true;
    --
    g_phys_uart                 : boolean                        := true;
    g_virtual_uart              : boolean                        := true;
    g_aux_clks                  : integer                        := 0;
    g_ep_rxbuf_size             : integer                        := 1024;
    g_tx_runt_padding           : boolean                        := true;
    g_dpram_initf               : string                         := "";
    g_dpram_size                : integer                        := 131072/4;  --in 32-bit words
    g_interface_mode            : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity       : t_wishbone_address_granularity := BYTE;
    g_etherbone_enable          : boolean                        := true;
    g_etherbone_sdb             : t_sdb_device                   := c_wrc_periph3_sdb;
    g_ext_sdb                   : t_sdb_device                   := c_wrc_periph3_sdb;
    g_multiboot_sdb             : t_sdb_device                   := c_wrc_periph3_sdb;
    g_softpll_enable_debugger   : boolean                        := false;
    g_vuart_fifo_size           : integer                        := 1024;
    g_pcs_16bit                 : boolean                        := false);
  port(
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- system reference clock (any frequency <= f(clk_ref_i))
    clk_sys_i : in std_logic;

    -- DDMTD offset clock (125.x MHz)
    clk_dmtd_i : in std_logic;

    -- Timing reference (125 MHz)
    clk_ref_i : in std_logic;

    -- Aux clock (i.e. the FMC clock), which can be disciplined by the WR Core
    clk_aux_i : in std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');

    -- External 10 MHz reference (cesium, GPSDO, etc.), used in Grandmaster mode
    clk_ext_i : in std_logic := '0';

    clk_ext_mul_i : in std_logic := '0';
    clk_ext_mul_locked_i : in std_logic := '1';
    clk_ext_stopped_i    : in  std_logic := '0';
    clk_ext_rst_o        : out std_logic;

    -- External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    pps_ext_i : in std_logic := '0';

    rst_n_i : in std_logic;

    -----------------------------------------
    --Timing system
    -----------------------------------------
    dac_hpll_load_p1_o : out std_logic;
    dac_hpll_data_o    : out std_logic_vector(15 downto 0);

    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(15 downto 0);

    -- PHY I/f
    phy_ref_clk_i : in std_logic;

    phy_tx_data_o        : out std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_tx_k_o           : out std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_tx_disparity_i   : in  std_logic;
    phy_tx_enc_err_i     : in  std_logic;

    phy_rx_data_i        : in std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_rx_rbclk_i       : in std_logic;
    phy_rx_k_i           : in std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_rx_enc_err_i     : in std_logic;
    phy_rx_bitslide_i    : in std_logic_vector(f_pcs_bts_width(g_pcs_16bit)-1 downto 0);

    phy_rst_o            : out std_logic;
    phy_rdy_i            : in  std_logic := '1';
    phy_loopen_o         : out std_logic;
    phy_loopen_vec_o     : out std_logic_vector(2 downto 0);
    phy_tx_prbs_sel_o    : out std_logic_vector(2 downto 0);
    phy_sfp_tx_fault_i   : in std_logic := '0';
    phy_sfp_los_i        : in std_logic := '0';
    phy_sfp_tx_disable_o : out std_logic;
   
    -----------------------------------------
    --GPIO
    -----------------------------------------
    led_act_o  : out std_logic;
    led_link_o : out std_logic;
    scl_o      : out std_logic;
    scl_i      : in  std_logic := '1';
    sda_o      : out std_logic;
    sda_i      : in  std_logic := '1';
    sfp_scl_o  : out std_logic;
    sfp_scl_i  : in  std_logic := '1';
    sfp_sda_o  : out std_logic;
    sfp_sda_i  : in  std_logic := '1';
    sfp_det_i  : in  std_logic;
    btn1_i     : in  std_logic := '1';
    btn2_i     : in  std_logic := '1';
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := '0';

    -----------------------------------------
    --UART
    -----------------------------------------
    uart_rxd_i : in  std_logic := '0';
    uart_txd_o : out std_logic;

    -----------------------------------------
    -- 1-wire
    -----------------------------------------
    owr_pwren_o : out std_logic_vector(1 downto 0);
    owr_en_o    : out std_logic_vector(1 downto 0);
    owr_i       : in  std_logic_vector(1 downto 0) := (others => '1');

    -----------------------------------------
    -- WB Slave interface
    -----------------------------------------
    slave_i : in  t_wishbone_slave_in := cc_dummy_slave_in;
    slave_o : out t_wishbone_slave_out;

    -----------------------------------------
    --Etherbone WB interface
    -----------------------------------------
    etherbone_master_o : out t_wishbone_master_out;
    etherbone_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

    -----------------------------------------
    -- Etherbone Fabric I/F
    -----------------------------------------
    etherbone_src_o : out t_wrf_source_out;
    etherbone_src_i : in  t_wrf_source_in := c_dummy_src_in;
    etherbone_snk_o : out t_wrf_sink_out;
    etherbone_snk_i : in  t_wrf_sink_in   := c_dummy_snk_in;

    -----------------------------------------
    --Ext WB interface
    -----------------------------------------
    ext_master_o : out t_wishbone_master_out;
    ext_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

    -----------------------------------------
    -- External Fabric I/F
    -----------------------------------------
    ext_src_o : out t_wrf_source_out;
    ext_src_i : in  t_wrf_source_in := c_dummy_src_in;
    ext_snk_o : out t_wrf_sink_out;
    ext_snk_i : in  t_wrf_sink_in   := c_dummy_snk_in;

    -----------------------------------------
    --Multiboot Module
    -----------------------------------------
    multiboot_master_o : out t_wishbone_master_out;
    multiboot_master_i : in  t_wishbone_master_in := cc_dummy_master_in;

    -----------------------------------------
    -- External Tx Timestamping I/F
    -----------------------------------------
    timestamps_o     : out t_txtsu_timestamp;
    timestamps_ack_i : in  std_logic := '1';

    -----------------------------------------
    -- Pause Frame Control
    -----------------------------------------
    fc_tx_pause_req_i   : in  std_logic                     := '0';
    fc_tx_pause_delay_i : in  std_logic_vector(15 downto 0) := x"0000";
    fc_tx_pause_ready_o : out std_logic;

    -----------------------------------------
    -- Timecode/Servo Control
    -----------------------------------------

    tm_link_up_o         : out std_logic;
    -- DAC Control
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Aux clock lock enable
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    -- Aux clock locked flag
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Timecode output
    tm_time_valid_o      : out std_logic;
    tm_tai_o             : out std_logic_vector(39 downto 0);
    tm_cycles_o          : out std_logic_vector(27 downto 0);
    -- 1PPS output
    pps_p_o              : out std_logic;
    pps_led_o            : out std_logic;

    dio_o       : out std_logic_vector(3 downto 0);
    rst_aux_n_o : out std_logic;

    link_ok_o : out std_logic
    );
end xcute_core;

architecture struct of xcute_core is

component cute_core is
  generic(
    --if set to 1, then blocks in PCS use smaller calibration counter to speed 
    --up simulation
    g_simulation                : integer                        := 0;
    g_with_external_clock_input : boolean                        := true;
    --
    g_phys_uart                 : boolean                        := true;
    g_virtual_uart              : boolean                        := true;
    g_aux_clks                  : integer                        := 0;
    g_rx_buffer_size            : integer                        := 1024;
    g_tx_runt_padding           : boolean                        := true;
    g_dpram_initf               : string                         := "default";
    g_dpram_size                : integer                        := 131072/4;  --in 32-bit words
    g_interface_mode            : t_wishbone_interface_mode      := PIPELINED;
    g_address_granularity       : t_wishbone_address_granularity := BYTE;
    g_etherbone_enable          : boolean                        := true;
    g_etherbone_sdb             : t_sdb_device                   := c_wrc_periph3_sdb;
    g_ext_sdb                   : t_sdb_device                   := c_wrc_periph3_sdb;
    g_multiboot_sdb             : t_sdb_device                   := c_wrc_periph3_sdb;
    g_softpll_channels_config   : t_softpll_channel_config_array := c_softpll_default_channel_config;
    g_softpll_enable_debugger   : boolean                        := false;
    g_vuart_fifo_size           : integer                        := 1024;
    g_pcs_16bit                 : boolean                        := false);
  port(
    ---------------------------------------------------------------------------
    -- Clocks/resets
    ---------------------------------------------------------------------------

    -- system reference clock (any frequency <= f(clk_ref_i))
    clk_sys_i : in std_logic;

    -- DDMTD offset clock (125.x MHz)
    clk_dmtd_i : in std_logic;

    -- Timing reference (125 MHz)
    clk_ref_i : in std_logic;

    -- Aux clocks (i.e. the FMC clock), which can be disciplined by the WR Core
    clk_aux_i : in std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');

    clk_ext_mul_i : in std_logic := '0';
    clk_ext_mul_locked_i  : in  std_logic := '1';
    clk_ext_stopped_i     : in  std_logic := '0';
    clk_ext_rst_o         : out std_logic;

    -- External 10 MHz reference (cesium, GPSDO, etc.), used in Grandmaster mode
    clk_ext_i : in std_logic := '0';

    -- External PPS input (cesium, GPSDO, etc.), used in Grandmaster mode
    pps_ext_i : in std_logic := '0';

    rst_n_i : in std_logic;

    -----------------------------------------
    --Timing system
    -----------------------------------------
    dac_hpll_load_p1_o : out std_logic;
    dac_hpll_data_o    : out std_logic_vector(15 downto 0);

    dac_dpll_load_p1_o : out std_logic;
    dac_dpll_data_o    : out std_logic_vector(15 downto 0);

    -- PHY I/f
    phy_ref_clk_i : in std_logic;

    phy_tx_data_o      : out std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_tx_k_o         : out std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_tx_disparity_i : in  std_logic;
    phy_tx_enc_err_i   : in  std_logic;

    phy_rx_data_i     : in std_logic_vector(f_pcs_data_width(g_pcs_16bit)-1 downto 0);
    phy_rx_rbclk_i    : in std_logic;
    phy_rx_k_i        : in std_logic_vector(f_pcs_k_width(g_pcs_16bit)-1 downto 0);
    phy_rx_k16_i      : in std_logic := '0';
    phy_rx_enc_err_i  : in std_logic;
    phy_rx_bitslide_i : in std_logic_vector(f_pcs_bts_width(g_pcs_16bit)-1 downto 0);

    phy_rst_o            : out std_logic;
    phy_rdy_i            : in  std_logic := '1';
    phy_loopen_o         : out std_logic;
    phy_loopen_vec_o     : out std_logic_vector(2 downto 0);
    phy_tx_prbs_sel_o    : out std_logic_vector(2 downto 0);
    phy_sfp_tx_fault_i   : in std_logic := '0';
    phy_sfp_los_i        : in std_logic := '0';
    phy_sfp_tx_disable_o : out std_logic;

    -----------------------------------------
    --GPIO
    -----------------------------------------
    led_act_o  : out std_logic;
    led_link_o : out std_logic;
    scl_o      : out std_logic;
    scl_i      : in  std_logic := '1';
    sda_o      : out std_logic;
    sda_i      : in  std_logic := '1';
    sfp_scl_o  : out std_logic;
    sfp_scl_i  : in  std_logic := '1';
    sfp_sda_o  : out std_logic;
    sfp_sda_i  : in  std_logic := '1';
    sfp_det_i  : in  std_logic := '1';
    btn1_i     : in  std_logic := '1';
    btn2_i     : in  std_logic := '1';
    spi_sclk_o : out std_logic;
    spi_ncs_o  : out std_logic;
    spi_mosi_o : out std_logic;
    spi_miso_i : in  std_logic := '0';

    -----------------------------------------
    --UART
    -----------------------------------------
    uart_rxd_i : in  std_logic := '1';
    uart_txd_o : out std_logic;

    -----------------------------------------
    -- 1-wire
    -----------------------------------------
    owr_pwren_o : out std_logic_vector(1 downto 0);
    owr_en_o    : out std_logic_vector(1 downto 0);
    owr_i       : in  std_logic_vector(1 downto 0) := (others => '1');

    -----------------------------------------
    --External WB interface
    -----------------------------------------
    wb_adr_i   : in  std_logic_vector(c_wishbone_address_width-1 downto 0)   := (others => '0');
    wb_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0)      := (others => '0');
    wb_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    wb_sel_i   : in  std_logic_vector(c_wishbone_address_width/8-1 downto 0) := (others => '0');
    wb_we_i    : in  std_logic                                               := '0';
    wb_cyc_i   : in  std_logic                                               := '0';
    wb_stb_i   : in  std_logic                                               := '0';
    wb_ack_o   : out std_logic;
    wb_err_o   : out std_logic;
    wb_rty_o   : out std_logic;
    wb_stall_o : out std_logic;

    -----------------------------------------
    -- Etherbone WB master
    -----------------------------------------
    etherbone_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    etherbone_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    etherbone_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    etherbone_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    etherbone_we_o    : out std_logic;
    etherbone_cyc_o   : out std_logic;
    etherbone_stb_o   : out std_logic;
    etherbone_ack_i   : in  std_logic := '1';
    etherbone_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- Etherbone Fabric I/F
    -----------------------------------------
    etherbone_snk_adr_i   : in  std_logic_vector(1 downto 0)  := "00";
    etherbone_snk_dat_i   : in  std_logic_vector(15 downto 0) := x"0000";
    etherbone_snk_sel_i   : in  std_logic_vector(1 downto 0)  := "00";
    etherbone_snk_cyc_i   : in  std_logic                     := '0';
    etherbone_snk_we_i    : in  std_logic                     := '0';
    etherbone_snk_stb_i   : in  std_logic                     := '0';
    etherbone_snk_ack_o   : out std_logic;
    etherbone_snk_err_o   : out std_logic;
    etherbone_snk_stall_o : out std_logic;

    etherbone_src_adr_o   : out std_logic_vector(1 downto 0);
    etherbone_src_dat_o   : out std_logic_vector(15 downto 0);
    etherbone_src_sel_o   : out std_logic_vector(1 downto 0);
    etherbone_src_cyc_o   : out std_logic;
    etherbone_src_stb_o   : out std_logic;
    etherbone_src_we_o    : out std_logic;
    etherbone_src_ack_i   : in  std_logic := '1';
    etherbone_src_err_i   : in  std_logic := '0';
    etherbone_src_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- External WB master
    -----------------------------------------
    ext_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    ext_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    ext_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    ext_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    ext_we_o    : out std_logic;
    ext_cyc_o   : out std_logic;
    ext_stb_o   : out std_logic;
    ext_ack_i   : in  std_logic := '1';
    ext_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- External Fabric I/F
    -----------------------------------------
    ext_snk_adr_i   : in  std_logic_vector(1 downto 0)  := "00";
    ext_snk_dat_i   : in  std_logic_vector(15 downto 0) := x"0000";
    ext_snk_sel_i   : in  std_logic_vector(1 downto 0)  := "00";
    ext_snk_cyc_i   : in  std_logic                     := '0';
    ext_snk_we_i    : in  std_logic                     := '0';
    ext_snk_stb_i   : in  std_logic                     := '0';
    ext_snk_ack_o   : out std_logic;
    ext_snk_err_o   : out std_logic;
    ext_snk_stall_o : out std_logic;

    ext_src_adr_o   : out std_logic_vector(1 downto 0);
    ext_src_dat_o   : out std_logic_vector(15 downto 0);
    ext_src_sel_o   : out std_logic_vector(1 downto 0);
    ext_src_cyc_o   : out std_logic;
    ext_src_stb_o   : out std_logic;
    ext_src_we_o    : out std_logic;
    ext_src_ack_i   : in  std_logic := '1';
    ext_src_err_i   : in  std_logic := '0';
    ext_src_stall_i : in  std_logic := '0';

    -----------------------------------------
    -- Multiboot WB master
    -----------------------------------------
    multiboot_adr_o   : out std_logic_vector(c_wishbone_address_width-1 downto 0);
    multiboot_dat_o   : out std_logic_vector(c_wishbone_data_width-1 downto 0);
    multiboot_dat_i   : in  std_logic_vector(c_wishbone_data_width-1 downto 0);
    multiboot_sel_o   : out std_logic_vector(c_wishbone_address_width/8-1 downto 0);
    multiboot_we_o    : out std_logic;
    multiboot_cyc_o   : out std_logic;
    multiboot_stb_o   : out std_logic;
    multiboot_ack_i   : in  std_logic := '1';
    multiboot_stall_i : in  std_logic := '0';

    ------------------------------------------
    -- External TX Timestamp I/F
    ------------------------------------------
    txtsu_port_id_o      : out std_logic_vector(4 downto 0);
    txtsu_frame_id_o     : out std_logic_vector(15 downto 0);
    txtsu_ts_value_o     : out std_logic_vector(31 downto 0);
    txtsu_ts_incorrect_o : out std_logic;
    txtsu_stb_o          : out std_logic;
    txtsu_ack_i          : in  std_logic := '1';

    -----------------------------------------
    -- Pause Frame Control
    -----------------------------------------
    fc_tx_pause_req_i   : in  std_logic                     := '0';
    fc_tx_pause_delay_i : in  std_logic_vector(15 downto 0) := x"0000";
    fc_tx_pause_ready_o : out std_logic;

    -----------------------------------------
    -- Timecode/Servo Control
    -----------------------------------------

    tm_link_up_o         : out std_logic;
    -- DAC Control
    tm_dac_value_o       : out std_logic_vector(23 downto 0);
    tm_dac_wr_o          : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Aux clock lock enable
    tm_clk_aux_lock_en_i : in  std_logic_vector(g_aux_clks-1 downto 0) := (others => '0');
    -- Aux clock locked flag
    tm_clk_aux_locked_o  : out std_logic_vector(g_aux_clks-1 downto 0);
    -- Timecode output
    tm_time_valid_o      : out std_logic;
    tm_tai_o             : out std_logic_vector(39 downto 0);
    tm_cycles_o          : out std_logic_vector(27 downto 0);
    -- 1PPS output
    pps_p_o              : out std_logic;
    pps_led_o            : out std_logic;

    dio_o       : out std_logic_vector(3 downto 0);
    rst_aux_n_o : out std_logic;

    link_ok_o : out std_logic
    );
end component;

begin

  WRPC : cute_core
    generic map(
      g_simulation                => g_simulation,
      g_phys_uart                 => g_phys_uart,
      g_virtual_uart              => g_virtual_uart,
      g_rx_buffer_size            => g_ep_rxbuf_size,
      g_tx_runt_padding           => g_tx_runt_padding,
      g_with_external_clock_input => g_with_external_clock_input,
      g_aux_clks                  => g_aux_clks,
      g_dpram_initf               => g_dpram_initf,
      g_dpram_size                => g_dpram_size,
      g_interface_mode            => g_interface_mode,
      g_address_granularity       => g_address_granularity,
      g_etherbone_enable          => g_etherbone_enable,
      g_etherbone_sdb             => g_etherbone_sdb,
      g_ext_sdb                   => g_ext_sdb,
      g_multiboot_sdb             => g_multiboot_sdb,
      g_softpll_enable_debugger   => g_softpll_enable_debugger,
      g_vuart_fifo_size           => g_vuart_fifo_size,
      g_pcs_16bit                 => g_pcs_16bit)
    port map(
      clk_sys_i     => clk_sys_i,
      clk_dmtd_i    => clk_dmtd_i,
      clk_ref_i     => clk_ref_i,
      clk_aux_i     => clk_aux_i,
      clk_ext_i     => clk_ext_i,
      clk_ext_mul_i => clk_ext_mul_i,
      clk_ext_mul_locked_i  => clk_ext_mul_locked_i,
      clk_ext_stopped_i => clk_ext_stopped_i,
      clk_ext_rst_o     => clk_ext_rst_o,
      pps_ext_i     => pps_ext_i,
      rst_n_i       => rst_n_i,

      dac_hpll_load_p1_o   => dac_hpll_load_p1_o,
      dac_hpll_data_o      => dac_hpll_data_o,
      dac_dpll_load_p1_o   => dac_dpll_load_p1_o,
      dac_dpll_data_o      => dac_dpll_data_o,

      phy_ref_clk_i        => phy_ref_clk_i,
      phy_tx_data_o        => phy_tx_data_o,
      phy_tx_k_o           => phy_tx_k_o,
      phy_tx_disparity_i   => phy_tx_disparity_i,
      phy_tx_enc_err_i     => phy_tx_enc_err_i,
      phy_rx_data_i        => phy_rx_data_i,
      phy_rx_rbclk_i       => phy_rx_rbclk_i,
      phy_rx_k_i           => phy_rx_k_i,
      phy_rx_enc_err_i     => phy_rx_enc_err_i,
      phy_rx_bitslide_i    => phy_rx_bitslide_i,
      phy_rst_o            => phy_rst_o,
      phy_rdy_i            => phy_rdy_i,
      phy_loopen_o         => phy_loopen_o,
      phy_loopen_vec_o     => phy_loopen_vec_o,
      phy_tx_prbs_sel_o    => phy_tx_prbs_sel_o,
      phy_sfp_tx_fault_i   => phy_sfp_tx_fault_i,
      phy_sfp_los_i        => phy_sfp_los_i,
      phy_sfp_tx_disable_o => phy_sfp_tx_disable_o,

      led_act_o  => led_act_o,
      led_link_o => led_link_o,
      scl_o      => scl_o,
      scl_i      => scl_i,
      sda_o      => sda_o,
      sda_i      => sda_i,
      sfp_scl_o  => sfp_scl_o,
      sfp_scl_i  => sfp_scl_i,
      sfp_sda_o  => sfp_sda_o,
      sfp_sda_i  => sfp_sda_i,
      sfp_det_i  => sfp_det_i,
      btn1_i     => btn1_i,
      btn2_i     => btn2_i,
      spi_sclk_o => spi_sclk_o,
      spi_ncs_o  => spi_ncs_o,
      spi_mosi_o => spi_mosi_o,
      spi_miso_i => spi_miso_i,
      uart_rxd_i => uart_rxd_i,
      uart_txd_o => uart_txd_o,

      owr_pwren_o => owr_pwren_o,
      owr_en_o    => owr_en_o,
      owr_i       => owr_i,

      wb_adr_i   => slave_i.adr,
      wb_dat_i   => slave_i.dat,
      wb_dat_o   => slave_o.dat,
      wb_sel_i   => slave_i.sel,
      wb_we_i    => slave_i.we,
      wb_cyc_i   => slave_i.cyc,
      wb_stb_i   => slave_i.stb,
      wb_ack_o   => slave_o.ack,
      wb_err_o   => slave_o.err,
      wb_rty_o   => slave_o.rty,
      wb_stall_o => slave_o.stall,

      etherbone_adr_o   => etherbone_master_o.adr,
      etherbone_dat_o   => etherbone_master_o.dat,
      etherbone_sel_o   => etherbone_master_o.sel,
      etherbone_cyc_o   => etherbone_master_o.cyc,
      etherbone_stb_o   => etherbone_master_o.stb,
      etherbone_we_o    => etherbone_master_o.we,
      etherbone_stall_i => etherbone_master_i.stall,
      etherbone_ack_i   => etherbone_master_i.ack,
      etherbone_dat_i   => etherbone_master_i.dat,

      etherbone_snk_adr_i   => etherbone_snk_i.adr,
      etherbone_snk_dat_i   => etherbone_snk_i.dat,
      etherbone_snk_sel_i   => etherbone_snk_i.sel,
      etherbone_snk_cyc_i   => etherbone_snk_i.cyc,
      etherbone_snk_we_i    => etherbone_snk_i.we,
      etherbone_snk_stb_i   => etherbone_snk_i.stb,
      etherbone_snk_ack_o   => etherbone_snk_o.ack,
      etherbone_snk_err_o   => etherbone_snk_o.err,
      etherbone_snk_stall_o => etherbone_snk_o.stall,

      etherbone_src_adr_o   => etherbone_src_o.adr,
      etherbone_src_dat_o   => etherbone_src_o.dat,
      etherbone_src_sel_o   => etherbone_src_o.sel,
      etherbone_src_cyc_o   => etherbone_src_o.cyc,
      etherbone_src_stb_o   => etherbone_src_o.stb,
      etherbone_src_we_o    => etherbone_src_o.we,
      etherbone_src_ack_i   => etherbone_src_i.ack,
      etherbone_src_err_i   => etherbone_src_i.err,
      etherbone_src_stall_i => etherbone_src_i.stall,

      ext_adr_o   => ext_master_o.adr,
      ext_dat_o   => ext_master_o.dat,
      ext_sel_o   => ext_master_o.sel,
      ext_cyc_o   => ext_master_o.cyc,
      ext_stb_o   => ext_master_o.stb,
      ext_we_o    => ext_master_o.we,
      ext_stall_i => ext_master_i.stall,
      ext_ack_i   => ext_master_i.ack,
      ext_dat_i   => ext_master_i.dat,

      ext_snk_adr_i   => ext_snk_i.adr,
      ext_snk_dat_i   => ext_snk_i.dat,
      ext_snk_sel_i   => ext_snk_i.sel,
      ext_snk_cyc_i   => ext_snk_i.cyc,
      ext_snk_we_i    => ext_snk_i.we,
      ext_snk_stb_i   => ext_snk_i.stb,
      ext_snk_ack_o   => ext_snk_o.ack,
      ext_snk_err_o   => ext_snk_o.err,
      ext_snk_stall_o => ext_snk_o.stall,

      ext_src_adr_o   => ext_src_o.adr,
      ext_src_dat_o   => ext_src_o.dat,
      ext_src_sel_o   => ext_src_o.sel,
      ext_src_cyc_o   => ext_src_o.cyc,
      ext_src_stb_o   => ext_src_o.stb,
      ext_src_we_o    => ext_src_o.we,
      ext_src_ack_i   => ext_src_i.ack,
      ext_src_err_i   => ext_src_i.err,
      ext_src_stall_i => ext_src_i.stall,

      multiboot_adr_o   => multiboot_master_o.adr,
      multiboot_dat_o   => multiboot_master_o.dat,
      multiboot_sel_o   => multiboot_master_o.sel,
      multiboot_cyc_o   => multiboot_master_o.cyc,
      multiboot_stb_o   => multiboot_master_o.stb,
      multiboot_we_o    => multiboot_master_o.we,
      multiboot_stall_i => multiboot_master_i.stall,
      multiboot_ack_i   => multiboot_master_i.ack,
      multiboot_dat_i   => multiboot_master_i.dat,

      txtsu_port_id_o      => timestamps_o.port_id(4 downto 0),
      txtsu_frame_id_o     => timestamps_o.frame_id,
      txtsu_ts_value_o     => timestamps_o.tsval,
      txtsu_ts_incorrect_o => timestamps_o.incorrect,
      txtsu_stb_o          => timestamps_o.stb,
      txtsu_ack_i          => timestamps_ack_i,

      fc_tx_pause_req_i    => fc_tx_pause_req_i,
      fc_tx_pause_delay_i  => fc_tx_pause_delay_i,
      fc_tx_pause_ready_o  => fc_tx_pause_ready_o,

      tm_link_up_o         => tm_link_up_o,
      tm_dac_value_o       => tm_dac_value_o,
      tm_dac_wr_o          => tm_dac_wr_o,
      tm_clk_aux_lock_en_i => tm_clk_aux_lock_en_i,
      tm_clk_aux_locked_o  => tm_clk_aux_locked_o,
      tm_time_valid_o      => tm_time_valid_o,
      tm_tai_o             => tm_tai_o,
      tm_cycles_o          => tm_cycles_o,
      pps_p_o              => pps_p_o,
      pps_led_o            => pps_led_o,

      dio_o       => dio_o,
      rst_aux_n_o => rst_aux_n_o,

      link_ok_o => link_ok_o
      );

  timestamps_o.port_id(5) <= '0';

  slave_o.int <= '0';

  ext_snk_o.rty <= '0';
  etherbone_snk_o.rty <= '0';

end struct;
