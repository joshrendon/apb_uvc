TEST_NAME=${1:-"apb_wr_test"}

echo "Compiling with Vivado XSIM..."
xvlog -sv -L uvm sv/apb_types.sv sv/apb_interface.sv

xvlog -sv -L uvm sv/apb_pkg.sv

xvlog -sv -L uvm sv/tb_top.sv
echo "Running without coverage..."
xelab -L uvm --timescale 1ns/1ps tb_top
        
xsim -R tb_top -testplusarg UVM_TESTNAME=$TEST_NAME -testplusarg UVM_VERBOSITY=UVM_LOW --f run.f
