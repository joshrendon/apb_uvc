`ifndef APB_SLAVE_SEQUENCER_SV
`define APB_SLAVE_SEQUENCER_SV
`timescale 1ns / 1ps
class apb_slave_sequencer extends uvm_sequencer#(apb_item);
    `uvm_component_utils(apb_slave_sequencer)
    
    uvm_analysis_export #(apb_item) request_export;
    uvm_tlm_analysis_fifo #(apb_item) request_fifo;
    logic [31:0] slave_mem [logic[31:0]];

    function new(string name="apb_slave_sequencer", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        request_export = new("request_export", this);
        request_fifo = new("request_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        request_export.connect(request_fifo.analysis_export);
    endfunction

endclass
`endif
