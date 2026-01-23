`timescale 1ns / 1ps
class apb_item extends uvm_sequence_item;
    rand bit [`APB_MAX_ADDR_WIDTH-1:0] paddr;
    rand bit pwrite;
    rand bit [`APB_MAX_DATA_WIDTH-1:0] prdata;
    rand bit [`APB_MAX_DATA_WIDTH-1:0] pwdata;

    // Control knobs that the driver sets
    rand bit [`APB_MAX_SEL_WIDTH-1:0] psel;
    bit penable;
    bit pready;
    `uvm_object_utils_begin(apb_item)
        `uvm_field_int(paddr, UVM_ALL_ON)
        `uvm_field_int(pwrite, UVM_ALL_ON)
        `uvm_field_int(prdata, UVM_ALL_ON)
        `uvm_field_int(pwdata, UVM_ALL_ON)
        `uvm_field_int(psel, UVM_ALL_ON)
        `uvm_field_int(penable, UVM_ALL_ON)
        `uvm_field_int(pready, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="apb_item");
        super.new(name);
    endfunction

    constraint paddr_limit {
        paddr >= 32'h4000_0000;
        paddr <  32'h4002_0000;
    }

    constraint psel_onehot {
        (psel & (psel-1)) == 0;
        psel != 0;
    }

endclass
