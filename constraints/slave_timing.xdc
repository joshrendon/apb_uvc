
# Timing Constraint (Assuming 100MHz clock)
create_clock -add -period 10.000 -name PCLK -waveform {0.000 5.000} [get_ports PCLK]

# Pin Assignments (Replace with your actual FPGA package pins)
set_property PACKAGE_PIN E3 [get_ports PCLK]
set_property IOSTANDARD LVCMOS33 [get_ports PCLK]

set_property PACKAGE_PIN C12 [get_ports PRESETn]
set_property IOSTANDARD LVCMOS33 [get_ports PRESETn]
