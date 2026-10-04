class ahb_driver extends uvm_driver #(ahb_seq_item);

  `uvm_component_utils(ahb_driver)

  virtual ahb_if vif;

  function new(string name = "ahb_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV_NO_VIF", "Virtual interface 'vif' not found in uvm_config_db")
    end
  endfunction : build_phase


  virtual task run_phase(uvm_phase phase);
    reset_signals();

    wait(vif.HRESETn == 1'b1);
    @(vif.master_cb);
raise
    forever begin
      
      seq_item_port.get_next_item(req);
      drive_transfer(req);
      seq_item_port.item_done();
    end
    drop
  endtask : run_phase


  virtual task reset_signals();
    vif.master_cb.HSEL   <= 1'b0;
    vif.master_cb.HADDR  <= 32'h0000_0000;
    vif.master_cb.HTRANS <= 2'b00;
    vif.master_cb.HWRITE <= 1'b0;
    vif.master_cb.HSIZE  <= 3'b010; // for 32 bit
    vif.master_cb.HBURST <= 3'b000;
    vif.master_cb.HPROT  <= 4'b0000;
    vif.master_cb.HWDATA <= 32'h0000_0000;
    vif.master_cb.HREADY <= 1'b1; // slave is ready
  endtask : reset_signals

  virtual task drive_transfer(ahb_seq_item trans);
    @(vif.master_cb);
    while (!vif.master_cb.HREADYOUT) begin
      @(vif.master_cb);
    end

    // 2. Address Phase
    vif.master_cb.HSEL   <= 1'b1;
    vif.master_cb.HADDR  <= trans.haddr;
    vif.master_cb.HTRANS <= trans.htrans;
    vif.master_cb.HWRITE <= trans.hwrite;
    vif.master_cb.HSIZE  <= trans.hsize;
    vif.master_cb.HBURST <= trans.hburst;
    vif.master_cb.HPROT  <= trans.hprot;
    vif.master_cb.HREADY <= 1'b1;

    // Wait 1 cycle for slave to sample the address phase
    @(vif.master_cb);
    while (!vif.master_cb.HREADYOUT) begin
      @(vif.master_cb);
    end

    // 3. Data Phase
    // back to IDLE, so that slave doesn't write it 2 times
    vif.master_cb.HSEL   <= 1'b0;
    vif.master_cb.HTRANS <= 2'b00;

    if (trans.hwrite) begin
      vif.master_cb.HWDATA <= trans.hwdata;
    end else begin
      vif.master_cb.HWDATA <= 32'h0000_0000;
    end

    // Wait for slave to complete data phase
    @(vif.master_cb);
    trans.wait_cycles = 0;
    while (!vif.master_cb.HREADYOUT) begin
      trans.wait_cycles++;
      @(vif.master_cb);
    end

    // response from DUT
    if (!trans.hwrite) begin
      trans.hrdata = vif.master_cb.HRDATA;
    end
    trans.hresp = vif.master_cb.HRESP;
  endtask : drive_transfer

endclass : ahb_driver
