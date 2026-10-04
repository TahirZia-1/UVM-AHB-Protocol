`ifndef AHB_ASSERTIONS_SV
`define AHB_ASSERTIONS_SV

module ahb_assertions (
  ahb_if bus
);

  // 1. Natural Address Alignment Rules
  property p_aligned_16bit;
    @(posedge bus.HCLK) disable iff (!bus.HRESETn)
    (bus.HSEL && bus.HTRANS[1] && (bus.HSIZE == 3'b001)) |-> (bus.HADDR[0] == 1'b0);
  endproperty

  property p_aligned_32bit;
    @(posedge bus.HCLK) disable iff (!bus.HRESETn)
    (bus.HSEL && bus.HTRANS[1] && (bus.HSIZE == 3'b010)) |-> (bus.HADDR[1:0] == 2'b00);
  endproperty

  assert_align_16: assert property (p_aligned_16bit)
    else $error("[SVA_ALIGN_16] AHB Rule Violation: 16-bit unaligned address 0x%08h", bus.HADDR);

  assert_align_32: assert property (p_aligned_32bit)
    else $error("[SVA_ALIGN_32] AHB Rule Violation: 32-bit unaligned address 0x%08h", bus.HADDR);

  // 2. Control Stability During Wait States
  property p_ctrl_stable_on_wait;
    @(posedge bus.HCLK) disable iff (!bus.HRESETn)
    (bus.HSEL && !bus.HREADYOUT) |=> ($stable(bus.HADDR) && $stable(bus.HWRITE) && $stable(bus.HSIZE) && $stable(bus.HBURST));
  endproperty

  assert_ctrl_stable: assert property (p_ctrl_stable_on_wait)
    else $error("[SVA_CTRL_STABLE] AHB Rule Violation: Control lines changed while HREADYOUT was low!");

  // 3. No 'X' or 'Z' on Bus Control Lines When Chip Selected
  property p_no_unknown_ctrl;
    @(posedge bus.HCLK) disable iff (!bus.HRESETn)
    bus.HSEL |-> (!$isunknown(bus.HTRANS) && !$isunknown(bus.HWRITE) && !$isunknown(bus.HSIZE) && !$isunknown(bus.HADDR));
  endproperty

  assert_no_unknown_ctrl: assert property (p_no_unknown_ctrl)
    else $error("[SVA_UNKNOWN_CTRL] AHB Rule Violation: Unknown (X/Z) detected on control lines during transfer!");

endmodule : ahb_assertions

`endif