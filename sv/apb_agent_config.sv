`ifndef APB_AGENT_CONFIG_SV
`define APB_AGENT_CONFIG_SV
class apb_slave_config extends uvm_object;
    
    string                       name;
    rand apb_addr_t              start_address; // = 32'h4000_0000;
    rand apb_addr_t              end_address;   // = 32'h4000_FFFF;
    rand uvm_active_passive_enum is_active;

    // Identifies the select line used by an APB slave controlled and/or observed
    // by the APB agent.
    rand int psel_index; 

    `uvm_object_utils_begin(apb_slave_config);
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
        `uvm_field_int(start_address,                    UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(end_address,                      UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(psel_index,                       UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_slave_config");
        super.new(name);
    endfunction

    function bit check_address_range(apb_addr_t addr);
        return (!((start_address > addr) || (end_addr < addr)))
    endfunction

    constraint addr_const {
        start_address > end_address;
    }
    constraint psel_const {
        psel_index inside [0:15];
    }
    
endclass

class apb_master_config extends uvm_object;
    string                       name;
    rand uvm_active_passive_enum is_active;

    // Variable: no_select_lines
    // Identifies the number of select lines used in the APB bus interface.
    rand int no_select_lines = 1;

    `uvm_object_utils_begin(apb_master_config)
        `uvm_field_string(name, UVM_ALL_ON)
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
        `uvm_field_int(no_select_lines, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name="apb_master_config");
        super.new(name);
    endfunction
    
endclass

class apb_agent_config extends uvm_object;

    rand apb_master_config master_config;
    rand apb_slave_config  slave_configs[$];
    rand bit has_bus_monitor = 1;
    rand int num_slaves;

    `uvm_object_utils_begin(apb_agent_config)
        `uvm_field_object(master_config,       UVM_DEFAULT)
        `uvm_field_queue_object(slave_configs, UVM_DEFAULT)
        `uvm_field_int(has_bus_monitor,        UVM_DEFAULT)
        `uvm_field_int(num_slaves,             UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_agent_config");
        super.new(name);
    endfunction

    extern function void add_slave(string name, apb_addr_t start_addr, apb_addr_t end_addr, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function void add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function int get_slave_psel_by_addr(apb_addr_t addr);
    extern function string get_slave_name_by_addr(apb_addr_t addr);

endclass

function void apb_agent_config::add_slave(string name, apb_addr_t start_addr, apb_addr_t end_addr, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    apb_slave_config tmp_cfg;
    num_slaves++;
    tmp_cfg = apb_slave_config::type_id::create("tmp_cfg");
    tmp_cfg.name = name;
    tmp_cfg.start_addr = start_addr;
    tmp_cfg.end_addr   = end_addr;
    tmp_cfg.psel_index = psel_index;
    tmp_cfg.is_active  = is_active;
    slave_configs.push_back(tmp_cfg);
endfunction : add_slave

function void apb_agent_config::add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    this.master_config = apb_master_config::type_id::create("master_config");
    master_config.name      = name;
    master_config.is_active = is_active;
endfunction : add_master

function int apb_agent_config::get_slave_psel_by_addr(apb_addr_t addr);
    for (int i = 0; i < num_slaves; i++) begin
        if (slave_configs[i].check_address_range(addr)) begin
            return slave_configs[i].psel_index;
        end
    end
endfunction : get_slave_psel_by_addr

function int apb_agent_config::get_slave_name_by_addr(apb_addr_t addr);
    for (int i = 0; i < num_slaves; i++) begin
        if (slave_configs[i].check_address_range(addr)) begin
            return slave_configs[i].name;
        end
    end
endfunction : get_slave_name_by_addr


class default_apb_config extends apb_config;
`endif
