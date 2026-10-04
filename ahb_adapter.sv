class ahb_adapter extends uvm_reg_adapter;

  `uvm_object_utils(ahb_adapter)

  function new(string name = "ahb_adapter");
    super.new(name);
    // AHB-Lite peripheral configuration
    supports_byte_enable = 0;
    provides_responses   = 0;
  endfunction : new

  // 1. High-level Register Operation -> Low-level Bus Transfer
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    ahb_seq_item item;

    item = ahb_seq_item::type_id::create("item");
    item.haddr  = rw.addr;
    item.hwrite = (rw.kind == UVM_WRITE) ? 1'b1 : 1'b0;
    if (item.hwrite) begin
      item.hwdata = rw.data;
    end
    item.hsize  = ahb_seq_item::SIZE_32BIT;
    item.hburst = ahb_seq_item::BURST_SINGLE;
    item.htrans = ahb_seq_item::TRANS_NONSEQ;
    item.hprot  = 4'b0000;

    return item;
  endfunction : reg2bus

  // 2. Low-level Bus Transfer -> High-level Register Operation
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    ahb_seq_item item;

    if (!$cast(item, bus_item)) begin
      `uvm_fatal("ADAPTER_CAST_FAIL", "bus_item is not of type ahb_seq_item")
      return;
    end

    rw.kind   = item.hwrite ? UVM_WRITE : UVM_READ;
    rw.addr   = item.haddr;
    rw.data   = item.hwrite ? item.hwdata : item.hrdata;
    rw.status = (item.hresp == 1'b0) ? UVM_IS_OK : UVM_NOT_OK;
  endfunction : bus2reg

endclass : ahb_adapter



