-------------------------------------------------------------------------------
-- Title      : SFP I2C adapter for VFC-HD board
-- Project    : WR PTP Core
-- URL        : http://www.ohwr.org/projects/wr-cores/wiki/Wrpc_core
-------------------------------------------------------------------------------
-- File       : sfp_i2c_adapter.vhd
-- Author(s)  : Dimitrios Lampridis  <dimitrios.lampridis@cern.ch>
-- Company    : CERN (BE-CO-HT)
-- Created    : 2016-11-25
-- Last update: 2016-11-28
-- Standard   : VHDL'93
-------------------------------------------------------------------------------
-- Description: Simple interface betweent the I2C master port of the WR PTP
-- core (used to retrieve the SFP configuration) and the parallel interface
-- provided by the VFC-HD board. Uses internally the I2C slave from
-- general-cores.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 CERN
-------------------------------------------------------------------------------
-- GNU LESSER GENERAL PUBLIC LICENSE
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.gencores_pkg.all;

entity sfp_i2c_adapter is
  port (

    -- Clock, reset ports
    clk_i   : in std_logic;
    rst_n_i : in std_logic;

    -- I2C lines
    scl_i    : in  std_logic;
    sda_i    : in  std_logic;
    sda_en_o : out std_logic;

    -- HIGH if both of the following are true:
    -- 1. SFP is detected (plugged in)
    -- 2. The part number has been successfully read after the SFP detection
    sfp_det_valid_i : in std_logic;
    -- 16 byte vendor Part Number (PN)
    -- (ASCII encoded, first character byte in bits 127 downto 120)
    sfp_data_i      : in std_logic_vector (127 downto 0)
    );
end entity sfp_i2c_adapter;

architecture rtl of sfp_i2c_adapter is

  -----------------------------------------------------------------------------
  -- Types
  -----------------------------------------------------------------------------

  -- 64-byte array representing the DDM serial ID area of the SFP management
  type t_sfp_ddm_serial_id is array (0 to 63) of std_logic_vector(7 downto 0);

  -----------------------------------------------------------------------------
  -- Signals
  -----------------------------------------------------------------------------

  signal sfp_i2c_tx_byte : std_logic_vector(7 downto 0);
  signal sfp_i2c_rx_byte : std_logic_vector(7 downto 0);
  signal sfp_i2c_r_done  : std_logic;
  signal sfp_i2c_w_done  : std_logic;
  signal sfp_ddm_din     : t_sfp_ddm_serial_id := (others => (others => '0'));
  signal sfp_ddm_reg     : t_sfp_ddm_serial_id := (others => (others => '0'));
  signal sfp_ddm_addr    : unsigned(5 downto 0);
  signal sfp_ddm_sum     : unsigned(7 downto 0);

begin  -- architecture rtl

  cmp_gc_i2c_slave : gc_i2c_slave
    generic map (
      g_auto_addr_ack => TRUE)
    port map (
      clk_i         => clk_i,
      rst_n_i       => rst_n_i,
      scl_i         => scl_i,
      -- clock streching not implemented by module
      scl_o         => open,
      scl_en_o      => open,
      sda_i         => sda_i,
      -- sda_o is not necessary, sda_en has all the info that we need
      sda_o         => open,
      sda_en_o      => sda_en_o,
      -- standard SFP management I2C address
      i2c_addr_i    => "1010000",
      -- no need to ACK, we use auto address ACK
      -- and only use one byte writes
      ack_i         => '0',
      tx_byte_i     => sfp_i2c_tx_byte,
      rx_byte_o     => sfp_i2c_rx_byte,
      -- we only care about r_done (new address)
      -- and w_done (load next byte from serial_id)
      i2c_sta_p_o   => open,
      i2c_sto_p_o   => open,
      addr_good_p_o => open,
      r_done_p_o    => sfp_i2c_r_done,
      w_done_p_o    => sfp_i2c_w_done,
      op_o          => open);

  -- Populate the sfp_ddm Vendor PN using the sfp_data_i input
  gen_sfp_ddm_data : for i in 0 to 15 generate
    sfp_ddm_din(40+i) <= sfp_data_i(127-i*8 downto 120-i*8);
  end generate gen_sfp_ddm_data;

  -- Calculate CC_BASE for the last byte of the sfp_ddm.
  -- We only sum the 16 bytes, all other bytes are zero anyway.
  sfp_ddm_sum <=
    (((unsigned(sfp_data_i(127 downto 120)) + unsigned(sfp_data_i(119 downto 112))) +
      (unsigned(sfp_data_i(111 downto 104)) + unsigned(sfp_data_i(103 downto 96)))) +
     ((unsigned(sfp_data_i(95 downto 88)) + unsigned(sfp_data_i(87 downto 80))) +
      (unsigned(sfp_data_i(79 downto 72)) + unsigned(sfp_data_i(71 downto 64))))) +
    (((unsigned(sfp_data_i(63 downto 56)) + unsigned(sfp_data_i(55 downto 48))) +
      (unsigned(sfp_data_i(47 downto 40)) + unsigned(sfp_data_i(39 downto 32)))) +
     ((unsigned(sfp_data_i(31 downto 24)) + unsigned(sfp_data_i(23 downto 16))) +
      (unsigned(sfp_data_i(15 downto 8)) + unsigned(sfp_data_i(7 downto 0)))));

  sfp_ddm_din(63) <= std_logic_vector(sfp_ddm_sum);

  -- always offer to send the next byte pointed to by the address counter
  sfp_i2c_tx_byte <= sfp_ddm_reg(to_integer(sfp_ddm_addr));

  -- Drive the SFP DDM based on the r_done/w_done pulses
  p_sfp_ddm_addr_counter : process (clk_i) is
  begin
    if rising_edge(clk_i) then
      if rst_n_i = '0' then
        sfp_ddm_addr <= (others => '0');
        sfp_ddm_reg  <= (others => (others => '0'));
      else
        -- check valid flag to load DDM register
        if sfp_det_valid_i = '1' then
          sfp_ddm_reg <= sfp_ddm_din;
        else
          sfp_ddm_reg <= (others => (others => '0'));
        end if;

        if sfp_i2c_r_done = '1' then
          -- update address pointer with new value
          sfp_ddm_addr <= unsigned(sfp_i2c_rx_byte(5 downto 0));
        elsif sfp_i2c_w_done = '1' then
          -- increase address pointer
          sfp_ddm_addr <= sfp_ddm_addr + 1;
        end if;
      end if;
    end if;
  end process p_sfp_ddm_addr_counter;


end architecture rtl;
