`timescale 1ns / 1ps
class apb_test extends uvm_test;
    `uvm_component_utils(apb_test)
    apb_env env;
    apb_agent_config cfg;
    function new(string name="apb_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
        cfg = apb_agent_config::type_id::create("cfg");

        //cfg.slave_start_addr = '{32'h4000_0000, 32'h4000_1000, 32'h4000_2000, 32'h4000_3000};
        uvm_config_db#(apb_agent_config)::set(this, "env.agent*", "cfg", cfg);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_root uvm_top = uvm_root::get();
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.phase_done.set_drain_time(this, 1500);
        //if(!uvm_config_db#(apb_agent_config)::get(this,"*", "cfg", cfg))
        //    `uvm_error("NO_CFG", "Config object not found!")
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

        //if(!uvm_config_db#(apb_agent_config)::get(this,"", "cfg", cfg))
        //    `uvm_error("NO_CFG", "Config object not found!")
        `uvm_info("RANDOM_APB_TEST", $sformatf("apb_agent_config:\n%s", cfg.sprint()), UVM_LOW)
        seq.start(env.agent.seq);
        phase.drop_objection(this);
        //phase.raise_objection(this);
        //#80;
        //phase.drop_objection(this);
    endtask
endclass

class apb_interleaved_test extends apb_test;
    `uvm_component_utils(apb_interleaved_test)

    function new(string name = "apb_interleaved_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        // Set the interleaved sequence as the default for the master sequencer
        uvm_config_db#(uvm_object_wrapper)::set(this, "env.agent.seq.main_phase", "default_sequence", apb_interleaved_test_seq::type_id::get());
            
        super.build_phase(phase);
    endfunction

    virtual task run_phase(uvm_phase phase);
        apb_interleaved_test_seq seq;
        phase.raise_objection(this);
        seq = apb_interleaved_test_seq::type_id::create("seq");
        `uvm_info("APB_INTERLEAVED_TEST", "run_phase() about to start seq", UVM_LOW)

        seq.start(env.agent.seq);
        phase.drop_objection(this);
    endtask
endclass
