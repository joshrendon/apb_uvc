# 1. Open project
open_project project_2.xpr

# 2. Add ALL files to the project first (Force Vivado to see them)
add_files -norecurse [glob ./project_2.srcs/sources_1/new/*.sv]
#add_files -norecurse [glob vcd_setup.tcl]
update_compile_order -fileset sources_1

# 3. Identify the files that are `included inside the package
set uvm_include_files {
    apb_types.sv
    apb_item.sv
    apb_agent_config.sv
    apb_seq_item.sv
    apb_sequence.sv
    apb_sequencer.sv
    apb_driver.sv
    apb_master_driver.sv
    apb_monitor.sv
    apb_agent.sv
    apb_env.sv
    apb_test.sv
}

# 4. Filter the fileset and disable independent compilation
# We use only the filenames here because they are now in the project
foreach f $uvm_include_files {
    set_property used_in_simulation false [get_files $f]
}

# 5. FORCE apb_types.sv to be a Global Header
# This makes ADDR_WIDTH available to apb_interface.sv
set_property is_global_include 1 [get_files apb_types.sv]

# 6. Fix the Global Includes
set obj [get_filesets sim_1]

## Create a small helper script for XSim to run at startup
#set vcd_script "vcd_setup.tcl"
#set fp [open $vcd_script w]
#puts $fp "open_vcd dump.vcd"
#puts $fp "log_vcd /top/*"
#puts $fp "run -all"
#puts $fp "flush_vcd"
#puts $fp "close_vcd"
#puts $fp "quit"
#close $fp

set_property include_dirs ./project_2.srcs/sources_1/new [get_filesets sources_1]
set_property include_dirs ./project_2.srcs/sources_1/new $obj

# 6. Set UVM and Test properties
set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects $obj
set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects $obj
# Using your correct class name: rand_apb_test
# Update xsim.simulate.xsim.more_options to include this script
#set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TEST=random_apb_test -testplusarg UVM_VERBOSITY=UVM_LOW -tclbatch vcd_setup.tcl} -objects $obj
set_property -name {xsim.simulate.xsim.more_options} -value {-testplusarg UVM_TEST=apb_interleaved_test -testplusarg UVM_VERBOSITY=UVM_LOW} -objects $obj


# 7. Set Top and Launch
set_property top top $obj
launch_simulation -simset $obj -mode behavioral

#open_vcd "simulation_dump.vcd"
#log_vcd [get_objects -r /top/*]
log_wave -recursive *
run 1000ns
#run all
#open_wave_database ./project_2.sim/sim_1/behav/xsim/top_behav.wdb
#open_wave_config mysignals.wcfg
