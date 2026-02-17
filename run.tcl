# 1. Open project
open_project project_2.xpr

# 2. Add ALL files to the project first (Force Vivado to see them)
add_files -norecurse ./sv/apb_defines.sv
add_files -norecurse [glob ./rtl/*.sv]

# 3. Identify the files that are `included inside the package
set uvm_include_files {
    apb_defines.sv
    apb_types.sv
    apb_item.sv
    apb_agent_config.sv
    apb_sequence.sv
    apb_sequencer.sv
    apb_driver.sv
    apb_master_driver.sv
    apb_interface.sv
    apb_monitor.sv
    apb_scoreboard.sv
    apb_predictor.sv
    apb_agent.sv
    apb_env.sv
    apb_test.sv
}

# 4. Filter the fileset and disable independent compilation
# We use only the filenames here because they are now in the project
foreach f $uvm_include_files {
    set_property used_in_synthesis false [get_files $f]
    set_property used_in_simulation false [get_files $f]
}
set_property used_in_synthesis false [get_files apb_pkg.sv]
set_property used_in_synthesis true [get_files apb_interface.sv]
set_property used_in_synthesis true [get_files apb_defines.sv]
set_property used_in_simulation true [get_files apb_pkg.sv]
set_property used_in_simulation true [get_files tb_top.sv]
set_property used_in_simulation true [get_files apb_predictor.sv]

# 5. FORCE apb_types.sv to be a Global Header
# This makes ADDR_WIDTH available to apb_interface.sv
#set_property is_global_include 1 [get_files apb_defines.sv]

# 6. Fix the Global Includes
set obj [get_filesets sim_1]

#set_property include_dirs ./sv [current_fileset -simset]
set_property include_dirs ./sv [get_filesets sources_1]
set_property is_global_include 1 [get_files apb_defines.sv]
add_files -fileset sim_1 -norecurse [glob ./sv/tb_top.sv]
add_files -fileset sim_1 -norecurse [glob ./sv/*.sv]

# 6. Set UVM and Test properties
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects $obj
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects $obj
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TEST=apb_reg_test -testplusarg UVM_VERBOSITY=UVM_LOW} -objects $obj


# 7. Set Top and Launch
set_property top tb_top [get_filesets sim_1]
launch_simulation -simset $obj -mode behavioral

log_wave -recursive *
#run 1000ns
run all

# Run synthesis
# Prepare and Launch Synthesis
set_property file_type {SystemVerilog Header} [get_files apb_defines.sv]

set_property is_global_include 1 [get_files apb_defines.sv]
set_property include_dirs ./sv [get_filesets sources_1]

set_property used_in_synthesis false [get_files pinout.xdc]

add_files -fileset constrs_1 -norecurse ./constraints/slave_timing.xdc
set_property used_in_synthesis true [get_files slave_timing.xdc]

# Change the top module to the slave itself for a logic-check
set_property top apb_slave_dut [current_fileset]

# Optional: Set flattened hierarchy to none to see the sub-modules
set_property -name {STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY} -value {none} -objects [get_runs synth_1]

update_compile_order -fileset sources_1

reset_run synth_1
launch_runs synth_1 -to_step synth_design
wait_on_run synth_1

# Ensure the GUI shows the "Real" top for the next time you open it
set_property top top [get_filesets sources_1]
update_compile_order -fileset sources_1
