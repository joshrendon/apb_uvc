`ifndef APB_REG_ADAPTER_SV
`define APB_REG_ADAPTER_SV
class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)

    function new(string name="apb_reg_adapter");
        super.new(name);
        supports_byte_enable = 1;
        provides_responses = 0;
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_item item = apb_item::type_id::create("item");
        item.paddr = rw.addr;
        item.pwrite = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
        item.pdata  = rw.data;
        item.psel   = 2'b01; // Hardcoded to SLV0 for now
        item.pstrb  = 4'hf; 
        return item;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_item item;
        if (!$cast(item, bus_item)) begin
            `uvm_fatal("ADAPTER", "Provided bus_item is not of type apb_item")
        end
        rw.kind = (item.pwrite == APB_WRITE) ? UVM_WRITE : UVM_READ;
        rw.data = item.pdata;
        rw.addr = item.paddr;
        rw.status = UVM_IS_OK;
    endfunction
    
endclass
`endif
