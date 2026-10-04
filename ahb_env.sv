`ifndef AHB_ENV_SV
`define AHB_ENV_SV

class ahb_env extends uvm_env;

  `uvm_component_utils(ahb_env)

  ahb_agent      master_agent;
  irq_monitor    irq_mon;
  ahb_reg_block  reg_block;
  ahb_adapter    adapter;
  ahb_scoreboard scoreboard;
  ahb_coverage   coverage;

  function new(string name = "ahb_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    master_agent = ahb_agent::type_id::create("master_agent", this);
    irq_mon      = irq_monitor::type_id::create("irq_mon", this);
    scoreboard   = ahb_scoreboard::type_id::create("scoreboard", this);
    coverage     = ahb_coverage::type_id::create("coverage", this);

    // RAL Infrastructure
    reg_block = ahb_reg_block::type_id::create("reg_block");
    reg_block.build();
    adapter = ahb_adapter::type_id::create("adapter", this);
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // RAL to Sequencer binding
    reg_block.default_map.set_sequencer(master_agent.sequencer, adapter);
    reg_block.default_map.set_auto_predict(1);

    // Scoreboard analysis connections
    master_agent.item_collected_port.connect(scoreboard.bus_export);
    irq_mon.irq_port.connect(scoreboard.irq_export);

    // Functional Coverage connection
    master_agent.item_collected_port.connect(coverage.analysis_export);
  endfunction : connect_phase

endclass : ahb_env

`endif