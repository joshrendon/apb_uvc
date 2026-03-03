`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV
class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard);

    uvm_analysis_imp #(apb_item, apb_scoreboard) ap_in;
    apb_predictor predictors[];
    apb_config cfg;
    apb_reg_block reg_block;

    function new(string name = "apb_scoreboard", uvm_component parent);
        super.new(name, parent);
    endfunction

   function void build_phase(uvm_phase phase);
       super.build_phase(phase);
       ap_in = new("ap_in", this);

       if (!uvm_config_db#(apb_config)::get(this, "", "cfg", cfg)) begin
           `uvm_fatal("NOCFG", "APB configuration object not found for scoreboard")
       end

       predictors  = new[cfg.slave_configs.size()];
       for (int i=0; i < cfg.slave_configs.size(); i++) begin
           predictors[i] = apb_predictor::type_id::create($sformatf("predictor[%0d]",i), this);
       end
            
   endfunction : build_phase 

   virtual function void connect_phase(uvm_phase phase);
       super.connect_phase(phase);
   endfunction : connect_phase

   virtual function void write(apb_item trans);
       int slave_idx;
       apb_item expected;

       if (cfg != null) begin
          slave_idx = cfg.addr_map.decode(trans.paddr);
       end
       `uvm_info("APB_SCOREBOARD", $sformatf("Checking transaction to slave %0d", slave_idx), UVM_LOW)

       `uvm_info("APB_SCOREBOARD", $sformatf("write() t.paddr: 0x%0h", trans.paddr), UVM_LOW)

       if (trans.paddr == 32'h0) begin
            `uvm_error("APB_SCB_ZERO_ADDR", "Detected access to address 0, likley slave bug")
       end

        // Skip accesses to memory space reserved for CSR registers
        if (trans.paddr >= 32'h4000_1000 && trans.paddr <= 32'h4000_101F) begin
            uvm_reg rg = reg_block.default_map.get_reg_by_offset(trans.paddr - 'h4000_1000);
            `uvm_info("apb_scoreboard", "handing off check to UVM RAL predictor -- access to CSR register space", UVM_LOW)
            if (rg != null && trans.pwrite == APB_READ) begin
                `uvm_info("APB_SCOREBOARD", $sformatf("Bus read 0x%h, RAL mirror has 0x%h", trans.pdata, rg.get_mirrored_value()), UVM_LOW)
                if (rg.get_mirrored_value() != trans.pdata) begin
                     `uvm_error("REG_MISMATCH", $sformatf("Bus read 0x%h, but RAL mirror has 0x%h", trans.pdata, rg.get_mirrored_value()))
                end
            end
            return;
        end

       `uvm_info("APB_SCOREBOARD", $sformatf("slave_idx: %0d", slave_idx), UVM_LOW)
       `uvm_info("APB_SCOREBOARD", "before predictors.update_and_get_expected()", UVM_LOW)

       expected = predictors[slave_idx].update_and_get_expected(trans);
       `uvm_info("APB_SCOREBOARD", $sformatf("expected:\n%s\nrecieved:\n%s",expected, trans), UVM_LOW)

       if (!expected.do_compare(trans)) begin
           `uvm_error("APB_SCOREBOARD", $sformatf("Mismatch: expected %0s, got %0s", expected.sprint(), trans.sprint()))
       end 
   endfunction

endclass
`endif
