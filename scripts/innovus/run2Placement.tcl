#################################################################################
# 3) Placement

# 3a) first place opt iteration
createBasicPathGroups -expanded 

setPlaceMode -place_detail_use_check_drc true
set_dont_use [get_lib_cells *BUFX2* ] true

place_opt_design

# 3b) Fixing any overlaps on the cells and fixing fanouts

addTieHiLo -cell {TIEHI TIELO} -prefix LTIE

setOptMode -fixFanoutLoad true
optDesign -preCTS
optDesign -preCTS -incr

# This will show post-place/pre-CTS timing
timeDesign -reportOnly -preCTS -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_preCTS" -outDir reports
report_timing -nworst 5 > ./reports/${TOP_LEVEL}_preCTS.rpt

# Saving design after placement
saveDesign chkpts/${TOP_LEVEL}_preCTS

#################################################################################
