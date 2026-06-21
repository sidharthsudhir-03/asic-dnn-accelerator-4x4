#################################################################################
# 4) Clock Tree Synthesis
reset_ccopt_config

update_constraint_mode -name cmFunc -sdc_files "/ubc/ece/home/ugrads/s/sidsud03/Desktop/Genus/MAC/syn/outputs/${TOP_LEVEL}_map.sdc"

# 4a) Setting the clock tree root, period
# NOTE: To list all ccopt_properties, use - get_ccopt_property -help *
set_ccopt_property cts_is_sdc_clock_root -pin CLK true
create_ccopt_clock_tree -name CLK -source CLK -no_skew_group
set_ccopt_property clock_period -pin CLK [lindex [get_db clocks .period] 0]

# 4b) Set params for cts
set_ccopt_property max_fanout 4
set_ccopt_property target_max_trans 0.125
set_ccopt_property buffer_cells {CLKBUFX2 CLKBUFX3 CLKBUFX4 CLKBUFX8 CLKBUFX12 CLKBUFX16}

create_route_type -name CLKRouteType -top_preferred_layer Metal7 -bottom_preferred_layer Metal4 
set_ccopt_property route_type CLKRouteType

# 4c) Skew group to balance non generated clock:CLK in timing_config:cmFunc 
create_ccopt_skew_group -name CLK/cmFunc -sources CLK -auto_sinks
set_ccopt_property include_source_latency -skew_group CLK/cmFunc true
set_ccopt_property extracted_from_clock_name -skew_group CLK/cmFunc CLK
set_ccopt_property extracted_from_constraint_mode_name -skew_group CLK/cmFunc cmFunc
set_ccopt_property extracted_from_delay_corners -skew_group CLK/cmFunc {dc_lsMax_rcWorst dc_lsMin_rcBest}

# 4c) Check convergence and make clock tree
check_ccopt_clock_tree_convergence
ccopt_design -cts
# NOTE - Use 'report_ccopt_clock_trees' to report specifications of the clock tree.

optDesign -postCTS
optDesign -postCTS -hold 

# This will show post-CTS timing
timeDesign -reportOnly -postCTS -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_postCTS" -outDir reports
timeDesign -reportOnly -postCTS -hold -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_postCTS_hold" -outDir reports
report_timing -nworst 5 > ./reports/${TOP_LEVEL}_postCTS.rpt

# Saving design after CTS
saveDesign chkpts/${TOP_LEVEL}_postCTS

#################################################################################
