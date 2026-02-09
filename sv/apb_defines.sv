`ifndef APB_DEFINES
    `define APB_DEFINES

    `define APB_MAX_ADDR_WIDTH 32
    //`ifndef APB_MAX_ADDR_WIDTH
    //    `define APB_MAX_ADDR_WIDTH 32
    //`endif
    
    `define APB_MAX_DATA_WIDTH 32
    //`ifndef APB_MAX_DATA_WIDTH
    //    `define APB_MAX_DATA_WIDTH 32
    //`endif
    
    `define APB_MAX_PROT_WIDTH 3
    
    `define APB_MAX_STROBE_WIDTH (32/8)
    //`ifndef APB_MAX_STROBE_WIDTH
    //    `define APB_MAX_STROBE_WIDTH (`APB_MAX_DATA_WIDTH/8)
    //`endif
    
    `define APB_MAX_SEL_WIDTH 2
    //`ifndef APB_MAX_SEL_WIDTH
    //    `define APB_MAX_SEL_WIDTH 2
    //`endif

    `define APB_BASE_REGION_ADDR 32'h4000_0000
`endif
