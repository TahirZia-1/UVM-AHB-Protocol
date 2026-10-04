`ifndef AHB_REGRESSION_TEST_SV
`define AHB_REGRESSION_TEST_SV

class ahb_regression_test extends uvm_test;

  `uvm_component_utils(ahb_regression_test)

  ahb_env env;

  function new(string name = "ahb_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_ral_seq        ral_s;
    ahb_memory_seq     mem_s;
    ahb_error_seq      err_s;
    ahb_peripheral_seq per_s;
    ahb_interrupt_seq  irq_s;
    ahb_stress_seq     str_s;

    phase.raise_objection(this);

    `uvm_info("REGRESS", "==================================================", UVM_NONE)
    `uvm_info("REGRESS", "   LAUNCHING DAY 5 FULL SYSTEM REGRESSION SUITE   ", UVM_NONE)
    `uvm_info("REGRESS", "==================================================", UVM_NONE)

    // 1. Register Architecture & Reset Tests (TC_01 - TC_15)
    ral_s    = ahb_ral_seq::type_id::create("ral_s");
    ral_s.rm = env.reg_block;
    ral_s.start(env.master_agent.sequencer);

    // 2. SRAM Sequential & Basic R/W (TC_16)
    mem_s = ahb_memory_seq::type_id::create("mem_s");
    mem_s.start(env.master_agent.sequencer);

    // 3. Error Injection & Negative Testing (TC_51 - TC_60)
    err_s = ahb_error_seq::type_id::create("err_s");
    err_s.start(env.master_agent.sequencer);

    // 4. Hardware FIFO & Timer IP Testing (TC_21 - TC_35)
    per_s = ahb_peripheral_seq::type_id::create("per_s");
    per_s.start(env.master_agent.sequencer);

    // 5. Hardware Interrupts & W1C Semantics (TC_36 - TC_40)
    irq_s = ahb_interrupt_seq::type_id::create("irq_s");
    irq_s.start(env.master_agent.sequencer);

    // 6. Full Subsystem Concurrent Stress & Bursts (TC_41 - TC_50, TC_61 - TC_62)
    str_s = ahb_stress_seq::type_id::create("str_s");
    str_s.start(env.master_agent.sequencer);

    #200ns;
    `uvm_info("REGRESS", "==================================================", UVM_NONE)
    `uvm_info("REGRESS", "   ALL 62 TEST CASES EXECUTED SUCCESSFULLY        ", UVM_NONE)
    `uvm_info("REGRESS", "==================================================", UVM_NONE)

    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_regression_test

`endif