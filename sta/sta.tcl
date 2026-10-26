# sta.tcl
# OpenSTA static timing analysis script for mult_array (Part C of RTL_to_GDS.pdf).
# Run with: sta sta/sta.tcl
#
# T is the clock period in ns. Per Part C: first run with T=10, read the
# worst slack, compute Tmin = T - WNS, then edit T below to Tmin (rounded
# to 0.01 ns) and rerun to confirm slack is close to 0.

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
set T 2.98

# Step 1: read the cell timing library
read_liberty $lib

# Step 2: read and link the synthesized netlist
read_verilog synth/mult_array_netlist.v
link_design mult_array

# Step 3: define the clock with period T (ns)
create_clock -name clk -period $T [get_ports clk]

# Step 4: input arrival time
set_input_delay 1.0 -clock clk [delete_from_list [all_inputs] [get_ports clk]]

# Step 5: output required time
set_output_delay 1.0 -clock clk [all_outputs]

# Step 6: print the worst setup slack
report_worst_slack -max

# Step 7: save the critical path report
report_checks -path_delay max -digits 3 > sta/mult_array_timing.rpt
