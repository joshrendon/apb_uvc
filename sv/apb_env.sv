`ifndef APB_ENV_SV
`define APB_ENV_SV
`timescale 1ns / 1ps
class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)

    apb_config                   cfg;
    apb_master_agent             master_agent;
    apb_slave_agent              slave_agents[];
    apb_scoreboard               scb;
    apb_reg_block                reg_block;
    apb_reg_adapter              m_adapter;
    //uvm_reg_predictor#(apb_item) m_predictor;
    apb_reg_predictor            m_predictor;
    apb_bus_monitor              bus_monitor;

    function new(string name="apb_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "APB configuration object not found in config_db")
        end
        if (cfg.master_config != null) begin
            master_agent = apb_master_agent::type_id::create("master_agent", this);
            uvm_config_db#(apb_agent_config)::set(this, "master_agent.*", "cfg", cfg.master_config);
        end

        slave_agents = new[cfg.slave_configs.size()]; // or cfg.num_slaves
        foreach (cfg.slave_configs[i]) begin
            string agent_name = $sformatf("slave_agent_%0d", i);

            slave_agents[i] = apb_slave_agent::type_id::create(agent_name, this);
            uvm_config_db#(apb_agent_config)::set(this, {agent_name, ".*"}, "cfg", cfg.slave_configs[i]);
        end
        scb   = apb_scoreboard::type_id::create("scb", this);
        reg_block = apb_reg_block::type_id::create("reg_block", this);
        uvm_config_db#(apb_reg_block)::set(this, "*", "reg_block", reg_block);
        void'(reg_block.build());
        scb.reg_block = reg_block;

        m_adapter = apb_reg_adapter::type_id::create("m_adapter");
        m_predictor = apb_reg_predictor::type_id::create("m_predictor", this);
        if (cfg.has_bus_monitor) begin
            bus_monitor = apb_bus_monitor::type_id::create("bus_monitor", this);
            uvm_config_db#(apb_config)::set(this, "bus_monitor", "cfg", cfg);
        end

        // Enable RAL model mirror update logging
        uvm_config_db#(string)::set(this, "m_predictor", "verbosity", "UVM_MEDIUM");
        uvm_config_db#(string)::set(this, "reg_block", "verbosity", "UVM_MEDIUM");
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        reg_block.default_map.set_sequencer(master_agent.seq, m_adapter);
        reg_block.default_map.set_auto_predict(0);
        m_predictor.map     = reg_block.default_map;
        m_predictor.adapter = m_adapter;

        // Connect the agent's monitor to the predictor
        if (cfg.has_bus_monitor) begin
            bus_monitor.item_collected_port.connect(scb.ap_in);
            bus_monitor.item_collected_port.connect(m_predictor.ap);

            // Rerouting the bus monitor to the individual slave sequencers
            foreach (slave_agents[i]) begin
                bus_monitor.request_aport.connect(slave_agents[i].seq.request_export);
            end
        end
    endfunction : connect_phase
endclass
`endif
