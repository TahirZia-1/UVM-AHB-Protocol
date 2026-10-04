`ifndef AHB_ERROR_TEST_SV
`define AHB_ERROR_TEST_SV

// ================================================================
// Sequence: Injects AHB-Lite Negative & Boundary Violations
// ================================================================
class ahb_error_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_error_seq)

  function new(string name = "ahb_error_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_seq_item item;

    // ------------------------------------------------------------
    // TC_52: Half-word Unaligned Address Access (HSIZE=16bit, Addr=0x0001)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_52: Driving unaligned 16-bit access to 0x00000001", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc52_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0001;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_16BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_52");
    finish_item(item);

    // ------------------------------------------------------------
    // TC_53: Word Unaligned Address Access (HSIZE=32bit, Addr=0x00000002)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_53: Driving unaligned 32-bit access to 0x00000002", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc53_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0002;
      hwrite == 1'b1;
      hwdata == 32'hDEAD_BEEF;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_53");
    finish_item(item);

    // ------------------------------------------------------------
    // TC_55: Unsupported Transfer Size (HSIZE=3'd3 -> 64-bit)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_55: Driving unsupported 64-bit size to 0x00000100", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc55_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0100;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_64BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_55");
    finish_item(item);

    // ------------------------------------------------------------
    // TC_56: Unmapped RAM-to-Register Hole (Addr=0x00000900)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_56: Accessing unmapped RAM hole at 0x00000900", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc56_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_0900;
      hwrite == 1'b1;
      hwdata == 32'hBAAD_F00D;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_56");
    finish_item(item);

    // ------------------------------------------------------------
    // TC_57: Unmapped Register Gap Hole (Addr=0x0000101C)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_57: Accessing unmapped register hole at 0x0000101C", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc57_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_101C;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_57");
    finish_item(item);

    // ------------------------------------------------------------
    // TC_58: High Out-of-Bounds Address (Addr=0x00002000)
    // ------------------------------------------------------------
    `uvm_info("ERR_SEQ", "TC_58: Accessing high out-of-bounds address 0x00002000", UVM_LOW)
    item = ahb_seq_item::type_id::create("tc58_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_2000;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failure on TC_58");
    finish_item(item);

    #100ns;
  endtask : body

endclass : ahb_error_seq

// ================================================================
// Test: Executes ahb_error_seq
// ================================================================
class ahb_error_test extends uvm_test;

  `uvm_component_utils(ahb_error_test)

  ahb_env env;

  function new(string name = "ahb_error_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_error_seq err_seq;
    phase.raise_objection(this);

    err_seq = ahb_error_seq::type_id::create("err_seq");
    `uvm_info("ERR_TEST", "--- STARTING DAY 5 SUITE 1: NEGATIVE & ERROR INJECTION ---", UVM_LOW)
    err_seq.start(env.master_agent.sequencer);

    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_error_test

`endif