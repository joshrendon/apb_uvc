`ifndef APB_TYPES_SV
    `define APB_TYPES_SV

    `include "apb_defines.sv"

    typedef enum bit {APB_READ = 0, APB_WRITE = 1} apb_direction_t;

    typedef bit [`APB_MAX_DATA_WIDTH-1:0] apb_data_t;

    typedef bit [`APB_MAX_ADDR_WIDTH-1:0] apb_addr_t;

    typedef enum {APB_IDLE, APB_SETUP, APB_ACCESS} apb_state_t;
    
`endif
