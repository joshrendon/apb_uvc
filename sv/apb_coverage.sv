`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

`ifdef COVERAGE

// ============================================================================
// Master Coverage - Transactions initiated by master
// ============================================================================
class apb_master_coverage_subscriber extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_master_coverage_subscriber)

    function new(string name="apb_master_coverage_subscriber", uvm_component parent);
        super.new(name,parent);
        master_cg = new();
    endfunction

    covergroup master_cg with function sample(apb_item item);
        option.per_instance = 1;
        option.name = "APB_MASTER_STIMULUS_CG";

        // Wait states: normal (0) to delayed (1-5)
        cp_wait_states: coverpoint item.wait_cycles {
            bins normal      = (0);
            bins wait_1      = (1);
            bins wait_2      = (2);
            bins wait_3      = (3);
            bins wait_4      = (4);
            bins wait_5      = (5);
        }

        // Transaction direction
        cp_direction: coverpoint item.pwrite {
            bins write = {APB_WRITE};
            bins read  = {APB_READ};
        }

        // Back-to-back transaction flag
        cp_is_b2b: coverpoint item.is_b2b {
            bins yes = {1};
            bins no  = {0};
        }

        // PSEL index (which slave was accessed)
        cp_psel_index: coverpoint item.psel {
            bins s0 = (2'b01);
            bins s1 = (2'b10);
        }

        // Address coverage
        cp_addr: coverpoint item.paddr {
            bins low_range    = {[32'h4000_0000 : 32'h4000_0FFF]};
            bins medium_range = {[32'h4000_1000 : 32'h4000_EFFF]};
            bins high_range   = {[32'h4000_F000 : 32'h4001_FFFF]};
        }

        // Data patterns
        cp_data: coverpoint item.pdata {
            bins zeroes = {32'h0000_0000};
            bins ones   = {32'hFFFF_FFFF};
            bins others = default;
        }

        // Strbe patterns
        cp_strbs: coverpoint item.pstrb {
            bins one   = {2'b01};
            bins two   = {2'b10};
            bins three = {2'b11};
        }

        // Cross coverage: wait states x direction
        waitXdir: cross cp_wait_states, cp_direction;

        // Cross coverage: wait states x B2B
        waitXB2B: cross cp_wait_states, cp_is_b2b;

        // Cross coverage: wait states x PSEL index
        waitXpsel: cross cp_wait_states, cp_psel_index;

        // Cross coverage: B2B x PSEL index
        b2bXpsel: cross cp_is_b2b, cp_psel_index;

        // Cross coverage: address x direction
        addrXdir: cross cp_addr, cp_direction;

        // Cross coverage: wait states x data
        waitXdata: cross cp_wait_states, cp_data;

        // Full transaction coverage cross
        full_txn: cross cp_wait_states, cp_direction, cp_is_b2b, cp_psel_index;
    endgroup

    virtual function void write(apb_item t);
        master_cg.sample(t);
    endfunction
    
endclass

// ============================================================================
// Slave Coverage - Responses from slave
// ============================================================================
class apb_slave_coverage_subscriber extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_slave_coverage_subscriber)

    function new(string name="apb_slave_coverage_subscriber", uvm_component parent);
        super.new(name,parent);
        slave_cg = new();
    endfunction

    covergroup slave_cg with function sample(apb_item item);
        option.per_instance = 1;
        option.name = "APB_SLAVE_RESPONSE_CG";

        // Slave response time (wait cycles)
        cp_response_time: coverpoint item.wait_cycles {
            bins same_cycle   = (0);
            bins delayed_1    = (1);
            bins delayed_2    = (2);
            bins delayed_3    = (3);
            bins delayed_4    = (4);
            bins delayed_5    = (5);
        }

        // Error response
        cp_error: coverpoint item.pslverr {
            bins no_error = {0};
            bins error    = {1};
        }

        // PSEL index (which slave responded)
        cp_psel_index: coverpoint item.psel {
            bins s0 = (2'b01);
            bins s1 = (2'b10);
        }

        // Transaction type
        cp_txn_type: coverpoint item.pwrite {
            bins write = {APB_WRITE};
            bins read  = {APB_READ};
        }

        // Cross coverage: response time x error
        responseXerror: cross cp_response_time, cp_error;

        // Cross coverage: response time x PSEL
        responseXpsel: cross cp_response_time, cp_psel_index;

        // Cross coverage: error x PSEL
        errorXpsel: cross cp_error, cp_psel_index;

        // Cross coverage: response time x transaction type
        responseXtxn: cross cp_response_time, cp_txn_type;

        // Full slave response coverage
        full_response: cross cp_response_time, cp_error, cp_psel_index, cp_txn_type;
    endgroup

    virtual function void write(apb_item t);
        slave_cg.sample(t);
    endfunction
    
endclass

// ============================================================================
// Transaction-Level Coverage for Bus Monitor
// ============================================================================
class apb_transaction_coverage_subscriber extends uvm_subscriber #(apb_item);
    `uvm_component_utils(apb_transaction_coverage_subscriber)

    function new(string name="apb_transaction_coverage_subscriber", uvm_component parent);
        super.new(name,parent);
        txn_cg = new();
    endfunction

    covergroup txn_cg with function sample(apb_item item);
        option.per_instance = 1;
        option.name = "APB_TRANSACTION_CG";

        // B2B transaction analysis
        cp_b2b_same_slave: coverpoint item.is_b2b {
            bins yes_same = (1);
            bins no       = (0);
        }

        // Previous PSEL (for B2B same vs different slave detection)
        cp_prev_psel: coverpoint item.active_psel {
            bins s0 = (2'b01);
            bins s1 = (2'b10);
        }

        // Cross: B2B x PSEL for same/different slave detection
        b2bXpsel_analysis: cross cp_b2b_same_slave, cp_prev_psel;
    endgroup

    virtual function void write(apb_item t);
        txn_cg.sample(t);
    endfunction
    
endclass

`endif // COVERAGE
`endif // APB_COVERAGE_SV
