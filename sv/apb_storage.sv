`ifndef APB_STORAGE_SV
`define APB_STORAGE_SV
class apb_storage extends uvm_object;
    `uvm_object_utils(apb_storage);

    logic [`APB_MAX_DATA_WIDTH-1:0] mem [logic [`APB_MAX_ADDR_WIDTH-1:0]];

    function new(string name = "apb_storage");
        super.new(name);
    endfunction

    function void display_mem();
        logic [`APB_MAX_ADDR_WIDTH-1:0] index;

        if (mem.first(index)) begin
            do
                `uvm_info("apb_storage", $sformatf("mem[0x%0h] = 0x%0h",index, mem[index]), UVM_NONE)
            while (mem.next(index));
        end
    endfunction
    
    virtual function void write(logic [`APB_MAX_ADDR_WIDTH-1:0] addr, logic [`APB_MAX_DATA_WIDTH-1:0] data);
        mem[addr] = data;
        `uvm_info("APB_STORAGE", $sformatf("Write: Addr:0x%0h, Data:0x%0h", addr, data), UVM_LOW)
        display_mem();
        `uvm_info("APB_STORAGE_DBG", $sformatf("mem[0x%0h] = 0x%0h", addr, mem[addr]), UVM_LOW)
    endfunction

    virtual function logic [`APB_MAX_DATA_WIDTH-1:0] read(logic [`APB_MAX_ADDR_WIDTH-1:0] addr);
        `uvm_info("APB_STORAGE", $sformatf("READ: Addr:0x%0h", addr), UVM_LOW)
        if (mem.exists(addr)) begin
            return mem[addr];
        end else begin
            return 32'hDEAD_BEEF;
        end
    endfunction
endclass
`endif
