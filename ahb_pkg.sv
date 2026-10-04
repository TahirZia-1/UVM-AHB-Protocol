`ifndef AHB_PKG_SV
`define AHB_PKG_SV

package ahb_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "ahb_seq_item.sv"
  `include "ahb_sequencer.sv"
  `include "ahb_driver.sv"
  `include "ahb_monitor.sv"
  `include "irq_monitor.sv"
  `include "ahb_agent.sv"

  // RAL Components
  `include "ahb_adapter.sv"
  `include "ahb_reg_block.sv"

  // Day 3 Scoreboard
  `include "ahb_scoreboard.sv"

  // Day 4 Functional Coverage
  `include "ahb_coverage.sv"

  `include "ahb_env.sv"

  // Sequences and Tests
  `include "ahb_sanity_seq.sv"
  `include "ahb_sanity_test.sv"
  `include "ahb_ral_seq.sv"
  `include "ahb_ral_test.sv"
  `include "ahb_memory_seq.sv"
  `include "ahb_functional_test.sv"

  `include "ahb_error_test.sv"  // Error Injection & Protocol Negative Testing
  `include "ahb_peripheral_test.sv"  // Peripheral Hardware Verification
  `include "ahb_interrupt_test.sv"  // Interrupts & W1C Logic
  `include "ahb_stress_test.sv" // Full Subsystem Concurrent Stress & Burst Exerciser
  `include "ahb_regression_test.sv" // Regression Test
  
endpackage : ahb_pkg

`endif