`ifndef APB_INTERFACE_SV
`define APB_INTERFACE_SV
`include "apb_types.sv"
`timescale 1ns / 1ps

interface apb_interface();

    logic pclk;
    logic prstn;
    logic [`APB_MAX_ADDR_WIDTH-1:0] paddr;
    logic [`APB_MAX_SEL_WIDTH-1:0]  psel;
    logic penable;
    logic pwrite;
    logic [`APB_MAX_DATA_WIDTH-1:0]   prdata;
    logic [`APB_MAX_DATA_WIDTH-1:0]   pwdata;
    logic [`APB_MAX_STROBE_WIDTH-1:0] pstrb;
    logic pready;
    logic pslverr;

    // Master clocking block used for Drivers
    clocking master_cb @(posedge pclk);
        output paddr, psel, penable, pwrite, pwdata, pstrb;
        input prdata, pslverr, pready;
    endclocking : master_cb

    // Slave clocking block used for Slave BFMS
    clocking slave_cb @(posedge pclk);
        input paddr, psel, penable, pwrite, pwdata, pready, pslverr, pstrb;
        output prdata;
    endclocking : slave_cb

    clocking monitor_cb @(posedge pclk);
        input paddr, psel, penable, pwrite, pwdata, prdata, pready, pslverr;
        input pstrb;
    endclocking : monitor_cb

    modport master(clocking master_cb);
    modport slave(clocking slave_cb);
    modport passive(clocking monitor_cb);

endinterface
`endif
