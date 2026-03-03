`ifndef APB_SLAVE_AGENT_SV
`define APB_SLAVE_AGENT_SV
class apb_slave_agent extends uvm_agent;
    `uvm_component_utils(apb_slave_agent)
    uvm_analysis_port #(apb_item) ap;

    apb_slave_driver     drv;
    apb_slave_sequencer  seq;
    apb_agent_config     cfg;
    apb_slave_config     s_cfg;

    function new(string name="apb_slave_agent", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(apb_agent_config)::get(this, "*", "cfg", cfg)) begin
            `uvm_error("CFG_NOT_FOUND", "APB_CFG not found in uvm_config_db")
        end

        if (!$cast(s_cfg, cfg)) begin
            `uvm_fatal("apb_slave_agent", "Config object is not of type apb_slave_config")
        end

        if (s_cfg.storage == null ) begin
            `uvm_fatal("STORAGE_NULL", "Storage handle is still null in agent!")
        end

        if (s_cfg.addr_map == null ) begin
            `uvm_fatal("ADDR_MAP_NULL", "ADDR_MAP handle is still null in agent!")
        end
        is_active = s_cfg.is_active;
        ap = new ("ap", this);
        if (s_cfg.is_active == UVM_ACTIVE) begin
            seq = apb_slave_sequencer::type_id::create("seq", this);
            drv = apb_slave_driver::type_id::create("drv", this);
            seq.s_cfg = s_cfg; // pass the s_cfg handle down to the sequencer
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (s_cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seq.seq_item_export);
        end
    endfunction
endclass
`endif

