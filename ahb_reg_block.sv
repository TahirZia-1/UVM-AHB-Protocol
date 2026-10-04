// ----------------------------------------------------
// 1. Control Register (0x1000) - R/W
// ----------------------------------------------------
class reg_ctrl extends uvm_reg;
  `uvm_object_utils(reg_ctrl)
  rand uvm_reg_field val;

  function new(string name = "reg_ctrl");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    val = uvm_reg_field::type_id::create("val");
    // (parent, size, lsb_pos, access, volatile, reset_val, has_reset, is_rand, individually_accessible)
    val.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 1);
  endfunction
endclass

// ----------------------------------------------------
// 2. Status Register (0x1004) - Read-Only
// ----------------------------------------------------
class reg_status extends uvm_reg;
  `uvm_object_utils(reg_status)
  uvm_reg_field val;

  function new(string name = "reg_status");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    val = uvm_reg_field::type_id::create("val");
    val.configure(this, 32, 0, "RO", 1, 32'h0000_0000, 1, 0, 1);
  endfunction
endclass

// ----------------------------------------------------
// 3. Scratchpad Register (0x1028) - R/W
// ----------------------------------------------------
class reg_scratch extends uvm_reg;
  `uvm_object_utils(reg_scratch)
  rand uvm_reg_field val;

  function new(string name = "reg_scratch");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    val = uvm_reg_field::type_id::create("val");
    val.configure(this, 32, 0, "RW", 0, 32'h0000_0000, 1, 1, 1);
  endfunction
endclass

// ----------------------------------------------------
// 4. Revision ID Register (0x102C) - Read-Only
// ----------------------------------------------------
class reg_rev_id extends uvm_reg;
  `uvm_object_utils(reg_rev_id)
  uvm_reg_field val;

  function new(string name = "reg_rev_id");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    val = uvm_reg_field::type_id::create("val");
    val.configure(this, 32, 0, "RO", 0, 32'h0000_0000, 1, 0, 1);
  endfunction
endclass

// ----------------------------------------------------
// Top-Level Register Block
// ----------------------------------------------------
class ahb_reg_block extends uvm_reg_block;

  `uvm_object_utils(ahb_reg_block)

  rand reg_ctrl    ctrl;
  rand reg_status  status;
  rand reg_scratch scratch;
  rand reg_rev_id  rev_id;

  uvm_reg_map default_map;

  function new(string name = "ahb_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    // 1. Instantiate Registers
    ctrl    = reg_ctrl::type_id::create("ctrl");
    ctrl.configure(this);
    ctrl.build();

    status  = reg_status::type_id::create("status");
    status.configure(this);
    status.build();

    scratch = reg_scratch::type_id::create("scratch");
    scratch.configure(this);
    scratch.build();

    rev_id  = reg_rev_id::type_id::create("rev_id");
    rev_id.configure(this);
    rev_id.build();

    // 2. Create and Populate Address Map (Base: 0x0, 4 bytes width)
    default_map = create_map("default_map", 32'h0000_0000, 4, UVM_LITTLE_ENDIAN);
    default_map.add_reg(ctrl,    32'h0000_1000, "RW");
    default_map.add_reg(status,  32'h0000_1004, "RO");
    default_map.add_reg(scratch, 32'h0000_1028, "RW");
    default_map.add_reg(rev_id,  32'h0000_102C, "RO");

    lock_model();
  endfunction : build

endclass : ahb_reg_block



