`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import ahb_pkg::*;

module top_tb;

  // 1. Clock Generation (100 MHz / 10 ns period)
  logic HCLK = 0;
  always #5 HCLK = ~HCLK;

  // 2. Physical Interface Instance
  ahb_if #(32, 32) ahb(HCLK);

  // 3. DUT Instantiation
  ahb_lite_peripheral dut (
    .HCLK      (ahb.HCLK),
    .HRESETn   (ahb.HRESETn),
    .HSEL      (ahb.HSEL),
    .HADDR     (ahb.HADDR),
    .HTRANS    (ahb.HTRANS),
    .HWRITE    (ahb.HWRITE),
    .HSIZE     (ahb.HSIZE),
    .HBURST    (ahb.HBURST),
    .HPROT     (ahb.HPROT),
    .HWDATA    (ahb.HWDATA),
    .HREADY    (ahb.HREADY),
    .HRDATA    (ahb.HRDATA),
    .HREADYOUT (ahb.HREADYOUT),
    .HRESP     (ahb.HRESP),
    .IRQ       (ahb.IRQ)
  );

  // 4. Standalone SVA Protocol Checker (Direct Instantiation, No Bind)
  ahb_assertions u_ahb_assert (
    .bus (ahb)
  );

  // 5. Testbench Configuration & UVM Run Phase
  initial begin
    uvm_config_db#(virtual ahb_if)::set(null, "*", "vif", ahb);
    run_test();
  end

  // 6. Asynchronous Reset Assertion
  initial begin
    ahb.HRESETn = 1'b0;
    #25;
    ahb.HRESETn = 1'b1;
  end

endmodule : top_tb