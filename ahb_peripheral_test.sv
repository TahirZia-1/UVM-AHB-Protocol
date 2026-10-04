`ifndef AHB_PERIPHERAL_TEST_SV
`define AHB_PERIPHERAL_TEST_SV

// ================================================================
// Sequence: Exercises FIFO and Timer Peripheral Hardware
// ================================================================
class ahb_peripheral_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_peripheral_seq)

  function new(string name = "ahb_peripheral_seq");
    super.new(name);
  endfunction : new

  // Helper task for single word write
  task bus_write(bit [31:0] addr, bit [31:0] data);
    ahb_seq_item item = ahb_seq_item::type_id::create("bus_write_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == addr;
      hwrite == 1'b1;
      hwdata == data;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Write item randomization failed");
    finish_item(item);
  endtask : bus_write

  // Helper task for single word read
  task bus_read(bit [31:0] addr, output bit [31:0] data);
    ahb_seq_item item = ahb_seq_item::type_id::create("bus_read_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == addr;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Read item randomization failed");
    finish_item(item);
    data = item.hrdata;
  endtask : bus_read

  virtual task body();
    bit [31:0] rdata;

    // ------------------------------------------------------------
    // 1. FIFO HARDWARE TESTING (TC_21 to TC_27)
    // ------------------------------------------------------------
    `uvm_info("PERIPH_SEQ", "--- PHASE 1: FIFO Verification ---", UVM_LOW)

    // Enable FIFO via CTRL[2] = 1
    `uvm_info("PERIPH_SEQ", "Enabling FIFO via CTRL[2] = 1", UVM_MEDIUM)
    bus_write(32'h0000_1000, 32'h0000_0004);

    // Verify FIFO initial empty state (TC_06, TC_22)
    bus_read(32'h0000_1024, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("FIFO_STAT after reset: 0x%08h (Expected Bit 0 Empty=1)", rdata), UVM_LOW)

    // Push 16 words to fill FIFO depth (TC_22)
    `uvm_info("PERIPH_SEQ", "Pushing 16 words to FIFO (0x1020)...", UVM_LOW)
    for (int i = 0; i < 16; i++) begin
      bus_write(32'h0000_1020, 32'hF1F0_0000 | i);
    end

    // Verify FIFO Full flag (TC_22)
    bus_read(32'h0000_1024, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("FIFO_STAT after 16 pushes: 0x%08h (Expected Bit 1 Full=1)", rdata), UVM_LOW)

    // TC_26: FIFO Overflow Attempt (17th write to full FIFO)
    `uvm_info("PERIPH_SEQ", "TC_26: Attempting 17th write to test FIFO overflow error...", UVM_LOW)
    bus_write(32'h0000_1020, 32'hDEAD_0017);

    // Pop and verify 16 words in strict FIFO order (TC_22)
    `uvm_info("PERIPH_SEQ", "Popping 16 words from FIFO...", UVM_LOW)
    for (int i = 0; i < 16; i++) begin
      bus_read(32'h0000_1020, rdata);
      `uvm_info("PERIPH_SEQ", $sformatf("Popped Word %0d: 0x%08h", i, rdata), UVM_MEDIUM)
    end

    // Verify FIFO Empty flag (TC_22)
    bus_read(32'h0000_1024, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("FIFO_STAT after 16 pops: 0x%08h (Expected Bit 0 Empty=1)", rdata), UVM_LOW)

    // TC_27: FIFO Underflow Attempt (Pop from empty FIFO)
    `uvm_info("PERIPH_SEQ", "TC_27: Attempting pop on empty FIFO to test underflow error...", UVM_LOW)
    bus_read(32'h0000_1020, rdata);

    // ------------------------------------------------------------
    // 2. TIMER HARDWARE TESTING (TC_29 to TC_32)
    // ------------------------------------------------------------
    `uvm_info("PERIPH_SEQ", "--- PHASE 2: Timer Verification ---", UVM_LOW)

    // Enable Timer block via CTRL[1] = 1
    bus_write(32'h0000_1000, 32'h0000_0002);

    // TC_29: One-shot down-count mode
    `uvm_info("PERIPH_SEQ", "TC_29: Programming Timer One-Shot mode with load count 0x0000_0020", UVM_LOW)
    bus_write(32'h0000_1010, 32'h0000_0020); // TIMER_LOAD = 32 cycles
    bus_write(32'h0000_1014, 32'h0000_0001); // TIMER_CTRL: Start=1, Mode=0 (One-shot)

    // Poll TIMER_VAL to verify down-counting
    #100ns;
    bus_read(32'h0000_1018, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("TIMER_VAL sampled while running: 0x%08h", rdata), UVM_LOW)

    // Wait for timer expiry
    #300ns;
    bus_read(32'h0000_1018, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("TIMER_VAL sampled after expiry: 0x%08h (Expected 0)", rdata), UVM_LOW)

    // TC_30: Periodic Reload Mode
    `uvm_info("PERIPH_SEQ", "TC_30: Programming Timer Periodic mode with load count 0x0000_0010", UVM_LOW)
    bus_write(32'h0000_1010, 32'h0000_0010); // TIMER_LOAD = 16 cycles
    bus_write(32'h0000_1014, 32'h0000_0003); // TIMER_CTRL: Start=1, Mode=1 (Periodic)

    #250ns;
    bus_read(32'h0000_1018, rdata);
    `uvm_info("PERIPH_SEQ", $sformatf("TIMER_VAL in periodic mode: 0x%08h", rdata), UVM_LOW)

    // Stop timer
    bus_write(32'h0000_1014, 32'h0000_0000);
    #50ns;
  endtask : body

endclass : ahb_peripheral_seq

// ================================================================
// Test: Executes ahb_peripheral_seq
// ================================================================
class ahb_peripheral_test extends uvm_test;

  `uvm_component_utils(ahb_peripheral_test)

  ahb_env env;

  function new(string name = "ahb_peripheral_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_peripheral_seq p_seq;
    phase.raise_objection(this);

    p_seq = ahb_peripheral_seq::type_id::create("p_seq");
    `uvm_info("PERIPH_TEST", "--- STARTING DAY 5 SUITE 2: FIFO & TIMER PERIPHERAL TESTING ---", UVM_LOW)
    p_seq.start(env.master_agent.sequencer);

    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_peripheral_test

`endif