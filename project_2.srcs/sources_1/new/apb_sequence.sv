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
