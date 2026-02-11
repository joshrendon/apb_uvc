`timescale 1ns / 1ps
module top(
    input logic sys_clk,
    input logic sys_rst_n,
    ////output logic [7:0] leds
    output logic [3:0] leds,      // 4 Green LEDs
    output logic [5:0] rgb_leds,  // 2 RGB LEDs (R-G-B each)
    input  logic [3:0] sw,        // 4 Switches
    input  logic [3:0] btn        // 4 Buttons
);

    logic [2:0] pprot;
    logic pnse;
    logic pready_s0, pready_s1; //preadies for slaves s0, s1
    logic pslverr_s0, pslverr_s1;
    logic [31:0] prdata_s0, prdata_s1;

    logic [3:0] s0_leds;
    logic [5:0] s0_rgb;

    apb_interface mif();
    assign mif.pclk = sys_clk;
    assign mif.prstn = sys_rst_n;
    //assign mif.pwdata = 32'hFFFFFFFF;
    
    apb_slave_dut #(.AW(32), .DW(32), .SW(4), .DEPTH(256)) slave_0 (
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
      .PSTRB(mif.pstrb),
      .PSLVERR(pslverr_s0),
      .leds(s0_leds),
      .rgb_leds(s0_rgb),
      .switches(sw),
      .buttons(btn)
    );

    apb_slave_dut #(.AW(32), .DW(32), .SW(4), .DEPTH(256)) slave_1 (
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
      .PSTRB(mif.pstrb),
      .PSLVERR(pslverr_s1)
    );
    
    initial begin
        pprot = 3'b000;
        pnse  = 1'b0;
    end
    
    // Simple OR-reduction for PREADY (assuming inactive slaves drive 0)
    // Or a Mux based on which PSEL is active
    assign mif.pready = mif.psel[0] ? pready_s0 : 
                        mif.psel[1] ? pready_s1 : 1'b0;
    
    assign mif.prdata = mif.psel[0] ? prdata_s0 : 
                        mif.psel[1] ? prdata_s1 : '0;

    assign mif.pslverr = mif.psel[0] ? pslverr_s0 : 
                         mif.psel[1] ? pslverr_s1 : '0;

    assign leds     = s0_leds;
    assign rgb_leds = s0_rgb;

endmodule
