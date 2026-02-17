`ifndef APB_SLAVE_SEQUENCER_SV
`define APB_SLAVE_SEQUENCER_SV
`timescale 1ns / 1ps
class apb_slave_sequencer extends uvm_sequencer#(apb_item);
    `uvm_component_utils(apb_slave_sequencer)
    
    logic [31:0] slave_mem [logic[31:0]];

    function new(string name="apb_slave_sequencer", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.drop_objection(this);
    endtask
endclass
`endif
