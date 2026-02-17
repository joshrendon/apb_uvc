`ifndef APB_PREDICTOR_SV
`define APB_PREDICTOR_SV
class apb_predictor extends uvm_component;
    `uvm_component_utils(apb_predictor);

    localparam INDEX_BITS = $clog2(256);
    bit [`APB_MAX_DATA_WIDTH-1:0] mem [255:0];
    

    function new(string name = "apb_predictor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function apb_item update_and_get_expected(apb_item t);
        bit [4:0] addr_index;
        bit [`APB_MAX_DATA_WIDTH-1:0] wdata = 0;
        apb_item expected = apb_item::type_id::create("expected");
        expected.psel     = t.psel;
        expected.paddr    = t.paddr;
        expected.pwrite   = t.pwrite;
        expected.pstrb    = t.pstrb;
        addr_index = t.paddr[INDEX_BITS+1:2];

        `uvm_info("APB_PREDICTOR", $sformatf("apb_item t: Addr 0x%0h R/W:%0b pdata: 0x%0h", t.paddr, t.pwrite, t.pdata), UVM_LOW)

        if (t.pwrite) begin
            for (int i = 0; i < (`APB_MAX_DATA_WIDTH/8); i++) begin
                if (t.pstrb[i]) begin
                    wdata[(i*8) +: 8] = t.pdata[(i*8) +: 8];
                end
            end

            expected.pdata = wdata;
            mem[addr_index] = wdata;
            `uvm_info("APB_PREDICTOR", $sformatf("Addr 0x%0h wrote 0x%0h -> memory 0x%0h", t.paddr, t.pdata, mem[addr_index]), UVM_LOW)
        end else begin
            expected.pdata  = mem[addr_index];
        end
        expected.pslverr = t.pslverr;
        //`uvm_info("APB_PREDICTOR", $sformatf("t: %0s, expected: %s", t.sprint(), expected.sprint()), UVM_LOW)
        return expected;
    endfunction

endclass
`endif
