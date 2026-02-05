`ifndef APB_PREDICTOR_SV
`define APB_PREDICTOR_SV
class apb_predictor extends uvm_component;
    `uvm_component_utils(apb_predictor);
    //`uvm_analysis_imp_decl(_expected)
    //`uvm_analysis_imp_decl(_actual)
    bit [`APB_MAX_DATA_WIDTH-1:0] mem [`APB_MAX_ADDR_WIDTH-1:0];

    function new(string name = "apb_predictor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function apb_item update_and_get_expected(apb_item t);
        bit [4:0] addr_index;
        apb_item expected = apb_item::type_id::create("expected");
        expected.psel     = t.psel;
        expected.paddr    = t.paddr;
        expected.pwrite   = t.pwrite;
        expected.pstrb    = t.pstrb;
        expected.pslverr  = 0;
        addr_index = t.paddr[6:2];

        `uvm_info("APB_PREDICTOR", $sformatf("apb_item t: Addr 0x%0h R/W:%0b prdata: 0x%0h pwdata: 0x%0h", t.paddr, t.pwrite, t.prdata, t.pwdata), UVM_LOW)

        if (t.pwrite) begin
            expected.pwdata = t.pwdata;
            mem[addr_index] = t.pwdata;
            `uvm_info("APB_PREDICTOR", $sformatf("Addr 0x%0h wrote 0x%0h -> memory 0x%0h", t.paddr, t.pwdata, mem[addr_index]), UVM_LOW)
        end else begin
            expected.prdata = mem[addr_index];
        end
        //`uvm_info("APB_PREDICTOR", $sformatf("t: %0s, expected: %s", t.sprint(), expected.sprint()), UVM_LOW)
        return expected;
    endfunction

endclass
`endif
