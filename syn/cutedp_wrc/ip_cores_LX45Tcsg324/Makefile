PROJECT := cutedp_wrc.xise

ISE_CRAP := *.b cutedp_wrc_summary.html *.tcl cutedp_wrc.bld cutedp_wrc.cmd_log *.drc cutedp_wrc.lso *.ncd cutedp_wrc.ngd cutedp_wrc.ngr cutedp_wrc.pad cutedp_wrc.par cutedp_wrc.pcf cutedp_wrc.prj cutedp_wrc.ptwx cutedp_wrc.stx cutedp_wrc.syr cutedp_wrc.twr cutedp_wrc.twx cutedp_wrc.gise $(PROJECT).gise cutedp_wrc.bgn cutedp_wrc.unroutes cutedp_wrc.ut cutedp_wrc.xpi cutedp_wrc.xst cutedp_wrc_bitgen.xwbt cutedp_wrc_envsettings.html cutedp_wrc_guide.ncd cutedp_wrc_map.map cutedp_wrc_map.mrp cutedp_wrc_map.ncd cutedp_wrc_map.ngm cutedp_wrc_map.xrpt cutedp_wrc_ngdbuild.xrpt cutedp_wrc_pad.csv cutedp_wrc_pad.txt cutedp_wrc_par.xrpt cutedp_wrc_summary.xml cutedp_wrc_usage.xml cutedp_wrc_xst.xrpt usage_statistics_webtalk.html par_usage_statistics.html webtalk.log webtalk_pn.xml run.tcl

#target for performing local synthesis
all: WRPC

WRPC : 
	echo "project open $(PROJECT)" > run.tcl
	echo "process run {Synthesize - XST}" >> run.tcl
	$(XILINX)/bin/lin64/xtclsh run.tcl

#target for cleaning all intermediate stuff
clean:
	rm -f $(ISE_CRAP)
	rm -rf xst xlnx_auto_*_xdb iseconfig _xmsgs _ngo

#target for cleaning final files
mrproper:
	rm -f *.bit *.bin *.mcs

.PHONY: mrproper clean wrpc all 

