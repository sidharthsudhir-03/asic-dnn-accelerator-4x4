set clk_period 2
set clk_pin CLK 
set rstn_pin RST_N
set eighths [ expr $clk_period / 8.0]
set quarter [ expr $clk_period / 4.0 ] 
set inputs_no_clk_rstn [remove_from_collection [all_inputs] [get_ports "$clk_pin $rstn_pin"]]

create_clock [get_ports $clk_pin] -name clk -period $clk_period

# Minimum sized DFF with slew rate of 1/8
set_driving_cell -lib_cell DFFX1 -input_transition_rise [expr 1 * $eighths] -input_transition_fall [expr 1 * $eighths] $inputs_no_clk_rstn

# Setting load 
set_load [expr [load_of [get_lib_pins */NAND2X4/A]] * 4] [all_outputs]

# IO delays
create_clock -period $clk_period -name io_virtual_clk
set_input_delay -max [ expr 1 * $quarter ] -clock io_virtual_clk -add_delay $inputs_no_clk_rstn
set_output_delay -max [ expr 1 * $quarter ] -clock io_virtual_clk -add_delay [all_outputs]

# Adding latency and uncertanity
set_clock_latency      $eighths [get_clocks clk]
set_clock_uncertainty  $eighths [get_clocks clk]

# Max Fanout value of 4
set_max_fanout 4 [all_inputs]
