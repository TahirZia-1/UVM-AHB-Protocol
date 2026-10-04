module ahb_fifo #(
  parameter int WIDTH=32,
  parameter int DEPTH=16
)(
  input  logic clk,
  input  logic rst_n,
  input  logic clear,
  input  logic push,
  input  logic pop,
  input  logic [WIDTH-1:0] wdata,
  output logic [WIDTH-1:0] rdata,
  output logic empty,
  output logic full,
  output logic [$clog2(DEPTH+1)-1:0] level
);

  logic [WIDTH-1:0] mem[0:DEPTH-1];
  logic [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;

  assign empty = (level == 0);
  assign full  = (level == DEPTH);
  assign rdata = empty ? '0 : mem[rd_ptr];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      level  <= '0;
    end
    else if (clear) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      level  <= '0;
    end
    else begin
      case ({push && !full, pop && !empty})
        2'b10: begin
          mem[wr_ptr] <= wdata;
          wr_ptr <= wr_ptr + 1'b1;
          level <= level + 1'b1;
        end

        2'b01: begin
          rd_ptr <= rd_ptr + 1'b1;
          level <= level - 1'b1;
        end

        2'b11: begin
          mem[wr_ptr] <= wdata;
          wr_ptr <= wr_ptr + 1'b1;
          rd_ptr <= rd_ptr + 1'b1;
        end

        default: ;
      endcase
    end
  end

endmodule
