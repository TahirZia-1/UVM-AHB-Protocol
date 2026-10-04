`timescale 1ns/1ps

interface ahb_if #(
  parameter int ADDR_W = 32,
  parameter int DATA_W = 32
)(
  input logic HCLK
);

  // Global Asynchronous Control
  logic              HRESETn;

  // Master Address & Control Phase Signals
  logic              HSEL;
  logic [ADDR_W-1:0] HADDR;
  logic [1:0]        HTRANS;
  logic              HWRITE;
  logic [2:0]        HSIZE;
  logic [2:0]        HBURST;
  logic [3:0]        HPROT;

  // Data & Handshake Signals
  logic [DATA_W-1:0] HWDATA;
  logic              HREADY;
  logic [DATA_W-1:0] HRDATA;
  logic              HREADYOUT;
  logic              HRESP;

  // Sideband Output
  logic              IRQ;

  // ----------------------------------------------------
  // Driver Clocking Block
  // ----------------------------------------------------
  clocking master_cb @(posedge HCLK);
    default input #1step output #1ns;
    output HSEL, HADDR, HTRANS, HWRITE, HSIZE, HBURST, HPROT, HWDATA, HREADY;
    input  HRDATA, HREADYOUT, HRESP, IRQ;
  endclocking

  // ----------------------------------------------------
  // Monitor Clocking Block
  // ----------------------------------------------------
  clocking monitor_cb @(posedge HCLK);
    default input #1step;
    input HSEL, HADDR, HTRANS, HWRITE, HSIZE, HBURST, HPROT, HWDATA, HREADY;
    input HRDATA, HREADYOUT, HRESP, IRQ;
  endclocking

  // ----------------------------------------------------
  // Modports
  // ----------------------------------------------------
  modport master_mp  (clocking master_cb,  input HRESETn);
  modport monitor_mp (clocking monitor_cb, input HRESETn);
  modport irq_mp     (input HCLK, HRESETn, IRQ);

endinterface : ahb_if