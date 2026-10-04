class ahb_ral_test extends uvm_test;

  `uvm_component_utils(ahb_ral_test)

  ahb_env env;

  function new(string name = "ahb_ral_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_ral_seq seq;
    phase.raise_objection(this);

    seq = ahb_ral_seq::type_id::create("seq");
    seq.rm = env.reg_block;

    `uvm_info("RAL_TEST", "Starting Day 2 AHB RAL Sequence...", UVM_LOW)
    seq.start(env.master_agent.sequencer);
    #100ns;

    `uvm_info("RAL_TEST", "Day 2 RAL Sequence Finished Successfully.", UVM_LOW)
    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_ral_test



