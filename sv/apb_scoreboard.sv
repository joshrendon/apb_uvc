`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV
class apb_scoreboard extends uvm_scoreboard;
    
    `uvm_component_utils(apb_scoreboard);

    uvm_analysis_export #(apb_item)   item_export;
    uvm_tlm_analysis_fifo #(apb_item) ap_fifo;

    apb_item exp_packet;
    apb_item act_packet;

    apb_item items[$];

    function new(string name = "apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       item_export = new("item_export", this);
       ap_fifo     = new("ap_fifo",     this);
   endfunction : build_phase 

   virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
       // Connect analysis export to analysis fifo
       item_export.connect(ap_fifo.analysis_export);
   endfunction : connect_phase

   virtual task run_phase(uvm_phase phase);
       forever begin
           ap_fifo.get(act_packet);
           `uvm_info("apb_scoreboard", $sformatf("Comparison starting for Addr: 0x%0h", act_packet.paddr), UVM_LOW)
           check_data(act_packet);
       end 
   endtask : run_phase

   function void check_data(apb_item tr);

   endfunction

endclass
`endif
