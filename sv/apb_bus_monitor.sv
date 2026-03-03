`ifndef APB_BUS_MONITOR_SV
`define APB_BUS_MONITOR_SV
`timescale 1ns / 1ps
class apb_bus_monitor extends uvm_monitor;
    `uvm_component_utils(apb_bus_monitor)

    apb_config  cfg;

    virtual apb_interface vif;
    uvm_analysis_port #(apb_item) item_collected_port;
    uvm_analysis_port #(apb_item) request_aport;

    // State tracking for B2B detection and transaction sequencing
    bit last_transaction_completed;
    bit prev_psel_active;
    bit [`APB_MAX_SEL_WIDTH-1:0] prev_psel_value;
    apb_state_t previous_state;

    function new(string name="apb_bus_monitor", uvm_component parent);
        super.new(name,parent);
        item_collected_port = new("item_collected_port", this);
        request_aport = new("request_aport", this);
        last_transaction_completed = 0;
        prev_psel_active = 0;
        prev_psel_value = '0;
        previous_state = APB_IDLE;
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"vitual interface must be set for ", get_full_name(), ".vif"});
        if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
            `uvm_fatal("NOCFG", "apb_cfg not found for monitor")
        end

    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);

        if (cfg.addr_map == null) begin
            `uvm_fatal("ADDR_MAP_NULL", "ADDR_MAP handle is still null in bus_monitor!")
        end
    endfunction : start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transaction();
        end
    endtask : run_phase

    task collect_transaction();
        apb_state_t apb_state;
        apb_item trans;
        int psel_idx;
        apb_logic_data_t wdata;
        wdata = '0;

        // Wait for any slave to be selected
        apb_state = APB_IDLE;
        `uvm_info("apb_bus_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)
        @(vif.monitor_cb iff (|vif.monitor_cb.psel && !vif.monitor_cb.penable));

        trans = apb_item::type_id::create("trans");
        apb_state = APB_SETUP;

        trans.paddr  = vif.monitor_cb.paddr;
        trans.pwrite = apb_direction_t'(vif.monitor_cb.pwrite);
        trans.psel   = vif.monitor_cb.psel;
        trans.active_psel = vif.monitor_cb.psel;
        assert(cfg != null) else `uvm_fatal("apb_bus_monitor", "cfg null!")
        assert(cfg.addr_map != null) else `uvm_fatal("apb_bus_monitor", "cfg.addr_map null!")
        psel_idx     = cfg.addr_map.decode(trans.paddr);

       `uvm_info("apb_bus_monitor", $sformatf("psel_index: %0d", psel_idx), UVM_LOW)

        // ========================================================================
        // B2B Detection Logic
        // ========================================================================
        // Detect back-to-back transactions:
        // - Previous transaction completed
        // - Current transaction starts immediately (no idle cycles)
        // - Track if same slave or different slave
        // ========================================================================
        if (last_transaction_completed && prev_psel_active) begin
            trans.is_b2b = 1;
            `uvm_info("APB_B2B", $sformatf("B2B transaction detected! Prev PSEL: %b, Current PSEL: %b", 
                prev_psel_value, trans.psel), UVM_LOW);

            if (prev_psel_value == trans.psel) begin
                `uvm_info("APB_B2B", "B2B: Same slave accessed back-to-back", UVM_LOW);
            end else begin
                `uvm_info("APB_B2B", "B2B: Different slaves accessed back-to-back", UVM_LOW);
            end
        end else begin
            trans.is_b2b = 0;
        end

        // Update previous transaction tracking
        prev_psel_value = trans.psel;
        prev_psel_active = 1;

        if (psel_idx == -1) begin
            `uvm_error("UNMAPPED_ACCESS", $sformatf("access to unampped address: 0x%0h", trans.paddr))
        end

        if (vif.monitor_cb.pwrite) begin
            trans.pdata = vif.monitor_cb.pwdata;
            trans.pstrb = vif.monitor_cb.pstrb;

            if (trans.psel[psel_idx]) begin
                for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                    if (trans.pstrb[i]) begin
                        wdata[(i*8) +: 8] = trans.pdata[(i*8) +: 8];
                    end
                end
                assert(cfg.storage != null) else `uvm_fatal("apb_bus_monitor", "cfg.storage null!")
                cfg.storage.write(trans.paddr, wdata);
            end
        end
        `uvm_info("apb_bus_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)
        begin
            apb_item clone_req;
            $cast(clone_req, trans.clone());
            assert(clone_req != null) else `uvm_fatal("apb_bus_monitor", "clone_req went null fail clone")
            request_aport.write(clone_req);
        end
        assert(trans != null) else `uvm_fatal("apb_bus_monitor", "trans went fatal after write to request_aport")

        // Wait for the access phase ot complete
        @(vif.monitor_cb iff(vif.monitor_cb.pready));
        apb_state = APB_ACCESS;

        // Sample data once PREADY has been recieved
        if (trans.pwrite == APB_READ) begin
            trans.pdata = vif.monitor_cb.prdata;
        end 
        trans.pslverr = vif.monitor_cb.pslverr;
        `uvm_info("apb_bus_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)

        // Send data to the scoreboard
        //--begin : write_item_collected_port
        //--    `uvm_info("apb_bus_monitor", "inside branch write_item_collected_port", UVM_LOW)
        //--    apb_item clone_done;
        //--    $cast(clone_done, trans.clone());
        //--    item_collected_port.write(clone_done);
        //--end
        // Send data to the scoreboard
        begin : write_item_collected_port
            apb_item clone_done;
            uvm_object tmp_obj;

            `uvm_info("MON_DBG", "Checking block handles...", UVM_LOW)

            // 1. Check if trans itself is null
            if (trans == null) 
                `uvm_fatal("MON_NULL", "trans is NULL before cloning!")

            // 2. Check if the port is null
            if (item_collected_port == null) 
                `uvm_fatal("MON_NULL", "item_collected_port is NULL!")

            // 3. Attempt clone and check result
            tmp_obj = trans.clone();
            if (tmp_obj == null) 
                `uvm_fatal("MON_NULL", "trans.clone() returned NULL!")

            // 4. Attempt cast and check result
            if (!$cast(clone_done, tmp_obj))
                `uvm_fatal("MON_CAST", "Failed to cast cloned object to apb_item!")

            `uvm_info("MON_DBG", $sformatf("Calling write() on port with handle @%0d", clone_done.get_inst_id()), UVM_LOW)

            item_collected_port.write(clone_done);

            `uvm_info("MON_DBG", "write() completed successfully", UVM_LOW)
        end : write_item_collected_port

        // Mark transaction as completed
        last_transaction_completed = 1;

        `uvm_info("apb_bus_monitor", $sformatf("Collected: %s", trans.sprint()), UVM_LOW)
    endtask : collect_transaction

endclass
`endif
