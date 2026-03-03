`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_pkg.sv"

module tb_coverage;
    virtual apb_interface vif;
    apb_master_coverage_subscriber master_sub;
    apb_slave_coverage_subscriber slave_sub;
    apb_transaction_coverage_subscriber txn_sub;
    
    initial begin
        `uvm_info("TB_INIT", "=== APB UVC Coverage Testbench ===", UVM_LOW)
        
        // Create virtual interface
        vif = new();
        
        // Instantiate coverage collectors
        master_sub = apb_master_coverage_subscriber::type_id::create("master_sub");
        slave_sub = apb_slave_coverage_subscriber::type_id::create("slave_sub");
        txn_sub = apb_transaction_coverage_subscriber::type_id::create("txn_sub");
        
        // Set virtual interface in config DB
        uvm_config_db#(virtual apb_interface)::set(
            uvm_root::get(), "*", "vif", vif);
        
        // Connect coverage subscribers to monitor ports (if needed)
        // This allows automatic coverage collection from transactions
        
        `uvm_info("TB_INIT", $sformatf("Master coverage sub: %s", master_sub.get_full_name()), UVM_LOW)
        `uvm_info("TB_INIT", $sformatf("Slave coverage sub: %s", slave_sub.get_full_name()), UVM_LOW)
        `uvm_info("TB_INIT", $sformatf("Transaction coverage sub: %s", txn_sub.get_full_name()), UVM_LOW)
        
        // Run coverage test
        `uvm_info("TB_INIT", "Starting apb_wr_test with coverage collection", UVM_LOW)
        run_test("apb_wr_test");
        
        // Generate coverage reports
        `uvm_info("COVERAGE", "=== Coverage Collection Complete ===", UVM_LOW)
        
        // Print coverage summary
        `uvm_info("COVERAGE", "Printing coverage report...", UVM_LOW)
        
        // Generate HTML coverage report
        uvm_report_server::get_server().print_coverage_report("coverage_report.html");
        
        // Print text coverage report
        `uvm_info("COVERAGE", "=== Text Coverage Report ===", UVM_LOW)
        `uvm_info("COVERAGE", "Master Coverage Groups:", UVM_LOW)
        if (master_sub.master_cg != null) begin
            `uvm_info("COVERAGE", $sformatf("  - Total Coverage: %0d%%", 
                master_sub.master_cg.get_coverage()), UVM_LOW);
            `uvm_info("COVERAGE", master_sub.master_cg.get_coverage_info(), UVM_LOW);
        end
        
        `uvm_info("COVERAGE", "Slave Coverage Groups:", UVM_LOW)
        if (slave_sub.slave_cg != null) begin
            `uvm_info("COVERAGE", $sformatf("  - Total Coverage: %0d%%", 
                slave_sub.slave_cg.get_coverage()), UVM_LOW);
            `uvm_info("COVERAGE", slave_sub.slave_cg.get_coverage_info(), UVM_LOW);
        end
        
        `uvm_info("COVERAGE", "Transaction Coverage Groups:", UVM_LOW)
        if (txn_sub.txn_cg != null) begin
            `uvm_info("COVERAGE", $sformatf("  - Total Coverage: %0d%%", 
                txn_sub.txn_cg.get_coverage()), UVM_LOW);
            `uvm_info("COVERAGE", txn_sub.txn_cg.get_coverage_info(), UVM_LOW);
        end
        
        // Check coverage goals
        `uvm_info("COVERAGE", "=== Coverage Goals Check ===", UVM_LOW)
        
        if (master_sub.master_cg != null) begin
            int master_cov = master_sub.master_cg.get_coverage();
            if (master_cov >= 80) begin
                `uvm_pass_severity("COVERAGE_GOAL", $sformatf("Master coverage %0d%% >= 80%%", master_cov))
            end else begin
                `uvm_error("COVERAGE_GOAL", $sformatf("Master coverage %0d%% < 80%%", master_cov))
            end
        end
        
        if (slave_sub.slave_cg != null) begin
            int slave_cov = slave_sub.slave_cg.get_coverage();
            if (slave_cov >= 80) begin
                `uvm_pass_severity("COVERAGE_GOAL", $sformatf("Slave coverage %0d%% >= 80%%", slave_cov))
            end else begin
                `uvm_error("COVERAGE_GOAL", $sformatf("Slave coverage %0d%% < 80%%", slave_cov))
            end
        end
        
        `uvm_info("TB_INIT", "=== Coverage Testbench Complete ===", UVM_LOW)
        
        // Finish simulation
        #10;
        $finish;
    end
    
    // Dump waves for debugging
    initial begin
        $dumpfile("coverage_dump.vcd");
        $dumpvars(0, tb_coverage);
        #100;
        $finish_dumpvars;
    end
    
endmodule