#################################################################################
# 5) Routing

# 5a) Initial detail route
setNanoRouteMode -routeInsertAntennaDiode 1 -routeAntennaCellName "ANTENNA"
setNanoRouteMode -routeWithTimingDriven 1 -routeWithSiDriven 1
setNanoRouteMode -drouteAutoStop 0 -drouteEndIteration 5
setNanoRouteMode -routeTopRoutingLayer 10

routeDesign -globalDetail -viaOpt -wireOpt

# 5b) optimizing for post route
setAnalysisMode -analysisType onChipVariation -cppr both
optDesign -postRoute -setup -hold 

# This will show post-route timing
timeDesign -reportOnly -postRoute -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_postRoute" -outDir reports
timeDesign -reportOnly -postRoute -hold -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_postRoute_hold" -outDir reports
report_timing -nworst 5 > ./reports/${TOP_LEVEL}_postRoute.rpt

# Saving design after routing
saveDesign chkpts/${TOP_LEVEL}_postRoute

return
#################################################################################
