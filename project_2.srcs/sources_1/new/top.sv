`timescale 1ns / 1ps
module top;
    `include "uvm_macros.svh"
    import uvm_pkg::*;
    import apb_pkg::*;
    `include "apb_types.sv"
    `include "apb_interface.sv"
    
    logic [2:0] pprot;
    logic pnse;

    logic pready_s0, pready_s1; //preadies for slaves s0, s1
    logic pslverr_s0, pslverr_s1;
    logic [`APB_MAX_DATA_WIDTH-1:0] prdata_s0, prdata_s1;

    apb_interface mif();
    
    apb_slave_dut #(.ADDR_WIDTH(`APB_MAX_ADDR_WIDTH), .DATA_WIDTH(`APB_MAX_DATA_WIDTH)) slave_0 (
      .PCLK(mif.pclk),
      .PRESETn(mif.prstn),
      .PADDR(mif.paddr),
      .PPROT(pprot),
      .PNSE(pnse),
      .PSEL(mif.psel[0]),
      .PENABLE(mif.penable),
      .PWRITE(mif.pwrite),
      .PWDATA(mif.pwdata),
      .PREADY(pready_s0),
      .PRDATA(prdata_s0),
      .PSLVERR(pslverr_s0)
    );

    apb_slave_dut #(.ADDR_WIDTH(`APB_MAX_ADDR_WIDTH), .DATA_WIDTH(`APB_MAX_DATA_WIDTH)) slave_1 (
      .PCLK(mif.pclk),
      .PRESETn(mif.prstn),
      .PADDR(mif.paddr),
      .PPROT(pprot),
      .PNSE(pnse),
      .PSEL(mif.psel[1]),
      .PENABLE(mif.penable),
      .PWRITE(mif.pwrite),
      .PWDATA(mif.pwdata),
      .PREADY(pready_s1),
      .PRDATA(prdata_s1),
      .PSLVERR(pslverr_s1)
    );

    // Simple OR-reduction for PREADY (assuming inactive slaves drive 0)
    // Or a Mux based on which PSEL is active
    assign mif.pready = mif.psel[0] ? pready_s0 : 
                        mif.psel[1] ? pready_s1 : 1'b0;
    
    assign mif.prdata = mif.psel[0] ? prdata_s0 : 
                        mif.psel[1] ? prdata_s1 : '0;

    assign mif.pslverr = mif.psel[0] ? pslverr_s0 : 
                         mif.psel[1] ? pslverr_s1 : '0;

    initial begin
        mif.pclk    = 0;
    end
    always #10 mif.pclk = ~mif.pclk;
    
    initial begin
        //clk    = 0;
        mif.prstn   = 1;
        repeat (1) @(posedge mif.pclk);
        mif.prstn   = 0;
        repeat (1) @(posedge mif.pclk);
        mif.prstn   = 1;
        pprot  = 0;
        pnse   = 0;
    end

    //initial begin
    //    $dumpfile("apb_wave_dump.vcd");
    //    $dumpvars;
    //end
    initial begin
        uvm_config_db#(virtual apb_interface)::set(uvm_root::get(), "*", "vif", mif);
        run_test("random_apb_test");
    end
    

endmodule
