`ifndef APB_REG_BLOCK_SV
`define APB_REG_BLOCK_SV
class reg_leds extends uvm_reg;
    `uvm_object_utils(reg_leds)

    rand uvm_reg_field leds;

    function new(string name = "reg_leds");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        leds = uvm_reg_field::type_id::create("leds");
        //parent, size, lsb_pos, access, volatile, resetval, has_reset,
        //is_rand, individually_accessible
        leds.configure(this, 4, 0, "RW", 0, 4'h0, 1, 1, 0);
    endfunction
endclass

class reg_inputs extends uvm_reg;
    `uvm_object_utils(reg_inputs)

    uvm_reg_field btns;
    uvm_reg_field sws;

    function new(string name = "reg_inputs");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        btns = uvm_reg_field::type_id::create("btns");
        btns.configure(this, 4, 0, "RO", 0, 4'h0, 1, 0, 0);
        //parent, size, lsb_pos, access, volatile, resetval, has_reset,
        //is_rand, individually_accessible
        sws  = uvm_reg_field::type_id::create("sws");
        sws.configure(this, 4, 4, "RO", 0, 4'h0, 1, 0, 0);
    endfunction
endclass

class reg_id extends uvm_reg;
    `uvm_object_utils(reg_id)

    uvm_reg_field id_val;

    function new(string name = "reg_id");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        id_val = uvm_reg_field::type_id::create("id_val");
        id_val.configure(this, 32, 0, "RO", 0, 32'hA735_0001, 1, 0, 1);
    endfunction
endclass

class apb_reg_block extends uvm_reg_block;
    `uvm_object_utils(apb_reg_block)
    rand reg_leds  GPIO_LEDS;   // @ offset 0x00
    reg_inputs     GPIO_INPUTS; // @ offset 0x08
    reg_id         BOARD_ID;    // @ offset 0x0C
    rand uvm_reg   SCRATCH;

    function new(string name = "apb_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function build();
        default_map = create_map("default_map", 'h4000_1000, 4, UVM_LITTLE_ENDIAN);

        GPIO_LEDS = reg_leds::type_id::create("GPIO_LEDS");
        GPIO_LEDS.configure(this);
        GPIO_LEDS.build();
        default_map.add_reg(GPIO_LEDS, 'h00, "RW");

        GPIO_INPUTS = reg_inputs::type_id::create("GPIO_INPUTS");
        GPIO_INPUTS.configure(this);
        GPIO_INPUTS.build();
        default_map.add_reg(GPIO_INPUTS, 'h08, "RO");

        BOARD_ID = reg_id::type_id::create("BOARD_ID");
        BOARD_ID.configure(this);
        BOARD_ID.build();
        default_map.add_reg(BOARD_ID, 'h0C, "RO");

        lock_model();
    endfunction
endclass
`endif
