class ahb_coverage extends uvm_subscriber #(ahb_seq_item);

  `uvm_component_utils(ahb_coverage)

  // Flat sample variables (eliminates *E,ILLHIN hierarchical references)
  bit [31:0] haddr;
  bit        hwrite;
  bit [2:0]  hsize;
  bit [2:0]  hburst;
  bit [1:0]  htrans;
  bit        hresp;

  covergroup cg_ahb;
    option.per_instance = 0;

    // 1. Memory and Register Address Map (TC_16 - TC_20, TC_56 - TC_58)
    cp_addr: coverpoint haddr {
      bins ram_lower       = {[32'h0000_0000 : 32'h0000_03FF]};
      bins ram_upper       = {[32'h0000_0400 : 32'h0000_07FC]};
      bins ram_hole        = {[32'h0000_0800 : 32'h0000_0FFF]};
      bins reg_ctrl_status = {32'h0000_1000, 32'h0000_1004};
      bins reg_int         = {32'h0000_1008, 32'h0000_100C};
      bins reg_timer       = {32'h0000_1010, 32'h0000_1014, 32'h0000_1018};
      bins reg_fifo        = {32'h0000_1020, 32'h0000_1024};
      bins reg_scratch_rev = {32'h0000_1028, 32'h0000_102C};
      bins reg_gap_hole    = {32'h0000_101C};
      bins out_of_bounds   = {[32'h0000_2000 : 32'h0000_FFFF]};
    }

    // 2. Bus Direction
    cp_write: coverpoint hwrite {
      bins read  = {1'b0};
      bins write = {1'b1};
    }

    // 3. Transfer Size (TC_17, TC_18, TC_55)
    cp_size: coverpoint hsize {
      bins size_8bit   = {3'b000};
      bins size_16bit  = {3'b001};
      bins size_32bit  = {3'b010};
      bins size_unsupp = {[3'b011 : 3'b111]};
    }

    // 4. Burst Modes (TC_44 - TC_47)
    cp_burst: coverpoint hburst {
      bins burst_single = {3'b000};
      bins burst_incr   = {3'b001};
      bins burst_wrap4  = {3'b010};
      bins burst_incr4  = {3'b011};
    }

    // 5. Transfer Types (TC_48 - TC_50)
    cp_trans: coverpoint htrans {
      bins trans_nonseq = {2'b10};
      bins trans_seq    = {2'b11};
    }

    // 6. Protocol Slave Response (TC_60)
    cp_resp: coverpoint hresp {
      bins resp_okay  = {1'b0};
      bins resp_error = {1'b1};
    }

    // 7. Cross Coverage: Transfer Size vs. Burst Type
    cross_size_x_burst: cross cp_size, cp_burst {
      ignore_bins ign_unsupported = binsof(cp_size.size_unsupp);
    }

    // 8. Cross Coverage: Address Region vs. Direction
    cross_addr_x_write: cross cp_addr, cp_write;

    // 9. Cross Coverage: Direction vs. Response
    cross_write_x_resp: cross cp_write, cp_resp;

  endgroup : cg_ahb

  function new(string name = "ahb_coverage", uvm_component parent = null);
    super.new(name, parent);
    cg_ahb = new();
  endfunction : new

  virtual function void write(ahb_seq_item t);
    this.haddr  = t.haddr;
    this.hwrite = t.hwrite;
    this.hsize  = t.hsize;
    this.hburst = t.hburst;
    this.htrans = t.htrans;
    this.hresp  = t.hresp;

    cg_ahb.sample();
  endfunction : write

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("COV_REPORT", "--------------------------------------------------", UVM_NONE)
    `uvm_info("COV_REPORT", $sformatf("   TOTAL FUNCTIONAL COVERAGE : %0.2f%%", cg_ahb.get_coverage()), UVM_NONE)
    `uvm_info("COV_REPORT", "--------------------------------------------------", UVM_NONE)
  endfunction : report_phase

endclass : ahb_coverage