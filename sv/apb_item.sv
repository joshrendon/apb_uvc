`timescale 1ns / 1ps
`ifndef APB_ITEM_SV
`define APB_ITEM_SV
class apb_item extends uvm_sequence_item;
    rand apb_addr_t                        paddr;
    rand bit [`APB_MAX_SEL_WIDTH-1:0]      psel;
    rand apb_direction_t                   pwrite;
    rand apb_data_t                        pdata;
    rand bit [`APB_MAX_STROBE_WIDTH-1:0]   pstrb;
    rand bit                               pslverr;
    rand int                               wait_cycles;

    `uvm_object_utils_begin(apb_item)
        `uvm_field_int(paddr,        UVM_ALL_ON)
        `uvm_field_int(psel,         UVM_ALL_ON)
        `uvm_field_enum(apb_direction_t, pwrite,  UVM_ALL_ON)
        `uvm_field_int(pdata,        UVM_ALL_ON)
        `uvm_field_int(pstrb,        UVM_ALL_ON)
        `uvm_field_int(pslverr,      UVM_ALL_ON)
        `uvm_field_int(wait_cycles,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="apb_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
      string s;
      // Format: [TIME] ADDR: 0x4000_0000 | WRITE | DATA: 0xDEADBEEF | STRB: 0xF
      s = $sformatf("ADDR: 0x%0h | %s", paddr, pwrite.name());
      
      if (pwrite) 
        s = {s, $sformatf(" | DATA: 0x%0h | STRB: 0x%0h", pdata, pstrb)};
      else        
        s = {s, $sformatf(" | DATA: 0x%0h", pdata)};
        
      return s;
    endfunction

    virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer=null);
        apb_item rhs_;
        $cast(rhs_, rhs);
        if (psel   != rhs_.psel  ) return 0;
        if (paddr  != rhs_.paddr ) return 0;
        if (pwrite != rhs_.pwrite) return 0;
        if (pdata  != rhs_.pdata) return 0;
        if (pstrb  != rhs_.pstrb ) return 0;
        return 1;
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

    constraint c_wait {
        wait_cycles inside {[0:5]};
    }

endclass
`endif
