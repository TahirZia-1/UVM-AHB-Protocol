`ifndef IRQ_MONITOR_SV
`define IRQ_MONITOR_SV

class irq_monitor extends uvm_monitor;

  `uvm_component_utils(irq_monitor)

  virtual ahb_if vif;
  uvm_analysis_port #(bit) irq_port;

  function new(string name = "irq_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    irq_port = new("irq_port", this);

    if (!uvm_config_db#(virtual ahb_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("IRQ_MON_NO_VIF", "Virtual interface 'vif' not found in uvm_config_db")
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    bit prev_irq = 1'b0;

    @(posedge vif.HRESETn);

    forever begin
      @(posedge vif.HCLK);

      if (!vif.HRESETn) begin
        prev_irq = 1'b0;
        continue;
      end

      if (vif.IRQ !== prev_irq) begin
        prev_irq = vif.IRQ;
        irq_port.write(vif.IRQ);
        `uvm_info("IRQ_MON", $sformatf("IRQ pin changed state to %0b at time %0t", vif.IRQ, $time), UVM_HIGH)
      end
    end
  endtask : run_phase

endclass : irq_monitor

`endif