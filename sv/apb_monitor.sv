`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV
`timescale 1ns / 1ps
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_interface vif;
    uvm_analysis_port #(apb_item) item_collected_port;
    event sampling_trans;
    apb_item trans;
    
    function new(string name="apb_monitor", uvm_component parent=null);
        super.new(name,parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"vitual interface must be set for ", get_full_name(), ".vif"});
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            collect_transaction();
        end 
    endtask : run_phase

    task collect_transaction();
        apb_state_t apb_state;

        // 1. Wait for SETUP phase (PSEL must be high, PENABLE is low)
        apb_state = APB_IDLE;
        `uvm_info("apb_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)
        @(vif.monitor_cb);

        if (|vif.monitor_cb.psel && !vif.monitor_cb.penable) begin
            trans = apb_item::type_id::create("trans");
            apb_state = APB_SETUP;
            `uvm_info("apb_monitor", $sformatf("apb_state: %p", apb_state.name()), UVM_LOW)

            trans.paddr  = vif.monitor_cb.paddr;
            trans.pwrite = vif.monitor_cb.pwrite;
            trans.psel   = vif.monitor_cb.psel;

            if (vif.monitor_cb.pwrite) begin
                trans.pwdata = vif.monitor_cb.pwdata;
                trans.pstrb  = vif.monitor_cb.pstrb;
            end 

            // Wait for the ACCESS Phase & PREADY
            do begin
                @(vif.monitor_cb);
            end while (!(vif.monitor_cb.penable && vif.monitor_cb.pready));
            apb_state = APB_ACCESS;

            // Sample data once PREADY has been recieved
            if (!vif.monitor_cb.pwrite) begin
                trans.prdata = vif.monitor_cb.prdata;
            end 
            trans.pslverr = vif.monitor_cb.pslverr;

            // Send data to the scoreboard
            item_collected_port.write(trans);
            ->sampling_trans;
            //`uvm_info("apb_monitor", $sformatf("Collected: %s", trans.convert2string()), UVM_LOW)
            `uvm_info("apb_monitor", $sformatf("Collected: %s", trans.sprint()), UVM_LOW)
            `uvm_info("apb_monitor", $sformatf("apb_state: %s", apb_state.name()), UVM_LOW)
        end
    endtask : collect_transaction

endclass
`endif
