`timescale 1ns/1ps

module top_example;

  logic HCLK=0;
  always #5 HCLK=~HCLK;

  ahb_if ahb(HCLK);

  ahb_lite_peripheral dut(
    .HCLK(HCLK),
    .HRESETn(ahb.HRESETn),
    .HSEL(ahb.HSEL),
    .HADDR(ahb.HADDR),
    .HTRANS(ahb.HTRANS),
    .HWRITE(ahb.HWRITE),
    .HSIZE(ahb.HSIZE),
    .HBURST(ahb.HBURST),
    .HPROT(ahb.HPROT),
    .HWDATA(ahb.HWDATA),
    .HREADY(ahb.HREADY),
    .HRDATA(ahb.HRDATA),
    .HREADYOUT(ahb.HREADYOUT),
    .HRESP(ahb.HRESP),
    .IRQ()
  );

endmodule
