# 0) Prep - a) folders to point to the synthesis outputs
set PNR_OUT_FOLDER /ubc/ece/home/ugrads/s/sidsud03/Desktop/Innovus/MAC/output/
set SYNTH_OUT_FOLDER /ubc/ece/home/ugrads/s/sidsud03/Desktop/Genus/MAC/syn/outputs/

# 0) Prep - b) library timing, lef folders
set LIB_FOLDER /ubc/ece/data/cmc2/kits/GPDK45/gsclib045_all_v4.4/gsclib045/timing
set RCTECH_FOLDER /ubc/ece/data/cmc2/kits/GPDK45/gsclib045_all_v4.4/gsclib045/qrc/qx
set LEF_FOLDER /ubc/ece/data/cmc2/kits/GPDK45/gsclib045_all_v4.4/gsclib045/lef

# 0) Prep - c) specifiers for the design, versioning etc
set TOP_LEVEL "mkMACBuff"

setMultiCpuUsage -localCpu 1
setDesignMode -process 45 -node "unspecified"

#################################################################################
# 1) Design import 
set init_lef_file [list "$LEF_FOLDER/gsclib045_tech.lef" "$LEF_FOLDER/gsclib045_macro.lef"]

set init_verilog [list "$SYNTH_OUT_FOLDER/${TOP_LEVEL}_map.sv"]
set init_top_cell mkMACBuff

set init_pwr_net "VDD"
set init_gnd_net "VSS"

set init_mmmc_file "MMMC.tcl"

init_design
