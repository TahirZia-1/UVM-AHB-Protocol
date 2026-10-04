class ahb_monitor extends uvm_monitor;

  `uvm_component_utils(ahb_monitor)

  virtual ahb_if vif;
  uvm_analysis_port #(ahb_seq_item) item_collected_port;

  typedef struct {
    bit [31:0]                  haddr;
    ahb_seq_item::trans_type_e  htrans;
    bit                         hwrite;
    ahb_seq_item::transfer_size_e hsize;
    ahb_seq_item::burst_type_e  hburst;
    bit [3:0]                   hprot;
  } addr_phase_s;

  protected addr_phase_s pending_trans_q[$]; // a buffer for storing the signals of the address phase before it changes

  function new(string name = "ahb_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    item_collected_port = new("item_collected_port", this);

    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON_NO_VIF", "Virtual interface 'vif' not found in uvm_config_db")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);

      if (!vif.HRESETn) begin
        pending_trans_q.delete();
        continue;
      end

      // 1. Data Phase Sampling
      if (vif.monitor_cb.HREADYOUT && pending_trans_q.size() > 0) begin
        addr_phase_s completed_addr;
        ahb_seq_item collected_item;

        completed_addr = pending_trans_q.pop_front();
        collected_item = ahb_seq_item::type_id::create("collected_item");

        collected_item.haddr  = completed_addr.haddr;
        collected_item.htrans = completed_addr.htrans;
        collected_item.hwrite = completed_addr.hwrite;
        collected_item.hsize  = completed_addr.hsize;
        collected_item.hburst = completed_addr.hburst;
        collected_item.hprot  = completed_addr.hprot;

        collected_item.hwdata = vif.monitor_cb.HWDATA;
        collected_item.hrdata = vif.monitor_cb.HRDATA;
        collected_item.hresp  = vif.monitor_cb.HRESP;

        item_collected_port.write(collected_item);
      end

      // 2. Address Phase Sampling
      if (vif.monitor_cb.HSEL && vif.monitor_cb.HREADYOUT) begin
        if (vif.monitor_cb.HTRANS inside {2'b10, 2'b11}) begin
          addr_phase_s new_addr;
          new_addr.haddr  = vif.monitor_cb.HADDR;
          new_addr.htrans = ahb_seq_item::trans_type_e'(vif.monitor_cb.HTRANS);
          new_addr.hwrite = vif.monitor_cb.HWRITE;
          new_addr.hsize  = ahb_seq_item::transfer_size_e'(vif.monitor_cb.HSIZE);
          new_addr.hburst = ahb_seq_item::burst_type_e'(vif.monitor_cb.HBURST);
          new_addr.hprot  = vif.monitor_cb.HPROT;

          pending_trans_q.push_back(new_addr);
        end
      end
    end
  endtask : run_phase

endclass : ahb_monitor
