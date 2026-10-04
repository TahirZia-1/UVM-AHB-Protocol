class ahb_memory_seq extends uvm_sequence #(ahb_seq_item);

  `uvm_object_utils(ahb_memory_seq)

  function new(string name = "ahb_memory_seq");
    super.new(name);
  endfunction : new

  virtual task body();
    ahb_seq_item item;
    bit [31:0] start_addr = 32'h0000_0100;
    int num_words = 8;

    `uvm_info("MEM_SEQ", $sformatf("Executing SRAM burst write: %0d words starting at 0x%08h", num_words, start_addr), UVM_LOW)

    // 1. Write sequential words to internal SRAM
    for (int i = 0; i < num_words; i++) begin
      item = ahb_seq_item::type_id::create("item_mem_wr");
      start_item(item);
      if (!item.randomize() with {
        haddr  == start_addr + (i * 4);
        hwrite == 1'b1;
        hwdata == 32'hA000_0000 + (i * 32'h0011_1111);
        hsize  == ahb_seq_item::SIZE_32BIT;
        hburst == ahb_seq_item::BURST_SINGLE;
        htrans == ahb_seq_item::TRANS_NONSEQ;
      }) `uvm_fatal("RND_FAIL", "Randomization failed on item_mem_wr");
      finish_item(item);
    end

    // 2. Read back each written word from internal SRAM
    `uvm_info("MEM_SEQ", "Executing SRAM readback verification...", UVM_LOW)
    for (int i = 0; i < num_words; i++) begin
      item = ahb_seq_item::type_id::create("item_mem_rd");
      start_item(item);
      if (!item.randomize() with {
        haddr  == start_addr + (i * 4);
        hwrite == 1'b0;
        hsize  == ahb_seq_item::SIZE_32BIT;
        hburst == ahb_seq_item::BURST_SINGLE;
        htrans == ahb_seq_item::TRANS_NONSEQ;
      }) `uvm_fatal("RND_FAIL", "Randomization failed on item_mem_rd");
      finish_item(item);
    end
  endtask : body

endclass : ahb_memory_seq