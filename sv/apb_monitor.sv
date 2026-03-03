`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV
`timescale 1ns / 1ps
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    apb_agent_config  cfg;
    apb_master_config m_cfg;
    apb_slave_config  s_cfg;

    virtual apb_interface vif;
    uvm_analysis_port #(apb_item) item_collected_port;
    uvm_analysis_port #(apb_item) request_aport;
    event sampling_trans;
    apb_item trans;
    
    function new(string name="apb_monitor", uvm_component parent=null);
        super.new(name,parent);
        item_collected_port = new("item_collected_port", this);
        request_aport = new("request_aport", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"vitual interface must be set for ", get_full_name(), ".vif"});
        if (!uvm_config_db#(apb_agent_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "Config not found for monitor")
        end
    
        if (!cfg.is_master) begin
            if(!$cast(s_cfg, cfg)) begin
                `uvm_fatal("apb_monitor", "couldn't cast to s_cfg")
            end
        end

    endfunction

    virtual task run_phase(uvm_phase phase);
        @(vif.monitor_cb);
        forever begin
            collect_transaction();
            @(vif.monitor_cb);
        end 
    endtask : run_phase

    task collect_transaction();
        apb_state_t apb_state;
        apb_logic_data_t wdata = '0;

        //assert(s_cfg != null) else `uvm_fatal("APB_MON","s_cfg is null!")
        //assert($cast(s_cfg, cfg)) else `uvm_fatal("apb_monitor", "couldn't cast to s_cfg")
        
        // 1. Wait for SETUP phase (PSEL must be high, PENABLE is low)
        apb_state = APB_IDLE;
        `uvm_info("apb_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)

        if (cfg.is_master) begin
            @(vif.monitor_cb iff (|vif.monitor_cb.psel));
        end else begin
            @(vif.monitor_cb iff (vif.monitor_cb.psel[s_cfg.psel_index]));
        end

        if (!vif.monitor_cb.penable) begin
            trans = apb_item::type_id::create("trans");
            apb_state = APB_SETUP;
            `uvm_info("apb_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)

            trans.paddr  = vif.monitor_cb.paddr;
            trans.pwrite = apb_direction_t'(vif.monitor_cb.pwrite);
            trans.psel   = vif.monitor_cb.psel;

            if (vif.monitor_cb.pwrite) begin
                trans.pdata = vif.monitor_cb.pwdata;
                trans.pstrb = vif.monitor_cb.pstrb;

                ///if (cfg.addr_map.decode())
                if (trans.psel[s_cfg.psel_index]) begin
                    //Apply pstrb signals to pdata
                    for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                        if (trans.pstrb[i]) begin
                            wdata[(i*8) +: 8] = trans.pdata[(i*8) +: 8];
                        end
                    end
                    cfg.storage.write(trans.paddr, wdata);
                end
            end 
            request_aport.write(trans);

            // Wait for the ACCESS Phase & PREADY
            while (!(vif.monitor_cb.penable && vif.monitor_cb.pready)) @(vif.monitor_cb);
            apb_state = APB_ACCESS;

            // Sample data once PREADY has been recieved
            if (!vif.monitor_cb.pwrite) begin
                trans.pdata = vif.monitor_cb.prdata;
            end 
            trans.pslverr = vif.monitor_cb.pslverr;

            // Send data to the scoreboard
            item_collected_port.write(trans);
            ->sampling_trans;
            `uvm_info("apb_monitor", $sformatf("Collected: %s", trans.sprint()), UVM_LOW)
            `uvm_info("apb_monitor", $sformatf("apb_state: %s", apb_state.name()), UVM_LOW)
        end
    endtask : collect_transaction

endclass
`endif
