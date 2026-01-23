`timescale 1ns / 1ps
class apb_seq_item extends apb_item;
    `uvm_object_utils(apb_seq_item)

    function new(string name="apb_seq_item");
        super.new(name);
    endfunction
endclass
