`ifndef AHB_AGENT_SV
`define AHB_AGENT_SV

class ahb_agent extends uvm_agent;

  `uvm_component_utils(ahb_agent)

  ahb_sequencer                 sequencer;
  ahb_driver                    driver;
  ahb_monitor                   monitor;

  uvm_analysis_port #(ahb_seq_item) item_collected_port;

  function new(string name = "ahb_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    item_collected_port = new("item_collected_port", this);
    monitor = ahb_monitor::type_id::create("monitor", this);

    if (get_is_active() == UVM_ACTIVE) begin
      sequencer = ahb_sequencer::type_id::create("sequencer", this);
      driver    = ahb_driver::type_id::create("driver", this);
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    monitor.item_collected_port.connect(this.item_collected_port);

    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : ahb_agent

`endif