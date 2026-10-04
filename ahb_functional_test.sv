class ahb_functional_test extends uvm_test;

  `uvm_component_utils(ahb_functional_test)

  ahb_env env;

  function new(string name = "ahb_functional_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_ral_seq    ral_seq;
    ahb_memory_seq mem_seq;

    //phase.raise_objection(this);
fork
    ral_seq = ahb_ral_seq::type_id::create("ral_seq");
    ral_seq.rm = env.reg_block;

    mem_seq = ahb_memory_seq::type_id::create("mem_seq");

    // Phase 1: Register verification via RAL
    `uvm_info("FUNC_TEST", "--- PHASE 1: Running RAL Sequence ---", UVM_LOW)
    ral_seq.start(env.master_agent.sequencer);

    #50ns;

    // Phase 2: Memory verification via direct AHB transactions
    `uvm_info("FUNC_TEST", "--- PHASE 2: Running SRAM Memory Sequence ---", UVM_LOW)
    mem_seq.start(env.master_agent.sequencer);

  
join none

#600ns
    //phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_functional_test
