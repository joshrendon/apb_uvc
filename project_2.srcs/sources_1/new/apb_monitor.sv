`timescale 1ns / 1ps
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)
    function new(string name="apb_monitor", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction
endclass
