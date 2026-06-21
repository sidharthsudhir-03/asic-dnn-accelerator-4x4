#################################################################################
# 7) Outputs

# At this point both drc and connectivity should be clean
verify_drc
verify_connectivity
checkFiller -reportGap 0.2
checkFiller -reportGap 0.4

saveNetlist "$PNR_OUT_FOLDER/${TOP_LEVEL}_pnr.v" -excludeLeafCell

timeDesign -postRoute -reportOnly
write_sdf -max_view av_lsMax_rcWorst_cmFunc -typ_view av_lsMax_rcWorst_cmFunc -recompute_delay_calc -edges noedge -splitsetuphold -remashold -splitrecrem -min_period_edges both "$PNR_OUT_FOLDER/${TOP_LEVEL}_pnr.sdf"
