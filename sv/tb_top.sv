`timescale 1ns / 1ps
module tb_top;
`ifndef SYNTHESIS
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import apb_pkg::*;
`endif
    logic clk, rst_n;

    top hdl_top(
        .sys_clk(clk),
        .sys_rst_n(rst_n),
        .leds()
    );

    initial begin
        clk = 0;
    end
    always #10 clk = ~clk;
    
    initial begin
        rst_n   = 1;
        #20 rst_n   = 0;
        #20 rst_n   = 1;
    end

    //initial begin
    //    $dumpfile("apb_wave_dump.vcd");
    //    $dumpvars;
    //end
    initial begin
        // Pass the interface from hdl_top to the UVM database
`ifndef SYNTHESIS
        uvm_config_db#(virtual interface apb_interface)::set(uvm_root::get(), "*", "vif", hdl_top.mif);
        //run_test("random_apb_test");
        run_test("apb_wr_test");
`endif
    end
    
endmodule
