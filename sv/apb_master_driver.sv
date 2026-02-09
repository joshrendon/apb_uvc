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
        @(vif.master_cb);
        vif.master_cb.psel    <= '0;
        vif.master_cb.penable <= '0;
        vif.master_cb.paddr   <= '0;
        vif.master_cb.pwrite  <= '0;
        vif.master_cb.pwdata  <= '0; // Clear the Z on data bus
        vif.master_cb.pstrb   <= '0;
        super.run_phase(phase);
    endtask : run_phase

    virtual task send_to_dut(apb_seq_item trans);
        int slave_idx = get_psel_index(trans.paddr);
        logic [`APB_MAX_DATA_WIDTH-1:0] wdata = 32'b0;
        logic [`APB_MAX_DATA_WIDTH-1:0] rdata = 0;
        logic [`APB_MAX_DATA_WIDTH-1:0] final_wdata = '0;
        //`uvm_info("APB_MASTER_DRIVER", "send_to_dut recieved seq - trans", UVM_LOW)
        //`uvm_info("APB_MASTER_DRIVER", $sformatf("slave_idx: %0d", slave_idx), UVM_LOW)
        `uvm_info("APB_MASTER_DRIVER", $sformatf("send_to_dut() req:\n%s", trans.sprint()), UVM_LOW)

        @(vif.master_cb);
        vif.master_cb.psel    <= trans.psel;
        vif.master_cb.paddr   <= trans.paddr; 
        vif.master_cb.pwrite  <= trans.pwrite;
        vif.master_cb.pstrb   <= trans.pstrb;
        vif.master_cb.penable <= 1'b0;

        //`uvm_info("DEBUG_DRV", $sformatf("Driving PSEL: %0b for ADDR: %0h", trans.psel, trans.paddr), UVM_LOW)

        if (trans.pwrite) begin
            `uvm_info(get_type_name(), "Write transaction", UVM_HIGH)
            for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                if (trans.pstrb[i]) begin
                    wdata[(i*8) +: 8] = trans.pwdata[(i*8) +: 8];
                end
            end
            `uvm_info("APB_MASTER_DRIVER", $sformatf("pwdata: 0x%0h, pstrb: 0b%0b, wdata: 0x%0h", trans.pwdata, trans.pstrb, wdata), UVM_LOW)
            vif.master_cb.pwdata  <= wdata;
           
        end
        //end else begin
        //    `uvm_info(get_type_name(), "Read transaction", UVM_HIGH)
        //    vif.master_cb.pwdata  <= 0;
        //    trans.prdata  = vif.master_cb.prdata;
        //    trans.pslverr = vif.master_cb.pslverr;
        //    `uvm_info(get_type_name(), $sformatf("Read data from DUT: PRDATA:0x%0h",trans.prdata), UVM_HIGH)
        //end

        @(vif.master_cb);
        // Drive enable to high
        vif.master_cb.penable <= 1'b1;

        do
            @(vif.master_cb);
        while (!vif.master_cb.pready);

        if (!trans.pwrite) begin
            `uvm_info(get_type_name(), "Read transaction", UVM_HIGH)
            vif.master_cb.pwdata  <= 32'b0;
            trans.prdata  = vif.master_cb.prdata;
            `uvm_info(get_type_name(), $sformatf("Read data from DUT: PRDATA:0x%0h",trans.prdata), UVM_HIGH)
        end
        trans.pslverr = vif.master_cb.pslverr;

        `uvm_info(get_type_name(), "Completed transaction", UVM_HIGH)
    endtask : send_to_dut

    function int get_psel_index(apb_addr_t addr);
        foreach (cfg.slave_start_addr[i]) begin
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("cfg.slave_start_addr[%0d]:0x%0h", i, cfg.slave_start_addr[i]), UVM_LOW)
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("cfg.slave_end_addr[%0d]:0x%0h", i, cfg.slave_end_addr[i]), UVM_LOW)
            //`uvm_info("APB_MASTER_DRIVER", $sformatf("addr: 0x%0h", addr), UVM_LOW)
            if (addr >= cfg.slave_start_addr[i] && addr <= cfg.slave_end_addr[i])
                `uvm_info("APB_MASTER_DRIVER", $sformatf("addr: 0x%0h within slave[%0d] region", addr, i), UVM_HIGH)
                `uvm_info("APB_MASTER_DRIVER", $sformatf("returning i: %0d", i), UVM_HIGH)
                return i;
        end
        `uvm_error("APB_MASTER_DRIVER", $sformatf("Address %h is not mapped to any slave!", addr))
        return -1;
    endfunction

endclass
