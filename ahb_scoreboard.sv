`ifndef AHB_SCOREBOARD_SV
`define AHB_SCOREBOARD_SV

`uvm_analysis_imp_decl(_bus)
`uvm_analysis_imp_decl(_irq)

class ahb_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(ahb_scoreboard)

  // Analysis Imports
  uvm_analysis_imp_bus #(ahb_seq_item, ahb_scoreboard) bus_export;
  uvm_analysis_imp_irq #(bit,          ahb_scoreboard) irq_export;

  // Golden Reference Models
  protected bit [31:0] sram_model[bit [31:0]];
  protected bit [31:0] reg_model[bit [31:0]];
  protected bit        latest_irq_state = 1'b0;

  // Diagnostic Counters
  int unsigned match_count         = 0;
  int unsigned mismatch_count      = 0;
  int unsigned total_trans_checked = 0;
  int unsigned irq_toggle_count    = 0;

  function new(string name = "ahb_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    bus_export = new("bus_export", this);
    irq_export = new("irq_export", this);

    // Initial hardware reset defaults
    reg_model[32'h0000_1000] = 32'h0000_0000; // CTRL
    reg_model[32'h0000_1004] = 32'h0000_0000; // STATUS
    reg_model[32'h0000_1008] = 32'h0000_0000; // INT_EN
    reg_model[32'h0000_100C] = 32'h0000_0000; // INT_STATUS
    reg_model[32'h0000_1010] = 32'h0000_0000; // TIMER_LOAD
    reg_model[32'h0000_1014] = 32'h0000_0000; // TIMER_CTRL
    reg_model[32'h0000_1028] = 32'h0000_0000; // SCRATCH
    reg_model[32'h0000_102C] = 32'h0000_0000; // REV_ID (RTL reset value: 0)
  endfunction : build_phase

  // 1. Ingest Bus Items from ahb_monitor
  virtual function void write_bus(ahb_seq_item item);
    bit [31:0] expected_data;
    bit        check_performed = 0;

    total_trans_checked++;

    // If slave returned an error response (HRESP=1), validate and skip data check
    if (item.hresp == 1'b1) begin
      `uvm_info("SB_ERR_RESP", $sformatf("Verified HRESP=1 (Slave Error Response) for Addr: 0x%08h", item.haddr), UVM_MEDIUM)
      return;
    end

    if (item.hwrite) begin
      // WRITE TRANSACTION: Update reference models
      if (item.haddr inside {[32'h0000_0000 : 32'h0000_07FF]}) begin
        sram_model[item.haddr] = item.hwdata;
        `uvm_info("SB_RAM_WR", $sformatf("SRAM Model Updated: Addr=0x%08h Data=0x%08h", item.haddr, item.hwdata), UVM_HIGH)
      end
      // Writable configuration and scratch registers
      else if (item.haddr inside {32'h0000_1000, 32'h0000_1008, 32'h0000_1010, 32'h0000_1014, 32'h0000_1028}) begin
        reg_model[item.haddr] = item.hwdata;
        `uvm_info("SB_REG_WR", $sformatf("Register Model Updated: Addr=0x%08h Data=0x%08h", item.haddr, item.hwdata), UVM_HIGH)
      end
      // FIFO Write Data window (handled dynamically by FIFO IP)
      else if (item.haddr == 32'h0000_1020) begin
        `uvm_info("SB_FIFO_WR", $sformatf("Monitored FIFO Push: Data=0x%08h", item.hwdata), UVM_HIGH)
      end
    end 
    else begin
      // READ TRANSACTION: Compare read data against reference models

      // 1. Dynamic Peripheral Registers (Bypass static register checks)
      if (item.haddr inside {32'h0000_100C, 32'h0000_1018, 32'h0000_1020, 32'h0000_1024}) begin
        `uvm_info("SB_DYN_REG", $sformatf("Monitored Dynamic Reg: Addr=0x%08h Data=0x%08h (Bypassed static model)", 
                  item.haddr, item.hrdata), UVM_HIGH)
        return;
      end

      // 2. SRAM Address Space
      else if (item.haddr inside {[32'h0000_0000 : 32'h0000_07FF]}) begin
        if (sram_model.exists(item.haddr)) begin
          expected_data = sram_model[item.haddr];
          check_performed = 1;
        end else begin
          `uvm_error("SB_UNMODELED_RD", $sformatf("Read from unwritten SRAM addr 0x%08h! Read data = 0x%08h", item.haddr, item.hrdata))
        end
      end 

      // 3. Static Configuration Registers
      else if (reg_model.exists(item.haddr)) begin
        expected_data = reg_model[item.haddr];
        check_performed = 1;
      end 

      // 4. Out of bounds / Unmapped Read Access
      else begin
        `uvm_error("SB_UNMODELED_RD", $sformatf("Read from unmodeled Register addr 0x%08h!", item.haddr))
      end

      // Execute Comparison
      if (check_performed) begin
        if (item.hrdata === expected_data) begin
          match_count++;
          `uvm_info("SB_MATCH", $sformatf("PASS: Addr 0x%08h | Read=0x%08h Expected=0x%08h", item.haddr, item.hrdata, expected_data), UVM_MEDIUM)
        end else begin
          mismatch_count++;
          `uvm_error("SB_MISMATCH", $sformatf("FAIL: Addr 0x%08h | Read=0x%08h Expected=0x%08h", item.haddr, item.hrdata, expected_data))
        end
      end
    end
  endfunction : write_bus

  // 2. Ingest Sideband Interrupts from irq_monitor
  virtual function void write_irq(bit irq_val);
    latest_irq_state = irq_val;
    irq_toggle_count++;
    `uvm_info("SB_IRQ", $sformatf("Interrupt state change recorded: IRQ = %0b", irq_val), UVM_LOW)
  endfunction : write_irq

  // 3. Final Simulation Report
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("  TOTAL TRANSACTIONS CHECKED : %0d", total_trans_checked), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("  DATA MATCHES               : %0d", match_count), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("  DATA MISMATCHES            : %0d", mismatch_count), UVM_NONE)
    `uvm_info("SB_REPORT", $sformatf("  IRQ TRANSITIONS            : %0d", irq_toggle_count), UVM_NONE)
    `uvm_info("SB_REPORT", "--------------------------------------------------", UVM_NONE)

    if (mismatch_count > 0) begin
      `uvm_error("FINAL_STATUS", "TEST FAILED: Scoreboard detected data mismatches.")
    end else begin
      `uvm_info("FINAL_STATUS", "TEST PASSED: All monitored transactions matched golden models.", UVM_NONE)
    end
  endfunction : report_phase

endclass : ahb_scoreboard

`endif