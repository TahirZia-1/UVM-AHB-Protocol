`ifndef AHB_SANITY_TEST_SV
`define AHB_SANITY_TEST_SV

class ahb_sanity_test extends uvm_test;

  `uvm_component_utils(ahb_sanity_test)

  ahb_env env;

  function new(string name = "ahb_sanity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_sanity_seq seq;
    phase.raise_objection(this);

    seq = ahb_sanity_seq::type_id::create("seq");
    `uvm_info("SANITY_TEST", "Starting AHB Day 1 Sanity Sequence...", UVM_LOW)
    seq.start(env.master_agent.sequencer);
    #100ns;

    `uvm_info("SANITY_TEST", "Sanity Sequence Completed Successfully.", UVM_LOW)
    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_sanity_test

`endif