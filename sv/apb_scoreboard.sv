`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV
class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard);

    uvm_analysis_imp #(apb_item, apb_scoreboard) ap_in;
    apb_predictor predictors[2];

    function new(string name = "apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       ap_in       = new("ap_in",     this);
       for (int i=0; i < 2; i++) begin
           predictors[i] = apb_predictor::type_id::create($sformatf("predictor[%0d]",i), this);
       end
            
   endfunction : build_phase 

   virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
   endfunction : connect_phase

   virtual function void write(apb_item t);
       int slave_id;
       apb_item expected;

       `uvm_info("APB_SCOREBOARD", $sformatf("write() t.paddr: 0x%0h", t.paddr), UVM_LOW)

       // Decode address -> select slave
       if ((t.paddr -`APB_BASE_REGION_ADDR) < 64*1024) begin
           slave_id = 0;
       end else begin
           slave_id = 1;
       end

       `uvm_info("APB_SCOREBOARD", $sformatf("slave_id: %0d", slave_id), UVM_LOW)

       expected = predictors[slave_id].update_and_get_expected(t);

       if (!expected.do_compare(t)) begin
           `uvm_error("APB_SCOREBOARD", $sformatf("Mismatch: expected %0s, got %0s", expected.sprint(), t.sprint()))
       end 
   endfunction

endclass
`endif
