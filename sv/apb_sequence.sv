class apb_sequence extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(apb_sequence)
    apb_seq_item apb_seq_itm;
  
    function new(string name = "apb_sequence");
      super.new(name);
    endfunction : new

    task body;
      repeat(5)
        begin
	    apb_seq_itm = apb_seq_item::type_id::create("apb_seq_itm");
        assert(apb_seq_itm.randomize());
	    start_item(apb_seq_itm);
	    finish_item(apb_seq_itm);
	   end 
    endtask : body

endclass : apb_sequence

class apb_interleaved_test_seq extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(apb_interleaved_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_interleaved_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item req;
        apb_seq_item req2;
        
        `uvm_info(get_type_name(), "Starting Interleaved Write/Read Test", UVM_LOW)

        for(int i=1; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_seq_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b1; });
            //req.paddr  = s0_addr + (i*4);
            //req.pwrite = 1'b1;
            //req.pwdata = $urandom;
            //req.psel   = 2'b01;
            start_item(req);
            finish_item(req);
            //`uvm_do(req)

            // 2. READ from Slave 1 (Back-to-Back)
            req2 = apb_seq_item::type_id::create("req2");
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

class apb_interleaved_read_test_seq extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(apb_interleaved_read_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_interleaved_read_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item req;
        apb_seq_item req2;
        
        `uvm_info(get_type_name(), "Starting Interleaved Read Test", UVM_LOW)

        for(int i=1; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_seq_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b0; });
            //req.paddr  = s0_addr + (i*4);
            //req.pwrite = 1'b1;
            //req.pwdata = $urandom;
            //req.psel   = 2'b01;
            start_item(req);
            finish_item(req);
            //`uvm_do(req)

            // 2. READ from Slave 1 (Back-to-Back)
            req2 = apb_seq_item::type_id::create("req2");
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

class apb_wr_test_seq extends uvm_sequence#(apb_seq_item);
    `uvm_object_utils(apb_wr_test_seq)

    // Define address ranges for your slaves (adjust to match your cfg)
    bit [31:0] s0_addr = 32'h4000_0000; 
    bit [31:0] s1_addr = 32'h4001_0000;

    function new(string name="apb_wr_test_seq");
        super.new(name);
    endfunction

    virtual task body();
        apb_seq_item req;
        apb_seq_item req2;
        
        `uvm_info(get_type_name(), "Starting WR Test", UVM_LOW)

        for(int i=0; i<5; i++) begin
            // 1. WRITE to Slave 0
            req = apb_seq_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b1;});
            start_item(req);
            finish_item(req);

        end

        for(int i=0; i<5; i++) begin
            // 1. WRITE to Slave 1
            req = apb_seq_item::type_id::create("req");
            assert(req.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b1;});
            start_item(req);
            finish_item(req);

        end

        // Read after writing
        for(int i=0; i<5; i++) begin
            req = apb_seq_item::type_id::create("req");
            assert(req.randomize() with { paddr == s0_addr + (i*4); psel == 2'b01; pwrite == 1'b0;});
            start_item(req);
            finish_item(req);

            req2 = apb_seq_item::type_id::create("req2");
            assert(req2.randomize() with { paddr == s1_addr + (i*4); psel == 2'b10; pwrite == 1'b0;});
            start_item(req2);
            finish_item(req2);
        end

    endtask
endclass
