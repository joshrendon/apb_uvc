`timescale 1ns / 1ps
class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)
    apb_env env;
    apb_config cfg;
    function new(string name="apb_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
        cfg = apb_config::type_id::create("cfg");
        cfg.add_master("master", UVM_ACTIVE);
        cfg.add_slave("slave0", 32'h4000_0000, 32'h4000_FFFF, 0, UVM_ACTIVE);
        cfg.add_slave("slave1", 32'h4001_0000, 32'h4001_FFFF, 1, UVM_ACTIVE);

        uvm_config_db#(apb_config)::set(this, "*", "cfg", cfg);
        //uvm_config_db#(apb_master_config)::set(this, "env.master_agent*", "cfg", cfg.master_config);
        `uvm_info("APB_TEST", $sformatf("apb_agent_config:\n%s", cfg.sprint()), UVM_LOW)
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_root uvm_top = uvm_root::get();
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_drain_time(this, 1500);
        `uvm_info("RANDOM_APB_TEST", $sformatf("apb_agent_config:\n%s", cfg.sprint()), UVM_LOW)
    endtask

    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        `uvm_info(get_type_name(), "test in start_of_simulation_phase", UVM_LOW)
    endfunction : start_of_simulation_phase
endclass

class random_apb_test extends apb_test;
    `uvm_component_utils(random_apb_test)
    function new(string name="random_apb_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_sequence seq;
        phase.raise_objection(this);
        seq = apb_sequence::type_id::create("seq");
        `uvm_info("APB_TEST", "run_phase() about to start seq", UVM_LOW)

        `uvm_info("RANDOM_APB_TEST", $sformatf("apb_agent_config:\n%s", cfg.sprint()), UVM_LOW)
        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass

class apb_interleaved_test extends apb_test;
    `uvm_component_utils(apb_interleaved_test)

    function new(string name = "apb_interleaved_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Set the interleaved sequence as the default for the master sequencer
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_interleaved_test_seq::type_id::get());
            
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_interleaved_test_seq seq;
        phase.raise_objection(this);
        seq = apb_interleaved_test_seq::type_id::create("seq");
        `uvm_info("APB_INTERLEAVED_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass

class apb_interleaved_read_test extends apb_test;
    `uvm_component_utils(apb_interleaved_read_test)

    function new(string name = "apb_interleaved_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Set the interleaved sequence as the default for the master sequencer
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_interleaved_read_test_seq::type_id::get());
            
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_interleaved_read_test_seq seq;
        phase.raise_objection(this);
        seq = apb_interleaved_read_test_seq::type_id::create("seq");
        `uvm_info("APB_INTERLEAVED_READ_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass

class apb_wr_test extends apb_test;
    `uvm_component_utils(apb_wr_test)

    function new(string name = "apb_wr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Set the interleaved sequence as the default for the master sequencer
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_wr_test_seq::type_id::get());
            
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_wr_test_seq seq;
        phase.raise_objection(this);
        seq = apb_wr_test_seq::type_id::create("seq");
        `uvm_info("APB_WR_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass

class apb_reg_test extends apb_test;
    `uvm_component_utils(apb_reg_test)

    function new(string name = "apb_reg_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        //default_apb_config my_cfg;
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_reg_test_seq::type_id::get());
        //set_type_override_by_type(apb_config::get_type(), default_apb_config::get_type());
        //my_cfg = default_apb_config::type_id::create("cfg");
        //uvm_config_db#(apb_config)::set(this, "*", "apb_config", my_cfg);
        //uvm_config_db#(apb_master_config)::set(null, "*", "cfg", my_cfg.master_config);
        //`uvm_info("APB_REG_TEST", $sformatf("default_apb_config: %s", my_cfg), UVM_LOW)
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_reg_test_seq seq;
        phase.raise_objection(this);
        seq = apb_reg_test_seq::type_id::create("seq");
        `uvm_info("APB_REG_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass : apb_reg_test

class apb_slv_test extends apb_test;
    `uvm_component_utils(apb_slv_test)

    function new(string name = "apb_slv_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_reg_test_seq::type_id::get());
        uvm_config_db_options::turn_on_tracing();
        super.build_phase(phase);
        uvm_top.print_config(1);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_slave_responder_seq slv_seq0, slv_seq1;
        apb_reg_test_seq mst_seq;

        phase.raise_objection(this);
        mst_seq = apb_reg_test_seq::type_id::create("mst_seq");
        slv_seq0 = apb_slave_responder_seq::type_id::create("slv_seq0");
        slv_seq1 = apb_slave_responder_seq::type_id::create("slv_seq1");

        fork
            slv_seq0.start(env.slave_agents[0].seq);
            //slv_seq1.start(env.slave_agents[1].seq);
        join_none

        `uvm_info("APB_SLV_TEST", "run_phase() Starting mst_seq", UVM_LOW)
        mst_seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask
endclass : apb_slv_test

class apb_ral_test extends apb_test;
    `uvm_component_utils(apb_ral_test)

    function new(string name = "apb_ral_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.master_agent.seq.main_phase", "default_sequence", apb_ral_test_seq::type_id::get());
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_ral_test_seq seq;

        phase.raise_objection(this);
        seq = apb_ral_test_seq::type_id::create("seq");
        //`uvm_info("APB_RAL_TEST", $sformatf("reg_block: %s", env.reg_block.sprint()), UVM_LOW)
        `uvm_info("APB_RAL_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.master_agent.seq);
        phase.drop_objection(this);
    endtask

    virtual function void end_of_elaboration_phase(uvm_phase phase);
      uvm_phase run_phase = phase.find_by_name("run", 0);
      run_phase.phase_done.set_drain_time(this, 100ns); // Give it enough time to finish the last ACCESS
    endfunction
endclass : apb_ral_test
