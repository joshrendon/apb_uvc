`ifndef APB_DEFINES
    `define APB_DEFINES

    `ifndef APB_MAX_ADDR_WIDTH
        `define APB_MAX_ADDR_WIDTH 32
    `endif
    
    `ifndef APB_MAX_DATA_WIDTH
        `define APB_MAX_DATA_WIDTH 8
    `endif
    
    `define APB_MAX_PROT_WIDTH 3
    
    `ifndef APB_MAX_STROBE_WIDTH
        `define APB_MAX_STROBE_WIDTH 4
    `endif
    
    `ifndef APB_MAX_SEL_WIDTH
        `define APB_MAX_SEL_WIDTH 2
    `endif
`endif
