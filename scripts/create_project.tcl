# create_project.tcl
# Rebuilds the Vivado project from the source files in this repository.
# Usage (Vivado Tcl console):   source scripts/create_project.tcl
# Usage (terminal):             vivado -mode batch -source scripts/create_project.tcl

set script_dir [file dirname [file normalize [info script]]]
set repo_dir   [file normalize "$script_dir/.."]

create_project motor_fpga "$repo_dir/build" -part xc7a100tcsg324-1 -force

# Design sources
add_files -norecurse [glob "$repo_dir/src/*.v"]

# Constraints
add_files -fileset constrs_1 -norecurse "$repo_dir/constraints/nexys_a7_motor.xdc"

# Simulation sources
add_files -fileset sim_1 -norecurse "$repo_dir/sim/tb_top.v"

# Top modules
set_property top top [get_filesets sources_1]
set_property top tb_top [get_filesets sim_1]

# The testbench needs ~300 ms to show the direction-change guard
set_property -name {xsim.simulate.runtime} -value {300ms} -objects [get_filesets sim_1]

update_compile_order -fileset sources_1

puts "Project created in $repo_dir/build"
