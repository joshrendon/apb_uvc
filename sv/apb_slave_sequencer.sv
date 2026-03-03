`ifndef APB_SLAVE_SEQUENCER_SV
`define APB_SLAVE_SEQUENCER_SV
`timescale 1ns / 1ps
class apb_slave_sequencer extends uvm_sequencer#(apb_item);
    `uvm_component_utils(apb_slave_sequencer)
    
    uvm_analysis_imp #(apb_item, apb_slave_sequencer) request_export;
    uvm_tlm_analysis_fifo #(apb_item) request_fifo;
    apb_slave_config     s_cfg;

    function new(string name="apb_slave_sequencer", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        request_export = new("request_export", this);
        request_fifo = new("request_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction

    virtual function void write(apb_item trans);
        if (s_cfg.check_address_range(trans.paddr)) begin
            `uvm_info("apb_slave_sequencer", $sformatf("Accepted request for addr: 0x%0h", trans.paddr), UVM_LOW)
            request_fifo.analysis_export.write(trans);
        end
    endfunction

endclass
`endif
