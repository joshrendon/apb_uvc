`ifndef APB_SLAVE_AGENT_SV
`define APB_SLAVE_AGENT_SV
`timescale 1ns / 1ps
class apb_slave_agent extends uvm_agent;
    `uvm_component_utils(apb_slave_agent)
    uvm_analysis_port #(apb_item) ap;

    apb_monitor          mon;
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
            `uvm_error("CFG_NOT_FOUND", "APB_SLAVE_CFG not found in uvm_config_db")
        end
        //uvm_config_db#(apb_slave_config)::set(this, "*", "cfg", cfg);

        if ($cast(s_cfg, cfg)) begin
            is_active = s_cfg.is_active;
            ap = new ("ap", this);
            mon = apb_monitor::type_id::create("mon", this);
            if (cfg.is_active == UVM_ACTIVE) begin
                seq = apb_slave_sequencer::type_id::create("seq", this);
                drv = apb_slave_driver::type_id::create("drv", this);
            end
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (s_cfg.is_active == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seq.seq_item_export);
        end
        mon.item_collected_port.connect(this.ap);
    endfunction
endclass
`endif

