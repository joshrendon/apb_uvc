`ifndef APB_AGENT_CONFIG_SV
`define APB_AGENT_CONFIG_SV
class apb_agent_config extends uvm_object;
    `uvm_object_utils_begin(apb_agent_config)
        `uvm_field_sarray_int(slave_start_addr, UVM_HEX | UVM_ALL_ON)
        `uvm_field_sarray_int(slave_end_addr,   UVM_HEX | UVM_ALL_ON)
    `uvm_object_utils_end

    apb_addr_t slave_start_addr[] = '{32'h4000_0000, 32'h4001_0000}; //Each region is 64KB = 65,536 Bytes
    apb_addr_t slave_end_addr[]   = '{32'h4000_FFFF, 32'h4001_FFFF};

    function new(string name = "apb_agent_config");
        super.new(name);
    endfunction

    
endclass
`endif
