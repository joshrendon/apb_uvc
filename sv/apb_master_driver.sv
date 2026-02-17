`timescale 1ns / 1ps
class apb_master_driver extends apb_driver;
    `uvm_component_utils(apb_master_driver)
    apb_config cfg;

    function new(string name="apb_master_driver", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(apb_config)::get(this,"", "cfg", cfg))
            `uvm_error("NO_CFG", "Config object not found!")
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        repeat(5) @(vif.master_cb);

        wait(vif.prstn === 1'b1);

        vif.master_cb.psel    <= '0;
        vif.master_cb.penable <= '0;
        vif.master_cb.paddr   <= '0;
        vif.master_cb.pwrite  <= '0;
        vif.master_cb.pwdata  <= '0; // Clear the Z on data bus
        vif.master_cb.pstrb   <= '0;
        super.run_phase(phase);
    endtask : run_phase

    virtual task send_to_dut(apb_item trans);
        int slave_idx = cfg.get_slave_psel_by_addr(trans.paddr);

        int wait_cycles;
        logic [`APB_MAX_DATA_WIDTH-1:0] wdata = 32'b0;
        logic [`APB_MAX_DATA_WIDTH-1:0] rdata = 0;
        logic [`APB_MAX_DATA_WIDTH-1:0] final_wdata = '0;
        //`uvm_info("APB_MASTER_DRIVER", "send_to_dut recieved seq - trans", UVM_LOW)
        `uvm_info("APB_MASTER_DRIVER", $sformatf("send_to_dut() req:\n%s", trans.sprint()), UVM_LOW)
        `uvm_info("APB_MASTER_DRIVER", $sformatf("slave_idx: %0d", slave_idx), UVM_LOW)

        @(vif.master_cb);
        //vif.master_cb.psel    <= trans.psel[slave_idx];
        vif.master_cb.psel[slave_idx]    <= 1'b1;
        vif.master_cb.paddr   <= trans.paddr; 
        vif.master_cb.pwrite  <= trans.pwrite;
        vif.master_cb.pstrb   <= trans.pstrb;
        vif.master_cb.penable <= 1'b0;

        //`uvm_info("DEBUG_DRV", $sformatf("Driving PSEL: %0b for ADDR: %0h", trans.psel, trans.paddr), UVM_LOW)
        `uvm_info("DRV_DEBUG", $sformatf("Mapping ADDR %h to Slave Index %0d", trans.paddr, slave_idx), UVM_LOW)

        if (trans.pwrite) begin
            `uvm_info(get_type_name(), "Write transaction", UVM_HIGH)
            for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                if (trans.pstrb[i]) begin
                    wdata[(i*8) +: 8] = trans.pdata[(i*8) +: 8];
                end
            end
            `uvm_info("APB_MASTER_DRIVER", $sformatf("pdata: 0x%0h, pstrb: 0b%0b, wdata: 0x%0h", trans.pdata, trans.pstrb, wdata), UVM_LOW)
            vif.master_cb.pwdata  <= wdata;
           
        end

        // Transition to the Access Phase
        @(vif.master_cb);
        // Drive enable to high
        vif.master_cb.penable <= 1'b1;

        //void'(std::randomize(wait_cycles) with {wait_cycles inside {[0:5]};});

        //if (wait_cycles > 0) begin
        //    `uvm_info("DRV_WAIT", $sformatf("Inserting %0d wait cycles", wait_cycles), UVM_LOW)
        //    repeat (wait_cycles) @(posedge vif.pclk);
        //end

        while (!vif.master_cb.pready) @(vif.master_cb);

        vif.master_cb.penable <= 1'b0;
        vif.master_cb.psel[slave_idx]    <= 1'b0;
        vif.master_cb.pwrite  <= '0;

        if (!trans.pwrite) begin
            `uvm_info(get_type_name(), "Read transaction", UVM_HIGH)
            trans.pdata  = vif.master_cb.prdata;
            `uvm_info(get_type_name(), $sformatf("Read data from DUT: PRDATA:0x%0h",trans.pdata), UVM_HIGH)
        end
        trans.pslverr = vif.master_cb.pslverr;

        `uvm_info(get_type_name(), "Completed transaction", UVM_HIGH)
    endtask : send_to_dut

endclass
