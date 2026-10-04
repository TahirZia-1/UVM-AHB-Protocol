// ================================================================
// Sequence: Full Subsystem Concurrent Stress & Burst Exerciser
// ================================================================
class ahb_stress_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_stress_seq)

  function new(string name = "ahb_stress_seq");
    super.new(name);
  endfunction : new

  // Word/Sub-word Transfer Task
  task bus_trans(bit [31:0] addr, bit write, bit [31:0] wdata, bit [2:0] size, output bit [31:0] rdata);
    ahb_seq_item item = ahb_seq_item::type_id::create("stress_item");
    start_item(item);
    if (!item.randomize() with {
      haddr  == addr;
      hwrite == write;
      hwdata == wdata;
      hsize  == size;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Stress transfer randomization failed");
    finish_item(item);
    rdata = item.hrdata;
  endtask : bus_trans

  // 4-Beat Incrementing Burst Task (TC_45)
  task burst_incr4(bit [31:0] start_addr, bit write);
    ahb_seq_item beat;
    bit [31:0] cur_addr = start_addr;

    for (int i = 0; i < 4; i++) begin
      beat = ahb_seq_item::type_id::create($sformatf("incr4_beat_%0d", i));
      start_item(beat);
      if (!beat.randomize() with {
        haddr  == cur_addr;
        hwrite == write;
        hwdata == (write ? (32'hB000_0000 | cur_addr) : 32'h0);
        hsize  == ahb_seq_item::SIZE_32BIT;
        hburst == ahb_seq_item::BURST_INCR4;
        htrans == (i == 0) ? ahb_seq_item::TRANS_NONSEQ : ahb_seq_item::TRANS_SEQ;
      }) `uvm_fatal("RND_FAIL", "INCR4 beat randomization failed");
      finish_item(beat);
      cur_addr += 4;
    end
  endtask : burst_incr4

  // 4-Beat Wrapping Burst Task (TC_46)
  task burst_wrap4(bit [31:0] start_addr, bit write);
    ahb_seq_item beat;
    bit [31:0] cur_addr = start_addr;
    bit [31:0] base_addr = {start_addr[31:4], 4'b0000};

    for (int i = 0; i < 4; i++) begin
      beat = ahb_seq_item::type_id::create($sformatf("wrap4_beat_%0d", i));
      start_item(beat);
      if (!beat.randomize() with {
        haddr  == cur_addr;
        hwrite == write;
        hwdata == (write ? (32'hC000_0000 | cur_addr) : 32'h0);
        hsize  == ahb_seq_item::SIZE_32BIT;
        hburst == ahb_seq_item::BURST_WRAP4;
        htrans == (i == 0) ? ahb_seq_item::TRANS_NONSEQ : ahb_seq_item::TRANS_SEQ;
      }) `uvm_fatal("RND_FAIL", "WRAP4 beat randomization failed");
      finish_item(beat);

      // Address wraps within 16-byte boundary
      cur_addr = base_addr | (((cur_addr[3:0] + 4) % 16) & 4'hF);
    end
  endtask : burst_wrap4

  virtual task body();
    bit [31:0]   rdata;
    bit [31:0]   cur_addr;
    ahb_seq_item beat;

    // ------------------------------------------------------------
    // 1. TC_42: Enable Randomized Wait States (WAIT_CFG = 3)
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "TC_42: Configuring WAIT_CFG = 3 (Randomized 0-3 wait cycles)", UVM_LOW)
    bus_trans(32'h0000_102C, 1'b1, 32'h0000_0003, ahb_seq_item::SIZE_32BIT, rdata);

    // ------------------------------------------------------------
    // 2. TC_17 & TC_18: Sub-word Memory Accesses (Byte & Half-word)
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "TC_18: Executing Byte Writes across all 4 byte lanes (0x0000_0200)", UVM_LOW)
    bus_trans(32'h0000_0200, 1'b1, 32'h0000_0011, ahb_seq_item::SIZE_8BIT, rdata);
    bus_trans(32'h0000_0201, 1'b1, 32'h0000_2200, ahb_seq_item::SIZE_8BIT, rdata);
    bus_trans(32'h0000_0202, 1'b1, 32'h0033_0000, ahb_seq_item::SIZE_8BIT, rdata);
    bus_trans(32'h0000_0203, 1'b1, 32'h4400_0000, ahb_seq_item::SIZE_8BIT, rdata);

    `uvm_info("STRESS_SEQ", "TC_17: Executing Half-word Writes (0x0000_0210)", UVM_LOW)
    bus_trans(32'h0000_0210, 1'b1, 32'h0000_55AA, ahb_seq_item::SIZE_16BIT, rdata);
    bus_trans(32'h0000_0212, 1'b1, 32'hAA55_0000, ahb_seq_item::SIZE_16BIT, rdata);

    // ------------------------------------------------------------
    // 3. TC_19: Memory Boundary Accesses (Edges of 2KB SRAM)
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "TC_19: Testing Memory Boundaries: 0x0000_0000 and 0x0000_07FC", UVM_LOW)
    bus_trans(32'h0000_0000, 1'b1, 32'h1234_5678, ahb_seq_item::SIZE_32BIT, rdata);
    bus_trans(32'h0000_0000, 1'b0, 32'h0,         ahb_seq_item::SIZE_32BIT, rdata);

    bus_trans(32'h0000_07FC, 1'b1, 32'h8765_4321, ahb_seq_item::SIZE_32BIT, rdata);
    bus_trans(32'h0000_07FC, 1'b0, 32'h0,         ahb_seq_item::SIZE_32BIT, rdata);

    // ------------------------------------------------------------
    // 4. TC_45 & TC_46: Pipelined Bursts (INCR4 and WRAP4)
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "TC_45: Executing INCR4 Burst to Upper SRAM (0x0000_0400)", UVM_LOW)
    burst_incr4(32'h0000_0400, 1'b1);
    burst_incr4(32'h0000_0400, 1'b0);

    `uvm_info("STRESS_SEQ", "TC_46: Executing WRAP4 Burst at boundary 0x0000_040C", UVM_LOW)
    burst_wrap4(32'h0000_040C, 1'b1);
    burst_wrap4(32'h0000_040C, 1'b0);

    // ------------------------------------------------------------
    // 5. TC_62: Full Concurrent Subsystem Stress
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "TC_62: Launching Concurrent Timer, FIFO, and Memory Stress Traffic", UVM_LOW)

    // Enable Timer and FIFO
    bus_trans(32'h0000_1000, 1'b1, 32'h0000_0007, ahb_seq_item::SIZE_32BIT, rdata);
    // Start periodic timer
    bus_trans(32'h0000_1010, 1'b1, 32'h0000_0018, ahb_seq_item::SIZE_32BIT, rdata);
    bus_trans(32'h0000_1014, 1'b1, 32'h0000_0003, ahb_seq_item::SIZE_32BIT, rdata);

    // Interleaved stream of FIFO pushes/pops and SRAM writes
    for (int k = 0; k < 20; k++) begin
      bus_trans(32'h0000_1020, 1'b1, (32'h5755_0000 | k), ahb_seq_item::SIZE_32BIT, rdata);
      bus_trans(32'h0000_0500 + (k*4), 1'b1, (32'hFACE_0000 | k), ahb_seq_item::SIZE_32BIT, rdata);
      bus_trans(32'h0000_1020, 1'b0, 32'h0, ahb_seq_item::SIZE_32BIT, rdata);
      bus_trans(32'h0000_0500 + (k*4), 1'b0, 32'h0, ahb_seq_item::SIZE_32BIT, rdata);
    end

    // ------------------------------------------------------------
    // 6. COVERAGE CLOSURE: Sub-word Bursts, BURST_INCR, & Register Readbacks
    // ------------------------------------------------------------
    `uvm_info("STRESS_SEQ", "Closing Coverage Gaps: Driving 8/16-bit Bursts, BURST_INCR, and Reg Reads", UVM_LOW)

    // Half-word INCR4 Burst (TC_45, cross_size_x_burst)
    cur_addr = 32'h0000_0300;
    for (int i = 0; i < 4; i++) begin
      beat = ahb_seq_item::type_id::create("h_incr4_beat");
      start_item(beat);
      if (!beat.randomize() with {
        haddr  == cur_addr;
        hwrite == 1'b1;
        hwdata == 32'h55AA_55AA;
        hsize  == ahb_seq_item::SIZE_16BIT;
        hburst == ahb_seq_item::BURST_INCR4;
        htrans == (i == 0) ? ahb_seq_item::TRANS_NONSEQ : ahb_seq_item::TRANS_SEQ;
      }) `uvm_fatal("RND_FAIL", "Half-word INCR4 beat randomization failed");
      finish_item(beat);
      cur_addr += 2;
    end

    // Byte WRAP4 Burst (TC_46, cross_size_x_burst: 4 beats wrap in 4-byte boundary)
    cur_addr = 32'h0000_030E;
    for (int i = 0; i < 4; i++) begin
      beat = ahb_seq_item::type_id::create("b_wrap4_beat");
      start_item(beat);
      if (!beat.randomize() with {
        haddr  == cur_addr;
        hwrite == 1'b1;
        hwdata == 32'h1122_3344;
        hsize  == ahb_seq_item::SIZE_8BIT;
        hburst == ahb_seq_item::BURST_WRAP4;
        htrans == (i == 0) ? ahb_seq_item::TRANS_NONSEQ : ahb_seq_item::TRANS_SEQ;
      }) `uvm_fatal("RND_FAIL", "Byte WRAP4 beat randomization failed");
      finish_item(beat);
      cur_addr = 32'h0000_030C | (((cur_addr[1:0] + 1) % 4) & 2'b11);
    end

    // Undefined-Length Incrementing Burst (BURST_INCR - TC_47)
    cur_addr = 32'h0000_0340;
    for (int i = 0; i < 6; i++) begin
      beat = ahb_seq_item::type_id::create("incr_beat");
      start_item(beat);
      if (!beat.randomize() with {
        haddr  == cur_addr;
        hwrite == 1'b1;
        hwdata == (32'hABCD_0000 | i);
        hsize  == ahb_seq_item::SIZE_32BIT;
        hburst == ahb_seq_item::BURST_INCR;
        htrans == (i == 0) ? ahb_seq_item::TRANS_NONSEQ : ahb_seq_item::TRANS_SEQ;
      }) `uvm_fatal("RND_FAIL", "BURST_INCR beat randomization failed");
      finish_item(beat);
      cur_addr += 4;
    end

    // Configuration Register Readbacks
    bus_trans(32'h0000_1000, 1'b0, 32'h0, ahb_seq_item::SIZE_32BIT, rdata); // CTRL
    bus_trans(32'h0000_1008, 1'b0, 32'h0, ahb_seq_item::SIZE_32BIT, rdata); // INT_EN
    bus_trans(32'h0000_1010, 1'b0, 32'h0, ahb_seq_item::SIZE_32BIT, rdata); // TIMER_LOAD

    // Restore WAIT_CFG = 0
    bus_trans(32'h0000_102C, 1'b1, 32'h0000_0000, ahb_seq_item::SIZE_32BIT, rdata);
    #100ns;
  endtask : body

endclass : ahb_stress_seq

// ================================================================
// Test: Executes ahb_stress_seq
// ================================================================
class ahb_stress_test extends uvm_test;

  `uvm_component_utils(ahb_stress_test)

  ahb_env env;

  function new(string name = "ahb_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = ahb_env::type_id::create("env", this);
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    ahb_stress_seq s_seq;
    phase.raise_objection(this);

    s_seq = ahb_stress_seq::type_id::create("s_seq");
    `uvm_info("STRESS_TEST", "--- STARTING DAY 5 SUITE 4: CONCURRENT STRESS & COVERAGE CLOSURE ---", UVM_LOW)
    s_seq.start(env.master_agent.sequencer);

    phase.drop_objection(this);
  endtask : run_phase

endclass : ahb_stress_test
