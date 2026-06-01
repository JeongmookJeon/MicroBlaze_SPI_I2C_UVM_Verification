vlib work
vlib activehdl

vlib activehdl/xpm
vlib activehdl/microblaze_v11_0_4
vlib activehdl/xil_defaultlib
vlib activehdl/lmb_v10_v3_0_11
vlib activehdl/lmb_bram_if_cntlr_v4_0_19
vlib activehdl/blk_mem_gen_v8_4_4
vlib activehdl/generic_baseblocks_v2_1_0
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/axi_register_slice_v2_1_22
vlib activehdl/fifo_generator_v13_2_5
vlib activehdl/axi_data_fifo_v2_1_21
vlib activehdl/axi_crossbar_v2_1_23
vlib activehdl/axi_lite_ipif_v3_0_4
vlib activehdl/axi_intc_v4_1_15
vlib activehdl/xlconcat_v2_1_4
vlib activehdl/mdm_v3_2_19
vlib activehdl/lib_cdc_v1_0_2
vlib activehdl/proc_sys_reset_v5_0_13
vlib activehdl/lib_pkg_v1_0_2
vlib activehdl/lib_srl_fifo_v1_0_2
vlib activehdl/axi_uartlite_v2_0_26

vmap xpm activehdl/xpm
vmap microblaze_v11_0_4 activehdl/microblaze_v11_0_4
vmap xil_defaultlib activehdl/xil_defaultlib
vmap lmb_v10_v3_0_11 activehdl/lmb_v10_v3_0_11
vmap lmb_bram_if_cntlr_v4_0_19 activehdl/lmb_bram_if_cntlr_v4_0_19
vmap blk_mem_gen_v8_4_4 activehdl/blk_mem_gen_v8_4_4
vmap generic_baseblocks_v2_1_0 activehdl/generic_baseblocks_v2_1_0
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_22 activehdl/axi_register_slice_v2_1_22
vmap fifo_generator_v13_2_5 activehdl/fifo_generator_v13_2_5
vmap axi_data_fifo_v2_1_21 activehdl/axi_data_fifo_v2_1_21
vmap axi_crossbar_v2_1_23 activehdl/axi_crossbar_v2_1_23
vmap axi_lite_ipif_v3_0_4 activehdl/axi_lite_ipif_v3_0_4
vmap axi_intc_v4_1_15 activehdl/axi_intc_v4_1_15
vmap xlconcat_v2_1_4 activehdl/xlconcat_v2_1_4
vmap mdm_v3_2_19 activehdl/mdm_v3_2_19
vmap lib_cdc_v1_0_2 activehdl/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_13 activehdl/proc_sys_reset_v5_0_13
vmap lib_pkg_v1_0_2 activehdl/lib_pkg_v1_0_2
vmap lib_srl_fifo_v1_0_2 activehdl/lib_srl_fifo_v1_0_2
vmap axi_uartlite_v2_0_26 activehdl/axi_uartlite_v2_0_26

vlog -work xpm  -sv2k12 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93 \
"C:/Xilinx/Vivado/2020.2/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work microblaze_v11_0_4 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/9285/hdl/microblaze_v11_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_microblaze_0_0/sim/design_1_microblaze_0_0.vhd" \

vcom -work lmb_v10_v3_0_11 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/c2ed/hdl/lmb_v10_v3_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_dlmb_v10_0/sim/design_1_dlmb_v10_0.vhd" \
"../../../bd/design_1/ip/design_1_ilmb_v10_0/sim/design_1_ilmb_v10_0.vhd" \

vcom -work lmb_bram_if_cntlr_v4_0_19 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/0b98/hdl/lmb_bram_if_cntlr_v4_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_dlmb_bram_if_cntlr_0/sim/design_1_dlmb_bram_if_cntlr_0.vhd" \
"../../../bd/design_1/ip/design_1_ilmb_bram_if_cntlr_0/sim/design_1_ilmb_bram_if_cntlr_0.vhd" \

vlog -work blk_mem_gen_v8_4_4  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/2985/simulation/blk_mem_gen_v8_4.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ip/design_1_lmb_bram_0/sim/design_1_lmb_bram_0.v" \

vlog -work generic_baseblocks_v2_1_0  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/b752/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_22  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/af2c/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_5  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/276e/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_5 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/276e/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_5  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/276e/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_21  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/54c0/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_23  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/bc0a/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ip/design_1_xbar_0/sim/design_1_xbar_0.v" \

vcom -work axi_lite_ipif_v3_0_4 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/66ea/hdl/axi_lite_ipif_v3_0_vh_rfs.vhd" \

vcom -work axi_intc_v4_1_15 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/47b8/hdl/axi_intc_v4_1_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_microblaze_0_axi_intc_0/sim/design_1_microblaze_0_axi_intc_0.vhd" \

vlog -work xlconcat_v2_1_4  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/4b67/hdl/xlconcat_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ip/design_1_microblaze_0_xlconcat_0/sim/design_1_microblaze_0_xlconcat_0.v" \

vcom -work mdm_v3_2_19 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/8715/hdl/mdm_v3_2_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_mdm_1_0/sim/design_1_mdm_1_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ip/design_1_clk_wiz_1_0/design_1_clk_wiz_1_0_clk_wiz.v" \
"../../../bd/design_1/ip/design_1_clk_wiz_1_0/design_1_clk_wiz_1_0.v" \

vcom -work lib_cdc_v1_0_2 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_13 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/8842/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_rst_clk_wiz_1_100M_0/sim/design_1_rst_clk_wiz_1_100M_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ipshared/fc01/hdl/GPIO8_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/fc01/hdl/GPIO8_v1_0.v" \
"../../../bd/design_1/ip/design_1_GPIO8_0_0/sim/design_1_GPIO8_0_0.v" \
"../../../bd/design_1/ip/design_1_GPIO8_1_0/sim/design_1_GPIO8_1_0.v" \

vcom -work lib_pkg_v1_0_2 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/0513/hdl/lib_pkg_v1_0_rfs.vhd" \

vcom -work lib_srl_fifo_v1_0_2 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/51ce/hdl/lib_srl_fifo_v1_0_rfs.vhd" \

vcom -work axi_uartlite_v2_0_26 -93 \
"../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/5edb/hdl/axi_uartlite_v2_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93 \
"../../../bd/design_1/ip/design_1_axi_uartlite_0_0/sim/design_1_axi_uartlite_0_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../260505_MicroBlaze_I2C.gen/sources_1/bd/design_1/ipshared/d0f7" \
"../../../bd/design_1/ipshared/f4b8/hdl/TMR_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/f4b8/hdl/TMR_v1_0.v" \
"../../../bd/design_1/ip/design_1_TMR_0_0/sim/design_1_TMR_0_0.v" \
"../../../bd/design_1/ipshared/2835/hdl/I2C_v1_0_S00_AXI.v" \
"../../../bd/design_1/ipshared/2835/hdl/I2C_v1_0.v" \
"../../../bd/design_1/ip/design_1_I2C_0_0/sim/design_1_I2C_0_0.v" \
"../../../bd/design_1/sim/design_1.v" \

vlog -work xil_defaultlib \
"glbl.v"

