`ifndef APB_AGENT_CONFIG_SV
`define APB_AGENT_CONFIG_SV

typedef struct {
    apb_addr_t start_addr;
    apb_addr_t end_addr;
    int        psel;
} apb_map_entry_t;

class apb_addr_map extends uvm_object;
    `uvm_object_utils(apb_addr_map);

    apb_map_entry_t entries[$];

    function new(string name = "apb_addr_map");
        super.new(name);
    endfunction
    
    virtual function void add_entry(apb_addr_t start_addr, apb_addr_t end_addr, int psel);
        entries.push_back('{start_addr, end_addr, psel});
    endfunction

    virtual function int decode(apb_addr_t addr);
        foreach (entries[i]) begin
            if (addr >= entries[i].start_addr && addr <= entries[i].end_addr) begin
                return entries[i].psel;
            end
        end
        return -1;
    endfunction
endclass

class apb_agent_config extends uvm_object;
    string                       name;
    rand apb_addr_t              start_address;
    rand apb_addr_t              end_address;
    rand uvm_active_passive_enum is_active;

    int unsigned num_select_lines = 1;
    bit is_master = 0;
    bit has_coverage = 0;
    bit has_bus_monitor = 0;

    // Handles to shared storage and addr_map
    apb_storage  storage;
    apb_addr_map addr_map;

    `uvm_object_utils_begin(apb_agent_config);
        `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
        `uvm_field_int(start_address,                       UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(end_address,                         UVM_HEX | UVM_DEFAULT)
        `uvm_field_int(num_select_lines,                    UVM_DEFAULT)
        `uvm_field_int(has_coverage,                        UVM_DEFAULT)
        `uvm_field_object(storage,                          UVM_DEFAULT)
        `uvm_field_object(addr_map,                         UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_agent_config");
        super.new(name);
    endfunction

    function bit check_address_range(apb_addr_t addr);
        return ((addr >= start_address) && (addr <= end_address));
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

    // Singletons shared by all agents
    apb_storage storage;
    apb_addr_map addr_map;

    `uvm_object_utils_begin(apb_config)
        `uvm_field_object(master_config,       UVM_DEFAULT)
        `uvm_field_queue_object(slave_configs, UVM_DEFAULT)
        `uvm_field_int(has_bus_monitor,        UVM_DEFAULT)
        `uvm_field_int(num_slaves,             UVM_DEFAULT)
        `uvm_field_object(storage,             UVM_DEFAULT)
        `uvm_field_object(addr_map,            UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name = "apb_config");
        super.new(name);
        storage = apb_storage::type_id::create("storage");
        addr_map = apb_addr_map::type_id::create("addr_map");
    endfunction

    extern function void add_slave(string name, apb_addr_t start_address, apb_addr_t end_address, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function void add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    extern function int get_slave_psel_by_addr(apb_addr_t address);
    extern function string get_slave_name_by_addr(apb_addr_t address);
endclass

function void apb_config::add_slave(string name, apb_addr_t start_address, apb_addr_t end_address, int psel_index, uvm_active_passive_enum is_active=UVM_ACTIVE);
    apb_slave_config s_cfg;
    s_cfg = apb_slave_config::type_id::create("s_cfg");
    s_cfg.name = name;
    s_cfg.start_address = start_address;
    s_cfg.end_address   = end_address;
    s_cfg.psel_index    = psel_index;
    s_cfg.is_active     = is_active;
    s_cfg.is_master     = 0;
    s_cfg.storage       = this.storage;
    s_cfg.addr_map      = this.addr_map;
    this.addr_map.add_entry(start_address, end_address, psel_index);
    this.num_slaves++;
    `uvm_info("apb_config", $sformatf("slv_cfg.storage: %s", s_cfg.storage.sprint()), UVM_NONE)
    `uvm_info("apb_config", $sformatf("slv_cfg.addr_map: %s", s_cfg.addr_map.sprint()), UVM_NONE)
    slave_configs.push_back(s_cfg);
endfunction : add_slave

function void apb_config::add_master(string name, uvm_active_passive_enum is_active=UVM_ACTIVE);
    this.master_config = apb_master_config::type_id::create("master_config");
    master_config.name      = name;
    master_config.is_master = 1;
    master_config.is_active = is_active;
    master_config.storage   = this.storage;
    master_config.addr_map  = this.addr_map;
    master_config.num_select_lines = master_config.num_select_lines << 1;
    `uvm_info("apb_config", $sformatf("mst_cfg.storage: %s", master_config.storage.sprint()), UVM_NONE)
    `uvm_info("apb_config", $sformatf("mst_cfg.addr_map: %s", master_config.addr_map.sprint()), UVM_NONE)
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
