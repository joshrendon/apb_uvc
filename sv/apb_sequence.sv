class apb_sequence extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_sequence)
    apb_item apb_seq_itm;
  
    function new(string name = "apb_sequence");
      super.new(name);
    endfunction : new

    task body;
      repeat(5)
        begin
	    apb_seq_itm = apb_item::type_id::create("apb_seq_itm");
        assert(apb_seq_itm.randomize());
	    start_item(apb_seq_itm);
	    finish_item(apb_seq_itm);
	   end 
    endtask : body

endclass : apb_sequence

class apb_slave_responder_seq extends uvm_sequence #(apb_item);
    `uvm_object_utils(apb_slave_responder_seq)
    `uvm_declare_p_sequencer(apb_slave_sequencer)

    apb_item req;

    function new(string name="apb_slave_responder_seq");
        super.new(name);
    endfunction

    task body();
        apb_item bus_req;
        `uvm_info("apb_slave_responder_seq", "Starting slave responder seq", UVM_LOW)
        
        forever begin
            logic [`APB_MAX_DATA_WIDTH-1:0] wdata = 32'b0;

            p_sequencer.request_fifo.get(bus_req);

            `uvm_info("SEQ_DEB", $sformatf("bus_req:\n%s", bus_req.sprint()), UVM_LOW)

            req = apb_item::type_id::create("req");
            req.copy(bus_req);
            `uvm_info("SEQ_DEB", $sformatf("req:\n%s", req.sprint()), UVM_LOW)

            //--wait_for_grant();

            //--send_request(req);

            `uvm_info("SEQ_DEBUG", $sformatf("I just woke up. Driver told me the address is 0x%0h", req.paddr), UVM_LOW)
            if (req.pwrite == APB_WRITE) begin
                //TODO: Apply pstrb signals to pdata
                for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                    if (req.pstrb[i]) begin
                        wdata[(i*8) +: 8] = req.pdata[(i*8) +: 8];
                    end
                end
                `uvm_info("SLV_MEM", $sformatf("pdata: 0x%0h, pstrb: 0b%0b, wdata: 0x%0h", req.pdata, req.pstrb, wdata), UVM_LOW)
                   
                //p_sequencer.slave_mem[req.paddr] = req.pdata;
                p_sequencer.slave_mem[req.paddr] = wdata;
                `uvm_info("SLV_MEM", $sformatf("WRITE: Addr=0x%0h, Data=0x%0h, Pstrb=0x%0h", req.paddr, req.pdata, req.pstrb), UVM_LOW)
            end else begin
                if (p_sequencer.slave_mem.exists(req.paddr)) begin
                    req.pdata = p_sequencer.slave_mem[req.paddr];
                end else begin
                    req.pdata = 32'hDEADBEEF;
                end
                `uvm_info("SLV_MEM", $sformatf("READ: Addr=0x%0h, Data=0x%0h", req.paddr, req.pdata), UVM_LOW)
            end

            start_item(req);
            finish_item(req);
            //--wait_for_item_done();
        end
    endtask
endclass

class apb_interleaved_test_seq extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_interleaved_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_interleaved_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_item req;
        apb_item req2;
        
        `uvm_info(get_type_name(), "Starting Interleaved Write/Read Test", UVM_LOW)

        for(int i=1; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b1; });
            //req.paddr  = s0_addr + (i*4);
            //req.pwrite = 1'b1;
            //req.pwdata = $urandom;
            //req.psel   = 2'b01;
            start_item(req);
            finish_item(req);
            //`uvm_do(req)

            // 2. READ from Slave 1 (Back-to-Back)
            req2 = apb_item::type_id::create("req2");
            assert(req2.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b0; });
            //assert(req2.randomize());
            //req2.paddr  = s1_addr + (i*4);
            //req2.pwrite = 1'b0;
            //req2.psel   = 2'b10;
            start_item(req2);
            finish_item(req2);
            //`uvm_do(req2)
        end
    endtask
endclass

class apb_interleaved_read_test_seq extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_interleaved_read_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_interleaved_read_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_item req;
        apb_item req2;
        
        `uvm_info(get_type_name(), "Starting Interleaved Read Test", UVM_LOW)

        for(int i=1; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b0; });
            //req.paddr  = s0_addr + (i*4);
            //req.pwrite = 1'b1;
            //req.pwdata = $urandom;
            //req.psel   = 2'b01;
            start_item(req);
            finish_item(req);
            //`uvm_do(req)

            // 2. READ from Slave 1 (Back-to-Back)
            req2 = apb_item::type_id::create("req2");
            assert(req2.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b0; });
            //assert(req2.randomize());
            //req2.paddr  = s1_addr + (i*4);
            //req2.pwrite = 1'b0;
            //req2.psel   = 2'b10;
            start_item(req2);
            finish_item(req2);
            //`uvm_do(req2)
        end
    endtask
endclass

class apb_wr_test_seq extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_wr_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_wr_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_item req;
        apb_item req2;
        
        `uvm_info(get_type_name(), "Starting WR Test", UVM_LOW)

        for(int i=0; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b1;});
            start_item(req);
            finish_item(req);

        end

        for(int i=0; i<5; i++) begin
            // 1. WRITE to Slave 1
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b1;});
            start_item(req);
            finish_item(req);

        end

        // Read after writing
        for(int i=0; i<5; i++) begin
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b0;});
            start_item(req);
            finish_item(req);

            req2 = apb_item::type_id::create("req2");
            assert(req2.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b0;});
            start_item(req2);
            finish_item(req2);
        end

    endtask
endclass

class apb_reg_test_seq extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_reg_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_1000; // to 32'h4000_101F 

    function new(string name="apb_reg_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_item req;
        apb_item req2;
        
        `uvm_info(get_type_name(), "Starting reg Test", UVM_LOW)

        // Write to Registers starting at REG_BASE_ADDR + (4*i) of slave_S0
        // 'h00 r_leds
        // 'h04 r_rgb
        // 'h08 switches, buttons
        // 'h0C ID
        // 'h10 Scratch
        for(int i=0; i<5; i++) begin
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b1;});
            start_item(req);
            finish_item(req);
        end

        // Then read all registers
        for(int i=0; i<5; i++) begin
            req = apb_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b0;});
            start_item(req);
            finish_item(req);
        end
    endtask
endclass

class apb_ral_test_seq extends uvm_sequence#(apb_item);
    `uvm_object_utils(apb_ral_test_seq)

    apb_reg_block reg_block;

    function new(string name="apb_ral_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        uvm_status_e status;
        uvm_reg_data_t data;
        if (!uvm_config_db#(apb_reg_block)::get(null, get_full_name(), "reg_block", reg_block)) begin
            `uvm_fatal("RAL_GET_ERR", "Could not get reg_model from config_db")
        end

        if (reg_block == null) begin
            `uvm_fatal("RAL_NULL", "The reg_block is null")
        end

        // 1. Verify Reset Value of ID Register
        reg_block.BOARD_ID.read(status, data);
        if (data != 32'hA735_0001)
            `uvm_error("RAL", "ID mismatch!")

        // 2. Test RW on LEDs
        reg_block.GPIO_LEDS.write(status, 4'hF);
        // On FPGA, you'd see LEDs toggle here. In SIM, check waveform.
        
        // 3. Mirror Check (Predictor check)
        // This performs a read and compares it against the 'desired' value in RAL
        reg_block.GPIO_LEDS.mirror(status, UVM_CHECK);
    endtask
endclass
