`ifndef APB_SLAVE_DRIVER_SV
`define APB_SLAVE_DRIVER_SV
class apb_slave_driver extends apb_driver;
    `uvm_component_utils(apb_slave_driver)
    apb_slave_config s_cfg;

    function new(string name="apb_slave_driver", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction : build_phase

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);

        assert ($cast(s_cfg, agent_cfg) == 1 ) else begin
            `uvm_fatal("APB_SLV_DRV", "Could not cast agent configuration to apb_slave_config")
        end
    endfunction : start_of_simulation_phase

    virtual task run_phase(uvm_phase phase);
        repeat(5) @(vif.slave_cb);

        wait(vif.prstn === 1'b1);

        vif.slave_cb.pready  <= '0;
        vif.slave_cb.pslverr <= '0; // Clear the Z on data bus
        super.run_phase(phase);
    endtask : run_phase

    virtual task send_to_dut(apb_item req);
        vif.slave_cb.pready  <= 1'b0;
        vif.slave_cb.pslverr <= 1'b0;
        vif.slave_cb.prdata  <= 32'h0;
        `uvm_info("APB_SLV_DRV", "Slave selected, awaiting PENABLE", UVM_LOW)

        // Wait on penable
        if (vif.slave_cb.penable !== 1'b1) begin
                @(vif.slave_cb iff (vif.slave_cb.penable === 1'b1));
        end

        //--// Insert wait states (where pready is kept low)
        if (req.wait_cycles > 0) begin
            `uvm_info("APB_SLV_DRV", $sformatf("Inserting %0d wait states", req.wait_cycles), UVM_LOW)
            repeat (req.wait_cycles) begin
                //vif.slave_cb.pready <= 1'b0;
                @(vif.slave_cb);
            end
        end
        
        // Finalize transaction
        if (vif.slave_cb.penable) begin
            `uvm_info("APB_SLV_DRV", $sformatf("received psel %0d driving req:\n%s", s_cfg.psel_index, req.sprint()), UVM_LOW)
            vif.slave_cb.pready <= 1'b1;
            vif.slave_cb.pslverr <= req.pslverr;

            if (vif.slave_cb.pwrite == APB_READ) begin
                 vif.slave_cb.prdata <= req.pdata;
            end
        end

        @(vif.slave_cb);
        vif.slave_cb.pready  <= 1'b0;
        vif.slave_cb.pslverr <= 1'b0;
    endtask
    
endclass
`endif
