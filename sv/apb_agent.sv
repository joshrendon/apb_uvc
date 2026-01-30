`ifndef APB_AGENT_SV
    `define APB_AGENT_SV
    `timescale 1ns / 1ps
    class apb_agent extends uvm_agent;
        `uvm_component_utils(apb_agent)
        apb_monitor          mon;
        apb_master_driver    drv;
        apb_sequencer        seq;
        function new(string name="apb_agent", uvm_component parent=null);
            super.new(name,parent);
        endfunction
    
        virtual function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            mon = apb_monitor::type_id::create("mon", this);
            if (is_active == UVM_ACTIVE) begin
                seq = apb_sequencer::type_id::create("seq", this);
                drv = apb_master_driver::type_id::create("drv", this);
            end
        endfunction
    
        virtual function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            if (is_active == UVM_ACTIVE) begin
                drv.seq_item_port.connect(seq.seq_item_export);
            end
        endfunction
    endclass
`endif
