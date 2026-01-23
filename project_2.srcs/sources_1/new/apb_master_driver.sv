`timescale 1ns / 1ps
class apb_master_driver extends apb_driver;
    `uvm_component_utils(apb_master_driver)
    apb_agent_config cfg;

    function new(string name="apb_master_driver", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(apb_agent_config)::get(this,"", "cfg", cfg))
            `uvm_error("NO_CFG", "Config object not found!")
    endfunction : build_phase

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

    virtual task send_to_dut(apb_seq_item trans);
        int slave_idx = get_psel_index(trans.paddr);
        `uvm_info("APB_MASTER_DRIVER", "send_to_dut recieved seq - trans", UVM_LOW)
        `uvm_info("APB_MASTER_DRIVER", $sformatf("slave_idx: %0d", slave_idx), UVM_LOW)
        `uvm_info("APB_MASTER_DRIVER", $sformatf("send_to_dut() req:\n%s", trans.sprint()), UVM_LOW)

        // Setup phase
        @(vif.master_cb);
        vif.master_cb.psel    <= trans.psel;
        //vif.master_cb.psel    <= (1 << slave_idx);
        vif.master_cb.paddr   <= trans.paddr; 
        vif.master_cb.pwrite  <= trans.pwrite;
        vif.master_cb.penable <= 1'b0;

        if (trans.pwrite) begin
            `uvm_info(get_type_name(), "Write transaction", UVM_LOW)
            vif.master_cb.pwdata  <= trans.pwdata;
        end
        //end else begin
        //    `uvm_info(get_type_name(), "Read transaction", UVM_LOW)
        //    trans.prdata = vif.master_cb.prdata;
        //    //trans.pslverr = vif.master_cb.pslverr;
        //    `uvm_info(get_type_name(), $sformatf("Read data from DUT: PRDATA:0x%0h",trans.prdata), UVM_LOW)
        //end

        // Access phase 
        @(vif.master_cb);
        vif.master_cb.penable <= 1'b1; // Drive enable to high
        vif.master_cb.psel    <= trans.psel;

        // @ait state logic in access phase
        do begin
           if (vif.master_cb.pready == 1'b1) break;
           @(vif.master_cb);
        end while (1);

        if (trans.pwrite) begin
            `uvm_info(get_type_name(), "Read transaction", UVM_LOW)
            trans.prdata = vif.master_cb.prdata;
            //trans.pslverr = vif.master_cb.pslverr;
            `uvm_info(get_type_name(), $sformatf("Read data from DUT: PRDATA:0x%0h",trans.prdata), UVM_LOW)
        end

        // Cleanup / transition to Idle phase
        vif.master_cb.penable <= 1'b0;
        vif.master_cb.psel    <= 0;
        vif.master_cb.paddr   <= 0;
        vif.master_cb.pwdata  <= 0;
        `uvm_info(get_type_name(), "Completed transaction", UVM_LOW)
    endtask : send_to_dut

    function int get_psel_index(apb_addr_t addr);
        foreach (cfg.slave_start_addr[i]) begin
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("cfg.slave_start_addr[%0d]:0x%0h", i, cfg.slave_start_addr[i]), UVM_LOW)
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("cfg.slave_end_addr[%0d]:0x%0h", i, cfg.slave_end_addr[i]), UVM_LOW)
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("addr: 0x%0h", addr), UVM_LOW)
            if (addr >= cfg.slave_start_addr[i] && addr <= cfg.slave_end_addr[i])
                `uvm_info("APB_MASTER_DRIVER", $sformatf("addr: 0x%0h within slave[%0d] region", addr, i), UVM_LOW)
                `uvm_info("APB_MASTER_DRIVER", $sformatf("returning i: %0d", i), UVM_LOW)
                return i;
        end
        `uvm_error("APB_MASTER_DRIVER", $sformatf("Address %h is not mapped to any slave!", addr))
        return -1;
    endfunction

endclass
