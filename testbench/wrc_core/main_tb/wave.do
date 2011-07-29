onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main_with_fec/DUT/fec/clk_i
add wave -noupdate /main_with_fec/DUT/fec/rst_n_i
add wave -noupdate /main_with_fec/DUT/fec/src_data_o
add wave -noupdate /main_with_fec/DUT/fec/src_ctrl_o
add wave -noupdate /main_with_fec/DUT/fec/src_bytesel_o
add wave -noupdate /main_with_fec/DUT/fec/src_dreq_i
add wave -noupdate /main_with_fec/DUT/fec/src_valid_o
add wave -noupdate /main_with_fec/DUT/fec/src_sof_p1_o
add wave -noupdate /main_with_fec/DUT/fec/src_eof_p1_o
add wave -noupdate /main_with_fec/DUT/fec/src_error_p1_i
add wave -noupdate /main_with_fec/DUT/fec/src_abort_p1_o
add wave -noupdate /main_with_fec/DUT/fec/wb_clk_i
add wave -noupdate /main_with_fec/DUT/fec/wb_addr_i
add wave -noupdate /main_with_fec/DUT/fec/wb_data_i
add wave -noupdate /main_with_fec/DUT/fec/wb_data_o
add wave -noupdate /main_with_fec/DUT/fec/wb_cyc_i
add wave -noupdate /main_with_fec/DUT/fec/wb_sel_i
add wave -noupdate /main_with_fec/DUT/fec/wb_stb_i
add wave -noupdate /main_with_fec/DUT/fec/wb_we_i
add wave -noupdate /main_with_fec/DUT/fec/wb_ack_o
add wave -noupdate /main_with_fec/DUT/fec/wbm_dat
add wave -noupdate /main_with_fec/DUT/fec/wbm_adr
add wave -noupdate /main_with_fec/DUT/fec/wbm_sel
add wave -noupdate /main_with_fec/DUT/fec/wbm_cyc
add wave -noupdate /main_with_fec/DUT/fec/wbm_stb
add wave -noupdate /main_with_fec/DUT/fec/wbm_we
add wave -noupdate /main_with_fec/DUT/fec/wbm_err
add wave -noupdate /main_with_fec/DUT/fec/wbm_stall
add wave -noupdate /main_with_fec/DUT/fec/wbm_ack
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_dat
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_adr
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_sel
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_cyc
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_stb
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_we
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_err
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_stall
add wave -noupdate /main_with_fec/DUT/fec/wbm2wrf_ack
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {90376 ns} 0}
configure wave -namecolwidth 226
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {87532 ns} {100657 ns}
