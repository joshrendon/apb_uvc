`ifndef APB_AGENT_CONFIG_SV
`define APB_AGENT_CONFIG_SV

class apb_agent_config extends uvm_object;
    string                       name;
    rand apb_addr_t              start_address;
    rand apb_addr_t              end_address;
    rand uvm_active_passive_enum is_active;
    int no_select_lines = 1;
    bit is_master = 0;

    `uvm_object_utils_begin(apb_agent_config);
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
        `uvm_field_int(start_address,                       UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(end_address,                         UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(no_select_lines,                     UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_agent_config");
        super.new(name);
    endfunction

    function bit check_address_range(apb_addr_t addr);
        return (!((start_address > addr) || (end_address < addr)));
    endfunction

    constraint addr_const {
        start_address < end_address;
    }
endclass

class apb_slave_config extends apb_agent_config;

    // Identifies the select line used by an APB slave controlled and/or observed
    // by the APB agent.
    rand int psel_index; 

    `uvm_object_utils_begin(apb_slave_config);
        `uvm_field_int(psel_index,                       UVM_DEFAULT)
        `uvm_field_int(is_master,                        UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_slave_config");
        super.new(name);
        is_master = 0;
    endfunction

    constraint psel_const {
        psel_index inside {[0:15]};
    }

    function int get_psel();
        return psel_index;
    endfunction
    
endclass

class apb_master_config extends apb_agent_config;

    `uvm_object_utils_begin(apb_master_config)
        `uvm_field_int(is_master, UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name="apb_master_config");
        super.new(name);
        is_master = 1;
    endfunction
    
endclass

class apb_config extends uvm_object;

    rand apb_master_config master_config;
    rand apb_slave_config  slave_configs[$];
    rand bit has_bus_monitor = 1;
    rand int num_slaves;

    `uvm_object_utils_begin(apb_config)
        `uvm_field_object(master_config,       UVM_DEFAULT)
        `uvm_field_queue_object(slave_configs, UVM_DEFAULT)
        `uvm_field_int(has_bus_monitor,        UVM_DEFAULT)
        `uvm_field_int(num_slaves,             UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_config");
        super.new(name);
    endfunction

    extern function void add_slave(string name, apb_addr_t start_address, apb_addr_t end_address, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function void add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function int get_slave_psel_by_addr(apb_addr_t address);
    extern function string get_slave_name_by_addr(apb_addr_t address);

endclass

function void apb_config::add_slave(string name, apb_addr_t start_address, apb_addr_t end_address, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    apb_slave_config tmp_cfg;
    num_slaves++;
    tmp_cfg = apb_slave_config::type_id::create("tmp_cfg");
    tmp_cfg.name = name;
    tmp_cfg.start_address = start_address;
    tmp_cfg.end_address   = end_address;
    tmp_cfg.psel_index    = psel_index;
    tmp_cfg.is_active     = is_active;
    tmp_cfg.is_master     = 0;
    slave_configs.push_back(tmp_cfg);
endfunction : add_slave

function void apb_config::add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    this.master_config = apb_master_config::type_id::create("master_config");
    master_config.name      = name;
    master_config.is_master = 1;
    master_config.is_active = is_active;
    master_config.no_select_lines++;
endfunction : add_master

function int apb_config::get_slave_psel_by_addr(apb_addr_t address);
    for (int i = 0; i < num_slaves; i++) begin
        if (slave_configs[i].check_address_range(address)) begin
            return slave_configs[i].psel_index;
        end
    end
    return -1;
endfunction : get_slave_psel_by_addr

function string apb_config::get_slave_name_by_addr(apb_addr_t address);
    for (int i = 0; i < num_slaves; i++) begin
        if (slave_configs[i].check_address_range(address)) begin
            return slave_configs[i].name;
        end
    end
    return "";
endfunction : get_slave_name_by_addr


class default_apb_config extends apb_config;
    `uvm_object_utils(default_apb_config)
    function new(string name="default_apb_config");
        super.new(name);
        add_master("master", UVM_ACTIVE);
        add_slave("slave0", 32'h4000_0000, 32'h4000_FFFF, 0, UVM_ACTIVE);
        add_slave("slave1", 32'h4001_0000, 32'h4001_FFFF, 1, UVM_ACTIVE);
    endfunction
endclass
`endif
