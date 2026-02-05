`ifndef APB_ENV_SV
`define APB_ENV_SV
`timescale 1ns / 1ps
class apb_env extends uvm_env;
    `uvm_component_utils(apb_env)
    apb_agent agent;
    apb_scoreboard scb;

    function new(string name="apb_env", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = apb_agent::type_id::create("agent", this);
        scb   = apb_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        //agent.ap.connect(scb.ap_in);
        agent.mon.item_collected_port.connect(scb.ap_in);
    endfunction : connect_phase
endclass
`endif
