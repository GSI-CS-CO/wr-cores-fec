onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/clk_sys_i
add wave -noupdate -expand /main/WRF_LBK/X_LOOPBACK/wrf_snk_i
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/wrf_snk_o
add wave -noupdate -expand /main/WRF_LBK/X_LOOPBACK/wrf_src_o
add wave -noupdate -expand /main/WRF_LBK/X_LOOPBACK/wrf_src_i
add wave -noupdate -expand /main/WRF_LBK/X_LOOPBACK/src_fab
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/wb_i
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/wb_o
add wave -noupdate -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_rxfsm
add wave -noupdate -height 16 /main/WRF_LBK/X_LOOPBACK/lbk_txfsm
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/fword_valid
add wave -noupdate -radix unsigned /main/WRF_LBK/X_LOOPBACK/fsize
add wave -noupdate -radix unsigned /main/WRF_LBK/X_LOOPBACK/txsize
add wave -noupdate -radix unsigned /main/WRF_LBK/X_LOOPBACK/tx_cnt
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/ffifo_full
add wave -noupdate -expand -group FFIFO -radix unsigned /main/WRF_LBK/X_LOOPBACK/FRAME_FIFO/count_o
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/frame_wr
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/frame_in
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/wrf_src_i.stall
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/FRAME_FIFO/empty_o
add wave -noupdate -expand -group FFIFO -color Red /main/WRF_LBK/X_LOOPBACK/src_dreq
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/src_fab.dvalid
add wave -noupdate -expand -group FFIFO -color Blue /main/WRF_LBK/X_LOOPBACK/frame_rd
add wave -noupdate -expand -group FFIFO /main/WRF_LBK/X_LOOPBACK/frame_out
add wave -noupdate -expand -group SFIFO /main/WRF_LBK/X_LOOPBACK/sfifo_empty
add wave -noupdate -expand -group SFIFO /main/WRF_LBK/X_LOOPBACK/sfifo_full
add wave -noupdate -expand -group SFIFO -radix unsigned /main/WRF_LBK/X_LOOPBACK/SIZE_FIFO/count_o
add wave -noupdate -expand -group SFIFO /main/WRF_LBK/X_LOOPBACK/fsize_wr
add wave -noupdate -expand -group SFIFO -radix unsigned /main/WRF_LBK/X_LOOPBACK/fsize_in
add wave -noupdate -expand -group SFIFO /main/WRF_LBK/X_LOOPBACK/fsize_rd
add wave -noupdate -expand -group SFIFO -radix unsigned /main/WRF_LBK/X_LOOPBACK/fsize_out
add wave -noupdate -expand -group CNTRS -radix unsigned /main/WRF_LBK/X_LOOPBACK/rcv_cnt
add wave -noupdate -expand -group CNTRS -radix unsigned /main/WRF_LBK/X_LOOPBACK/drp_cnt
add wave -noupdate -expand -group CNTRS -radix unsigned /main/WRF_LBK/X_LOOPBACK/fwd_cnt
add wave -noupdate /main/WRF_LBK/X_LOOPBACK/regs_fromwb
add wave -noupdate -expand -group WB_MASTER -expand /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/snk_fab_i
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/snk_dreq_o
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/src_wb_i
add wave -noupdate -expand -group WB_MASTER -expand /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/src_wb_o
add wave -noupdate -expand -group WB_MASTER -height 16 /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/state
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/ack_count
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/src_out_int
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/tmp_sel
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/tmp_dat
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/tmp_adr
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/enter_idle
add wave -noupdate -expand -group WB_MASTER /main/WRF_LBK/X_LOOPBACK/WRF_SRC_MOD/sof_reg
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 4} {2289625861100 fs} 0}
configure wave -namecolwidth 203
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 16000
configure wave -griddelta 60
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {2289204406500 fs} {2290083547460 fs}
