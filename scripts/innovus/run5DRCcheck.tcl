#################################################################################
# 6) Fixing DRCs

# 6a) Making gaps 2x column by moving stdcells around
addFillerGap 0.4 -effort high
checkFiller -reportGap 0.2

# 6b) Adding filler cells
addFiller -cell {DECAP8 DECAP10} -prefix FILLER1 -doDRC -fitGap
addFiller -cell {DECAP2 DECAP3} -prefix FILLER2 -doDRC -fitGap
# NOTE - Use the deleteFiller command to remove fillers

# 6c) First ecoRoute to connect the displaced nets, then ecoRoute only to fix DRCs
ecoRoute
verify_drc
ecoRoute -fix_drc

# This will show final timing
timeDesign -reportOnly -postRoute -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_final" -outDir reports
report_timing -nworst 5 > ./reports/${TOP_LEVEL}_final.rpt

# Saving design after finish
saveDesign chkpts/${TOP_LEVEL}_final

#################################################################################
