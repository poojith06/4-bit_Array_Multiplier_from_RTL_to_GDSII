# Run with: yosys -c synth/synth.tcl

set lib $::env(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib

# Step 1: read the design
yosys read_verilog rtl/full_adder.v rtl/mult_array.v

# Step 2: generic synthesis, flatten the full adders into one module
yosys synth -top mult_array -flatten

# Step 3: map flip-flops to SKY130 flip-flop cells
yosys dfflibmap -liberty $lib

# Step 4: map the logic to SKY130 gate cells
yosys abc -liberty $lib

# Step 5: remove unused wires
yosys opt_clean -purge

# Step 6: write the cell and area report
yosys tee -o synth/mult_array_stat.rpt stat -liberty $lib

# Step 7: write the gate-level netlist
yosys write_verilog -noattr synth/mult_array_netlist.v
