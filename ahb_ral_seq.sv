class ahb_ral_seq extends uvm_sequence;

  `uvm_object_utils(ahb_ral_seq)

  ahb_reg_block rm;

  function new(string name = "ahb_ral_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    uvm_status_e    status;
    uvm_reg_data_t  rdata;

    if (rm == null) begin
      `uvm_fatal("RAL_SEQ_NO_RM", "Register model handle 'rm' is null!")
    end

    // 1. Read REV_ID register (0x102C)
    rm.rev_id.read(status, rdata, .parent(this));
    `uvm_info("RAL_SEQ", $sformatf("Read REV_ID (0x102C) = 0x%08h | Status: %s", rdata, status.name()), UVM_LOW)

    // 2. Write and Read-back SCRATCH register (0x1028)
    `uvm_info("RAL_SEQ", "Writing 0xCAFE_BABE to SCRATCH register via RAL...", UVM_LOW)
    rm.scratch.write(status, 32'hCAFE_BABE, .parent(this));

    rm.scratch.read(status, rdata, .parent(this));
    `uvm_info("RAL_SEQ", $sformatf("Readback SCRATCH (0x1028) = 0x%08h | Status: %s", rdata, status.name()), UVM_LOW)

    // Check data integrity
    if (rdata == 32'hCAFE_BABE) begin
      `uvm_info("RAL_SEQ", "SCRATCH Register RAL check PASSED!", UVM_LOW)
    end else begin
      `uvm_error("RAL_SEQ", $sformatf("SCRATCH mismatch! Expected: 0xCAFE_BABE, Got: 0x%08h", rdata))
    end
  endtask : body

endclass : ahb_ral_seq



