class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)
    function new(string name="apb_reg_adapter");
        super.new(name);
    endfunction

    virtual function uvm_sequence_item reg2bus(const erf uvm_reg_bus_op rw);
        apb_seq_item item = apb_seq_item::type_id::create("item");
        item.paddr = rw.addr;
        item.pwrite = (rw.kind == UVM_WRITE);
        item.pwdata = rw.data;
        return item;
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_seq_item item;
        if (!$cast(item, bus_item)) begin
            `uvm_fatal("ADAPTER", "Provided bus_item is not of type apb_seq_item")
        end
        rw.kind = item.pwrite ? UVM_WRITE : UVM_READ;
        rw.addr = item.paddr;
        rw.data = item.pwdata; //or prdata
        rw.status = UVM_IS_OK;
    endfunction
    
endclass
