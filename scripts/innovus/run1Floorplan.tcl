#################################################################################
# 2) Floorplanning, power distribution network, and pin placement

# 2a) Floorplanning
setFPlanMode -snapDieGrid manufacturing
setFPlanMode -snapCoreGrid manufacturing

# Floorplan -> args for -r flag -- {aspect ratio, utilization, margins on [Left Bottom Right Top]
floorPlan -site CoreSite -r 1 0.7 8 8 8 8

# Query core box after floorplan: {llx lly urx ury}
set core_box [dbGet top.fPlan.coreBox]
set llx  [lindex $core_box 0]
set lly  [lindex $core_box 1]
set urx  [lindex $core_box 2]
set ury  [lindex $core_box 3]

set x_left  0.0
set x_right 169.0

# 2b) connecting the global power nets to the power nets on gates/tie-hi or tie-lo
globalNetConnect VDD -type pgpin -pin VDD -instanceBasename * -hierarchicalInstance {}
globalNetConnect VDD -type tiehi -instanceBasename * -hierarchicalInstance {}
globalNetConnect VSS -type pgpin -pin VSS -instanceBasename * -hierarchicalInstance {}
globalNetConnect VSS -type tielo -instanceBasename * -hierarchicalInstance {}

# 2c) Adding the power ring
setAddRingMode -ring_target default -extend_over_row 0 -ignore_rows 0 -avoid_short 0 -skip_crossing_trunks "none" -stacked_via_top_layer "Metal11" -stacked_via_bottom_layer "Metal1" -via_using_exact_crossover_size 1 -orthogonal_only true -skip_via_on_pin {  standardcell } -skip_via_on_wire_shape {  noshape }

addRing -nets [list "VDD" "VSS"] -type core_rings -follow "core" -layer {top "Metal7" bottom "Metal7" left "Metal8" right "Metal8"} -width {top 1.8 bottom 1.8 left 1.8 right 1.8} -spacing {top 0.45 bottom 0.45 left 0.45 right 0.45} -offset {top 1.8 bottom 1.8 left 1.8 right 1.8} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid "None"

# 2d) sroute for making the horizontal power tracks
setSrouteMode -viaConnectToShape { noshape }

sroute -connect { blockPin padPin padRing corePin floatingStripe } -layerChangeRange { Metal1(1) Metal6(6) } -blockPinTarget { nearestTarget } -padPinPortConnect { allPort oneGeom } -padPinTarget { nearestTarget } -corePinTarget { firstAfterRowEnd } -floatingStripeTarget { blockring padring ring stripe ringpin blockpin followpin } -allowJogging 1 -crossoverViaLayerRange { Metal1(1) Metal11(11) } -nets { VDD VSS } -allowLayerChange 1 -blockPin useLef -targetViaLayerRange { Metal1(1) Metal11(11) }

# 2e) Adding power stripes 
setAddStripeMode -ignore_block_check false -break_at none -route_over_rows_only false -rows_without_stripes_only false -extend_to_closest_target none -stop_at_last_wire_for_area false -partial_set_thru_domain false -ignore_nondefault_domains false -trim_antenna_back_to_shape none -spacing_type edge_to_edge -spacing_from_block 0 -stripe_min_length stripe_width -stacked_via_top_layer Metal11 -stacked_via_bottom_layer Metal1 -via_using_exact_crossover_size false -split_vias false -orthogonal_only true -allow_jog { padcore_ring  block_ring } -skip_via_on_pin { standardcell } -skip_via_on_wire_shape { noshape }

addStripe -nets [list "VDD" "VSS"] -layer "Metal6" -direction vertical -width 1.8 -spacing 0.45 -number_of_sets 4 -start_from left -start_offset 3 -switch_layer_over_obs false -max_same_layer_jog_length 2 -padcore_ring_top_layer_limit Metal11 -padcore_ring_bottom_layer_limit Metal1 -block_ring_top_layer_limit Metal11 -block_ring_bottom_layer_limit Metal1 -use_wire_group 0 -snap_wire_center_to_grid None


# 2f) Pin placement
setPinAssignMode -pinEditInBatch true

# NOTE: The command below spreads all the wires on the Right edge of the floorplan

editPin -snap MGRID -fixOverlap 1 -spreadDirection clockwise -side Left -layer 3 -spreadType range -start $x_left 0.0 -end $x_left 35.0 -pin {VALID_memVal memVal_data*}

editPin -snap MGRID -fixOverlap 1 -spreadDirection clockwise -side Left -layer 3 -spreadType range -start $x_left 39.0 -end $x_left 41.0 -pin {CLK RST_N}

editPin -snap MGRID -fixOverlap 1 -spreadDirection clockwise -side Left -layer 3 -spreadType range -start $x_left 36.0 -end $x_left 38.0 -pin {EN_blockRead RDY_blockRead}

editPin -pinWidth 0.08 -pinDepth 0.25 -snap MGRID -fixOverlap 1 -spreadDirection counterclockwise -side Right -layer 3 -spreadType range -start $x_right 0.0 -end $x_right 41.0 -pin {EN_readMem readMem_addr* readMem_val*}

editPin -snap MGRID -fixOverlap 1 -spreadDirection clockwise \
        -side Right -layer 3 -spreadType range \
        -start $x_right 42.0 -end $x_right 83.0 \
        -pin {EN_writeMem writeMem_addr* writeMem_val*}


editPin -snap MGRID -fixOverlap 1 -spreadDirection clockwise \
        -side Right -layer 3 -spreadType range -start $x_left 42.0 -end $x_left 172.0 \
        -pin {EN_mac RDY_mac mac_vectA_0* mac_vectB_0* mac_vectA_1* mac_vectB_1* mac_vectA_2* mac_vectB_2* mac_vectA_3* mac_vectB_3*}


setPinAssignMode -pinEditInBatch false

# This will show pre-place timing
timeDesign -reportOnly -prePlace -slackReports -numPaths 5 -prefix "${TOP_LEVEL}_prePlace" -outDir reports
report_timing -nworst 5 > ./reports/${TOP_LEVEL}_prePlace.rpt

# Saving design after floorplanning
saveDesign chkpts/${TOP_LEVEL}_prePlace

