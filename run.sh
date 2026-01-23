xvlog -sv -L uvm  project_2.srcs/sources_1/new/apb_types.sv project_2.srcs/sources_1/new/apb_interface.sv
xvlog -sv -L uvm project_2.srcs/sources_1/new/apb_pkg.sv
xvlog -sv -L uvm project_2.srcs/sources_1/new/apb_dut.sv project_2.srcs/sources_1/new/top.sv
xelab -L uvm --timescale 1ns/1ps top
xsim -R top -testplusarg UVM_TEST=random_apb_test -testplusarg UVM_VERBOSITY=UVM_LOW
