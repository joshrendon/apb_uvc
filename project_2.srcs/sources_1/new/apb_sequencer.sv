`timescale 1ns / 1ps
class apb_sequencer extends uvm_sequencer#(apb_seq_item);
    `uvm_component_utils(apb_sequencer)
    
    function new(string name="apb_sequencer", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        #80;
        phase.drop_objection(this);
    endtask
endclass
