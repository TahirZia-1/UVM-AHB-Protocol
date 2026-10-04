module ahb_timer(
  input  logic clk,
  input  logic rst_n,
  input  logic enable,
  input  logic start,
  input  logic periodic,
  input  logic irq_enable,
  input  logic [31:0] load,
  output logic [31:0] value,
  output logic running,
  output logic expiry
);

  logic start_d;

  assign running = enable && start && (value != 0);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      value   <= '0;
      expiry  <= 1'b0;
      start_d <= 1'b0;
    end
    else begin
      expiry  <= 1'b0;
      start_d <= start;

      if (start && !start_d)
        value <= load;
      else if (enable && start) begin
        if (value > 1)
          value <= value - 1'b1;
        else if (value == 1) begin
          expiry <= irq_enable;
          value <= periodic ? load : 32'h0;
        end
      end
    end
  end

endmodule
