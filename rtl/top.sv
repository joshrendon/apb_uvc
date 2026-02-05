`timescale 1ns / 1ps
module top(
    input logic sys_clk,
    input logic sys_rst_n,
    output logic [7:0] leds
);
    `include "apb_defines.sv"
    logic [2:0] pprot;
    logic pnse;

    logic pready_s0, pready_s1; //preadies for slaves s0, s1
    logic pslverr_s0, pslverr_s1;
    logic [`APB_MAX_DATA_WIDTH-1:0] prdata_s0, prdata_s1;

    apb_interface mif();
    assign mif.pclk = sys_clk;
    assign mif.prstn = sys_rst_n;
    
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
    
    initial begin
        pprot = 3'b000;
        pnse  = 1'b0;
        prdata_s0 = '0;
        prdata_s1 = '0;
    end
    
    // Simple OR-reduction for PREADY (assuming inactive slaves drive 0)
    // Or a Mux based on which PSEL is active
    assign mif.pready = mif.psel[0] ? pready_s0 : 
                        mif.psel[1] ? pready_s1 : 1'b0;
    
    assign mif.prdata = mif.psel[0] ? prdata_s0 : 
                        mif.psel[1] ? prdata_s1 : '0;

    assign mif.pslverr = mif.psel[0] ? pslverr_s0 : 
                         mif.psel[1] ? pslverr_s1 : '0;

    assign leds = mif.prdata[7:0];

endmodule
