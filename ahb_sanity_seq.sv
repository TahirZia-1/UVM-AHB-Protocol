`ifndef AHB_SANITY_SEQ_SV
`define AHB_SANITY_SEQ_SV

class ahb_sanity_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_sanity_seq)

  function new(string name = "ahb_sanity_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_seq_item item;

    // 1. Write 0xDEAD_BEEF to SCRATCH (0x1028)
    item = ahb_seq_item::type_id::create("item_wr");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_1028;
      hwrite == 1'b1;
      hwdata == 32'hDEAD_BEEF;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failed on item_wr");
    finish_item(item);

    // 2. Read back from SCRATCH (0x1028)
    item = ahb_seq_item::type_id::create("item_rd");
    start_item(item);
    if (!item.randomize() with {
      haddr  == 32'h0000_1028;
      hwrite == 1'b0;
      hsize  == ahb_seq_item::SIZE_32BIT;
      hburst == ahb_seq_item::BURST_SINGLE;
      htrans == ahb_seq_item::TRANS_NONSEQ;
    }) `uvm_fatal("RND_FAIL", "Randomization failed on item_rd");
    finish_item(item);

    `uvm_info("SANITY_SEQ", $sformatf("Readback value from 0x1028: 0x%08h", item.hrdata), UVM_LOW)
  endtask : body

endclass : ahb_sanity_seq

`endif