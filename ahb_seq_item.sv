class ahb_seq_item extends uvm_sequence_item;

  typedef enum logic [1:0] {
    TRANS_IDLE   = 2'b00,
    TRANS_BUSY   = 2'b01,
    TRANS_NONSEQ = 2'b10,
    TRANS_SEQ    = 2'b11 // all supports
  } trans_type_e;

  typedef enum logic [2:0] {
    SIZE_8BIT   = 3'b000,
    SIZE_16BIT  = 3'b001,
    SIZE_32BIT  = 3'b010, // dut supports till here
    SIZE_64BIT  = 3'b011,
    SIZE_128BIT = 3'b100,
    SIZE_256BIT = 3'b101,
    SIZE_512BIT = 3'b110,
    SIZE_1024BIT= 3'b111
  } transfer_size_e;

  typedef enum logic [2:0] {
    BURST_SINGLE = 3'b000,
    BURST_INCR   = 3'b001,
    BURST_WRAP4  = 3'b010,
    BURST_INCR4  = 3'b011, // dut supports till here
    BURST_WRAP8  = 3'b100,
    BURST_INCR8  = 3'b101,
    BURST_WRAP16 = 3'b110,
    BURST_INCR16 = 3'b111
  } burst_type_e;

  rand bit [31:0]        haddr;
  rand trans_type_e      htrans;
  rand bit               hwrite;
  rand transfer_size_e   hsize;
  rand burst_type_e      hburst;
  rand bit [3:0]         hprot;
  rand bit [31:0]        hwdata;

  bit [31:0]             hrdata;
  bit                    hresp;
  int                    wait_cycles;

  `uvm_object_utils_begin(ahb_seq_item)
    `uvm_field_int       (haddr,       UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum      (trans_type_e, htrans, UVM_ALL_ON)
    `uvm_field_int       (hwrite,      UVM_ALL_ON | UVM_BIN)
    `uvm_field_enum      (transfer_size_e, hsize, UVM_ALL_ON)
    `uvm_field_enum      (burst_type_e, hburst, UVM_ALL_ON)
    `uvm_field_int       (hprot,       UVM_ALL_ON | UVM_BIN)
    `uvm_field_int       (hwdata,      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int       (hrdata,      UVM_ALL_ON | UVM_HEX)
    `uvm_field_int       (hresp,       UVM_ALL_ON | UVM_BIN)
    `uvm_field_int       (wait_cycles, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  constraint valid_size_c {
    soft hsize inside {SIZE_8BIT, SIZE_16BIT, SIZE_32BIT};
  }

  constraint valid_burst_c {
    soft hburst inside {BURST_SINGLE, BURST_INCR, BURST_WRAP4, BURST_INCR4};
  }

  constraint align_c {
    if (hsize == SIZE_16BIT) {
      soft haddr[0] == 1'b0;
    }
    else if (hsize == SIZE_32BIT) {
      soft haddr[1:0] == 2'b00;
    }
  }

  constraint valid_addr_c {
    soft haddr inside {
      [32'h0000_0000 : 32'h0000_07FF],
      32'h0000_1000, 32'h0000_1004, 32'h0000_1008, 32'h0000_100C,
      32'h0000_1010, 32'h0000_1014, 32'h0000_1018, 32'h0000_1020,
      32'h0000_1024, 32'h0000_1028, 32'h0000_102C
    };
  }

  constraint trans_type_c {
    soft htrans inside {TRANS_NONSEQ, TRANS_SEQ}; // 2'b10, 2'b11
  }

  function new(string name = "ahb_seq_item");
    super.new(name);
  endfunction : new

  virtual function string convert2string();
    return $sformatf("HADDR=0x%08h | HWRITE=%0b | HSIZE=%0s | HBURST=%0s | HTRANS=%0s | HWDATA=0x%08h | HRDATA=0x%08h | HRESP=%0b | WAITS=%0d",
                     haddr, hwrite, hsize.name(), hburst.name(), htrans.name(), hwdata, hrdata, hresp, wait_cycles);
  endfunction : convert2string

endclass : ahb_seq_item
    
    
    