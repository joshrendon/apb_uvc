`ifndef APB_MASTER_AGENT_SV
`define APB_MASTER_AGENT_SV
`timescale 1ns / 1ps
class apb_master_agent extends uvm_agent;
    `uvm_component_utils(apb_master_agent)
    uvm_analysis_port #(apb_item) ap;

    apb_monitor          mon;
    apb_master_driver    drv;
    apb_master_sequencer seq;
    apb_agent_config     cfg;
    apb_master_config    m_cfg;

    function new(string name="apb_master_agent", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(apb_agent_config)::get(this, "*", "cfg", cfg)) begin
            `uvm_error("CFG_NOT_FOUND", "APB_MASTER_CFG not found in uvm_config_db")
        end
        if ($cast(m_cfg, cfg)) begin
            
            is_active = m_cfg.is_active;
            ap = new ("ap", this);
            mon = apb_monitor::type_id::create("mon", this);
            if (is_active == UVM_ACTIVE) begin
                seq = apb_master_sequencer::type_id::create("seq", this);
                drv = apb_master_driver::type_id::create("drv", this);
            end
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seq.seq_item_export);
        end
        mon.item_collected_port.connect(this.ap);
    endfunction
endclass
`endif
