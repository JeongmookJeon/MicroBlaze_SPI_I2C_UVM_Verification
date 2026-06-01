verdiSetActWin -dock widgetDock_<Watch>
simSetSimulator "-vcssv" -exec "simv" -args
debImport "-dbdir" "simv.daidir"
wvCreateWindow
wvOpenFile -win $_nWave2 {/home/hedu24/MOOK_WORK/0506_Micro_SPI/novas.fsdb}
verdiSetActWin -win $_nWave2
verdiWindowResize -win $_Verdi_1 "8" "31" "2560" "1369"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
debExit
