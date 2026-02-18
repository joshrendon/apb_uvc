`timescale 1ns / 1ps
class apb_driver extends uvm_driver #(apb_item);
    `uvm_component_utils(apb_driver)
    apb_agent_config      agent_cfg;
    apb_item req;
    virtual apb_interface vif;

    function new(string name="apb_driver", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_interface)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"vitual interface must be set for ", get_full_name(), ".vif"});
        if(!uvm_config_db#(apb_agent_config)::get(this, "", "cfg", agent_cfg))
            `uvm_error("NO_CFG", "apb_slave_config object not found!")
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);

            send_to_dut(req);

            seq_item_port.item_done();
        end
    endtask : run_phase

    virtual task send_to_dut(apb_item trans);
        `uvm_fatal("ABSTRACT", "send_to_dut() must be implemented in a subclass.")
    endtask : send_to_dut

endclass
