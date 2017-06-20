---------------------------------------------------------------------------------------
-- Title          : Wishbone slave core for WR Core Diagnostics
---------------------------------------------------------------------------------------
-- File           : wrc_diags_pkg.vhd
-- Author         : auto-generated by wbgen2 from wrc_diags_wb.wb
-- Created        : Tue Jun 20 09:59:03 2017
-- Version        : 0x00000001
-- Standard       : VHDL'87
---------------------------------------------------------------------------------------
-- THIS FILE WAS GENERATED BY wbgen2 FROM SOURCE FILE wrc_diags_wb.wb
-- DO NOT HAND-EDIT UNLESS IT'S ABSOLUTELY NECESSARY!
---------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package wrc_diags_wbgen2_pkg is
  
  
  -- Input registers (user design -> WB slave)
  
  type t_wrc_diags_in_registers is record
    ctrl_data_valid_i                        : std_logic;
    wdiag_sstat_wr_mode_i                    : std_logic;
    wdiag_sstat_servostate_i                 : std_logic_vector(3 downto 0);
    wdiag_pstat_link_i                       : std_logic;
    wdiag_pstat_locked_i                     : std_logic;
    wdiag_ptpstat_ptpstate_i                 : std_logic_vector(7 downto 0);
    wdiag_astat_aux_i                        : std_logic_vector(7 downto 0);
    wdiag_txfcnt_i                           : std_logic_vector(31 downto 0);
    wdiag_rxfcnt_i                           : std_logic_vector(31 downto 0);
    wdiag_sec_msb_i                          : std_logic_vector(31 downto 0);
    wdiag_sec_lsb_i                          : std_logic_vector(31 downto 0);
    wdiag_ns_i                               : std_logic_vector(31 downto 0);
    wdiag_mu_msb_i                           : std_logic_vector(31 downto 0);
    wdiag_mu_lsb_i                           : std_logic_vector(31 downto 0);
    wdiag_dms_msb_i                          : std_logic_vector(31 downto 0);
    wdiag_dms_lsb_i                          : std_logic_vector(31 downto 0);
    wdiag_asym_i                             : std_logic_vector(31 downto 0);
    wdiag_cko_i                              : std_logic_vector(31 downto 0);
    wdiag_setp_i                             : std_logic_vector(31 downto 0);
    wdiag_ucnt_i                             : std_logic_vector(31 downto 0);
    wdiag_temp_i                             : std_logic_vector(31 downto 0);
    end record;
  
  constant c_wrc_diags_in_registers_init_value: t_wrc_diags_in_registers := (
    ctrl_data_valid_i => '0',
    wdiag_sstat_wr_mode_i => '0',
    wdiag_sstat_servostate_i => (others => '0'),
    wdiag_pstat_link_i => '0',
    wdiag_pstat_locked_i => '0',
    wdiag_ptpstat_ptpstate_i => (others => '0'),
    wdiag_astat_aux_i => (others => '0'),
    wdiag_txfcnt_i => (others => '0'),
    wdiag_rxfcnt_i => (others => '0'),
    wdiag_sec_msb_i => (others => '0'),
    wdiag_sec_lsb_i => (others => '0'),
    wdiag_ns_i => (others => '0'),
    wdiag_mu_msb_i => (others => '0'),
    wdiag_mu_lsb_i => (others => '0'),
    wdiag_dms_msb_i => (others => '0'),
    wdiag_dms_lsb_i => (others => '0'),
    wdiag_asym_i => (others => '0'),
    wdiag_cko_i => (others => '0'),
    wdiag_setp_i => (others => '0'),
    wdiag_ucnt_i => (others => '0'),
    wdiag_temp_i => (others => '0')
    );
    
    -- Output registers (WB slave -> user design)
    
    type t_wrc_diags_out_registers is record
      ver_id_o                                 : std_logic_vector(31 downto 0);
      ctrl_data_snapshot_o                     : std_logic;
      end record;
    
    constant c_wrc_diags_out_registers_init_value: t_wrc_diags_out_registers := (
      ver_id_o => (others => '0'),
      ctrl_data_snapshot_o => '0'
      );
    function "or" (left, right: t_wrc_diags_in_registers) return t_wrc_diags_in_registers;
    function f_x_to_zero (x:std_logic) return std_logic;
    function f_x_to_zero (x:std_logic_vector) return std_logic_vector;
end package;

package body wrc_diags_wbgen2_pkg is
function f_x_to_zero (x:std_logic) return std_logic is
begin
if x = '1' then
return '1';
else
return '0';
end if;
end function;
function f_x_to_zero (x:std_logic_vector) return std_logic_vector is
variable tmp: std_logic_vector(x'length-1 downto 0);
begin
for i in 0 to x'length-1 loop
if(x(i) = 'X' or x(i) = 'U') then
tmp(i):= '0';
else
tmp(i):=x(i);
end if; 
end loop; 
return tmp;
end function;
function "or" (left, right: t_wrc_diags_in_registers) return t_wrc_diags_in_registers is
variable tmp: t_wrc_diags_in_registers;
begin
tmp.ctrl_data_valid_i := f_x_to_zero(left.ctrl_data_valid_i) or f_x_to_zero(right.ctrl_data_valid_i);
tmp.wdiag_sstat_wr_mode_i := f_x_to_zero(left.wdiag_sstat_wr_mode_i) or f_x_to_zero(right.wdiag_sstat_wr_mode_i);
tmp.wdiag_sstat_servostate_i := f_x_to_zero(left.wdiag_sstat_servostate_i) or f_x_to_zero(right.wdiag_sstat_servostate_i);
tmp.wdiag_pstat_link_i := f_x_to_zero(left.wdiag_pstat_link_i) or f_x_to_zero(right.wdiag_pstat_link_i);
tmp.wdiag_pstat_locked_i := f_x_to_zero(left.wdiag_pstat_locked_i) or f_x_to_zero(right.wdiag_pstat_locked_i);
tmp.wdiag_ptpstat_ptpstate_i := f_x_to_zero(left.wdiag_ptpstat_ptpstate_i) or f_x_to_zero(right.wdiag_ptpstat_ptpstate_i);
tmp.wdiag_astat_aux_i := f_x_to_zero(left.wdiag_astat_aux_i) or f_x_to_zero(right.wdiag_astat_aux_i);
tmp.wdiag_txfcnt_i := f_x_to_zero(left.wdiag_txfcnt_i) or f_x_to_zero(right.wdiag_txfcnt_i);
tmp.wdiag_rxfcnt_i := f_x_to_zero(left.wdiag_rxfcnt_i) or f_x_to_zero(right.wdiag_rxfcnt_i);
tmp.wdiag_sec_msb_i := f_x_to_zero(left.wdiag_sec_msb_i) or f_x_to_zero(right.wdiag_sec_msb_i);
tmp.wdiag_sec_lsb_i := f_x_to_zero(left.wdiag_sec_lsb_i) or f_x_to_zero(right.wdiag_sec_lsb_i);
tmp.wdiag_ns_i := f_x_to_zero(left.wdiag_ns_i) or f_x_to_zero(right.wdiag_ns_i);
tmp.wdiag_mu_msb_i := f_x_to_zero(left.wdiag_mu_msb_i) or f_x_to_zero(right.wdiag_mu_msb_i);
tmp.wdiag_mu_lsb_i := f_x_to_zero(left.wdiag_mu_lsb_i) or f_x_to_zero(right.wdiag_mu_lsb_i);
tmp.wdiag_dms_msb_i := f_x_to_zero(left.wdiag_dms_msb_i) or f_x_to_zero(right.wdiag_dms_msb_i);
tmp.wdiag_dms_lsb_i := f_x_to_zero(left.wdiag_dms_lsb_i) or f_x_to_zero(right.wdiag_dms_lsb_i);
tmp.wdiag_asym_i := f_x_to_zero(left.wdiag_asym_i) or f_x_to_zero(right.wdiag_asym_i);
tmp.wdiag_cko_i := f_x_to_zero(left.wdiag_cko_i) or f_x_to_zero(right.wdiag_cko_i);
tmp.wdiag_setp_i := f_x_to_zero(left.wdiag_setp_i) or f_x_to_zero(right.wdiag_setp_i);
tmp.wdiag_ucnt_i := f_x_to_zero(left.wdiag_ucnt_i) or f_x_to_zero(right.wdiag_ucnt_i);
tmp.wdiag_temp_i := f_x_to_zero(left.wdiag_temp_i) or f_x_to_zero(right.wdiag_temp_i);
return tmp;
end function;
end package body;
