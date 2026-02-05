`timescale 1ns / 1ps
`ifndef APB_ITEM_SV
`define APB_ITEM_SV
class apb_item extends uvm_sequence_item;
    rand bit [`APB_MAX_ADDR_WIDTH-1:0]     paddr;
    rand bit                               pwrite;
    rand bit [`APB_MAX_DATA_WIDTH-1:0]     prdata;
    rand bit [`APB_MAX_DATA_WIDTH-1:0]     pwdata;
    rand bit [`APB_MAX_SEL_WIDTH-1:0]      pstrb;
    rand bit [`APB_MAX_SEL_WIDTH-1:0]      psel;

    `uvm_object_utils_begin(apb_item)
        `uvm_field_int(paddr,  UVM_ALL_ON)
        `uvm_field_int(psel,   UVM_ALL_ON)
        `uvm_field_int(pwrite, UVM_ALL_ON)
        `uvm_field_int(prdata, UVM_ALL_ON)
        `uvm_field_int(pwdata, UVM_ALL_ON)
        `uvm_field_int(pstrb,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="apb_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
      string s;
      // Format: [TIME] ADDR: 0x4000_0000 | WRITE | DATA: 0xDEADBEEF | STRB: 0xF
      s = $sformatf("ADDR: 0x%0h | %s", paddr, (pwrite ? "WRITE" : "READ "));
      
      if (pwrite) 
        s = {s, $sformatf(" | WDATA: 0x%0h | STRB: 0x%0h", pwdata, pstrb)};
      else        
        s = {s, $sformatf(" | RDATA: 0x%0h", prdata)};
        
      return s;
    endfunction

    //virtual function void do_print(uvm_printer printer);
    //    printer.m_string = convert2string();
    //endfunction

    constraint paddr_limit {
        paddr inside {[32'h4000_0000 : 32'h4001_FFFF]};
    }

    constraint psel_onehot {
        (psel & (psel-1)) == 0;
        psel != 0;
    }

    constraint pstrb_val {
        if (pwrite == 0)
            pstrb == 0;
        else 
            pstrb != 0;
    }

endclass
`endif
