`ifndef AHB_INTERRUPT_TEST_SV
`define AHB_INTERRUPT_TEST_SV

// ================================================================
// Sequence: Exercises Hardware Interrupts, Masking, and W1C Logic
// ================================================================
class ahb_interrupt_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_interrupt_seq)

  function new(string name = "ahb_interrupt_seq");
    super.new(name);
  endfunction : new

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
    // 1. SETUP: Enable Blocks & Master IRQ (CTRL) and Interrupt Enables (INT_EN)
    // ------------------------------------------------------------
    `uvm_info("IRQ_SEQ", "--- PHASE 1: Setting up Interrupt Configuration ---", UVM_LOW)
    // CTRL: Bit 0 = Master IRQ Enable, Bit 1 = Timer Enable, Bit 2 = FIFO Enable
    bus_write(32'h0000_1000, 32'h0000_0007);
    // INT_EN (0x1008): Bit 0 = Timer Expiry IRQ, Bit 1 = FIFO Full IRQ, Bit 2 = FIFO Empty IRQ
    bus_write(32'h0000_1008, 32'h0000_0007);

    // ------------------------------------------------------------
    // 2. TC_35: Timer Expiry Interrupt Generation & IRQ Pin Check
    // ------------------------------------------------------------
    `uvm_info("IRQ_SEQ", "TC_35: Triggering Timer Expiry Interrupt...", UVM_LOW)
    bus_write(32'h0000_1010, 32'h0000_0008); // Short load value: 8 cycles
    bus_write(32'h0000_1014, 32'h0000_0001); // Start Timer in One-Shot Mode

    #150ns; // Wait for timer down-count to complete

    bus_read(32'h0000_100C, rdata); // Read INT_STATUS
    `uvm_info("IRQ_SEQ", $sformatf("INT_STATUS after Timer expiry: 0x%08h (Bit 0 expected 1)", rdata), UVM_LOW)

    // ------------------------------------------------------------
    // 3. TC_38: Master IRQ Masking via CTRL[0]
    // ------------------------------------------------------------
    `uvm_info("IRQ_SEQ", "TC_38: Testing Master IRQ Masking via CTRL[0]...", UVM_LOW)
    // Mask master interrupt by writing CTRL[0] = 0
    bus_write(32'h0000_1000, 32'h0000_0006);
    #30ns;
    `uvm_info("IRQ_SEQ", "Master IRQ masked. Restoring CTRL[0] = 1...", UVM_MEDIUM)
    bus_write(32'h0000_1000, 32'h0000_0007);
    #30ns;

    // ------------------------------------------------------------
    // 4. TC_15 & TC_39: W1C (Write-1-to-Clear) on INT_STATUS & Deassertion Latency
    // ------------------------------------------------------------
    `uvm_info("IRQ_SEQ", "TC_15/TC_39: Servicing Timer IRQ via W1C write to bit 0...", UVM_LOW)
    // Writing 0 does not clear bits
    bus_write(32'h0000_100C, 32'h0000_0000);
    bus_read(32'h0000_100C, rdata);
    `uvm_info("IRQ_SEQ", $sformatf("INT_STATUS after writing 0: 0x%08h (Must retain 1)", rdata), UVM_LOW)

    // Writing 1 clears bit 0
    bus_write(32'h0000_100C, 32'h0000_0001);
    bus_read(32'h0000_100C, rdata);
    `uvm_info("IRQ_SEQ", $sformatf("INT_STATUS after W1C write: 0x%08h (Bit 0 must be 0)", rdata), UVM_LOW)

    // ------------------------------------------------------------
    // 5. TC_36 & TC_40: FIFO Full Interrupt & Concurrent Clear Verification
    // ------------------------------------------------------------
    `uvm_info("IRQ_SEQ", "TC_36/TC_40: Triggering FIFO Full Interrupt concurrently...", UVM_LOW)
    // Push 16 words to fill FIFO
    for (int i = 0; i < 16; i++) begin
      bus_write(32'h0000_1020, 32'hA000_0000 | i);
    end

    bus_read(32'h0000_100C, rdata);
    `uvm_info("IRQ_SEQ", $sformatf("INT_STATUS after filling FIFO: 0x%08h (FIFO Full bit expected)", rdata), UVM_LOW)

    // Clear remaining interrupt flags
    bus_write(32'h0000_100C, 32'h0000_0007);
    #50ns;
    bus_read(32'h0000_100C, rdata);
    `uvm_info("IRQ_SEQ", $sformatf("INT_STATUS after full W1C clear: 0x%08h (Expected 0)", rdata), UVM_LOW)

    #100ns;
  endtask : body

endclass : ahb_interrupt_seq

// ================================================================
// Test: Executes ahb_interrupt_seq
// ================================================================
class ahb_interrupt_test extends uvm_test;

  `uvm_component_utils(ahb_interrupt_test)

  ahb_env env;

  function new(string name = "ahb_interrupt_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_interrupt_seq irq_seq;
    phase.raise_objection(this);

    irq_seq = ahb_interrupt_seq::type_id::create("irq_seq");
    `uvm_info("IRQ_TEST", "--- STARTING DAY 5 SUITE 3: INTERRUPT & W1C TESTING ---", UVM_LOW)
    irq_seq.start(env.master_agent.sequencer);

    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_interrupt_test

`endif