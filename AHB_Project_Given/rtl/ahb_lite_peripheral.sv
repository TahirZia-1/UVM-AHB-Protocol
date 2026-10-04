module ahb_lite_peripheral #(
  parameter int ADDR_W=32,
  parameter int DATA_W=32
)(
  input  logic HCLK,
  input  logic HRESETn,

  input  logic              HSEL,
  input  logic [ADDR_W-1:0] HADDR,
  input  logic [1:0]        HTRANS,
  input  logic              HWRITE,
  input  logic [2:0]        HSIZE,
  input  logic [2:0]        HBURST,
  input  logic [3:0]        HPROT,
  input  logic [DATA_W-1:0] HWDATA,
  input  logic              HREADY,

  output logic [DATA_W-1:0] HRDATA,
  output logic              HREADYOUT,
  output logic              HRESP,
  output logic              IRQ
);

  localparam logic [31:0] A_CTRL       = 32'h0000_1000;
  localparam logic [31:0] A_STATUS     = 32'h0000_1004;
  localparam logic [31:0] A_INT_EN     = 32'h0000_1008;
  localparam logic [31:0] A_INT_STATUS = 32'h0000_100C;
  localparam logic [31:0] A_TIMER_LOAD = 32'h0000_1010;
  localparam logic [31:0] A_TIMER_CTRL = 32'h0000_1014;
  localparam logic [31:0] A_TIMER_VAL  = 32'h0000_1018;
  localparam logic [31:0] A_FIFO_DATA  = 32'h0000_1020;
  localparam logic [31:0] A_FIFO_STAT  = 32'h0000_1024;
  localparam logic [31:0] A_SCRATCH    = 32'h0000_1028;
  localparam logic [31:0] A_WAIT_CFG   = 32'h0000_102C;

  logic [7:0] ram[0:2047];

  logic [3:0] ctrl;
  logic [2:0] int_en;
  logic [2:0] int_status;
  logic [31:0] timer_load;
  logic [2:0] timer_ctrl;
  logic [31:0] scratch;
  logic [1:0] wait_cfg;

  logic [31:0] timer_value;
  logic timer_running;
  logic timer_expiry;

  logic fifo_push, fifo_pop;
  logic [31:0] fifo_rdata;
  logic fifo_empty, fifo_full;
  logic [4:0] fifo_level;

  logic [31:0] addr_q;
  logic        write_q;
  logic [2:0]  size_q;
  logic [2:0]  burst_q;
  logic        active_q;
  logic [1:0]  wait_count;

  logic [15:0] lfsr;

  logic valid_addr_phase;
  logic trans_nonseq_or_seq;

  assign trans_nonseq_or_seq = HTRANS[1];
  assign valid_addr_phase = HSEL && HREADY && trans_nonseq_or_seq;

  assign IRQ = ctrl[0] && (|(int_en & int_status));

  ahb_fifo #(.WIDTH(32), .DEPTH(16)) u_fifo (
    .clk(HCLK),
    .rst_n(HRESETn),
    .clear(!ctrl[2]),
    .push(fifo_push),
    .pop(fifo_pop),
    .wdata(HWDATA),
    .rdata(fifo_rdata),
    .empty(fifo_empty),
    .full(fifo_full),
    .level(fifo_level)
  );

  ahb_timer u_timer (
    .clk(HCLK),
    .rst_n(HRESETn),
    .enable(ctrl[1]),
    .start(timer_ctrl[0]),
    .periodic(timer_ctrl[1]),
    .irq_enable(timer_ctrl[2]),
    .load(timer_load),
    .value(timer_value),
    .running(timer_running),
    .expiry(timer_expiry)
  );

  function automatic logic is_ram(input logic [31:0] a);
    return a <= 32'h0000_07FF;
  endfunction

  function automatic logic is_reg(input logic [31:0] a);
    return a inside {
      A_CTRL, A_STATUS, A_INT_EN, A_INT_STATUS, A_TIMER_LOAD,
      A_TIMER_CTRL, A_TIMER_VAL, A_FIFO_DATA, A_FIFO_STAT,
      A_SCRATCH, A_WAIT_CFG
    };
  endfunction

  function automatic logic aligned(input logic [31:0] a, input logic [2:0] size);
    case (size)
      3'd0: return 1'b1;
      3'd1: return (a[0] == 1'b0);
      3'd2: return (a[1:0] == 2'b00);
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic burst_supported(input logic [2:0] b);
    return b inside {3'b000, 3'b001, 3'b010, 3'b011};
  endfunction

  function automatic logic [31:0] read_ram(input logic [31:0] a);
    logic [31:0] v;
    v='0;

    for (int i=0;i<4;i++)
      if ((a+i) <= 32'h0000_07FF)
        v[i*8 +: 8] = ram[a+i];

    return v;
  endfunction

  function automatic logic [31:0] read_reg(input logic [31:0] a);
    case (a)
      A_CTRL:       return {28'h0,ctrl};
      A_STATUS:     return {27'h0,IRQ,fifo_full,fifo_empty,timer_running,ctrl[0]};
      A_INT_EN:     return {29'h0,int_en};
      A_INT_STATUS: return {29'h0,int_status};
      A_TIMER_LOAD: return timer_load;
      A_TIMER_CTRL: return {29'h0,timer_ctrl};
      A_TIMER_VAL:  return timer_value;
      A_FIFO_DATA:  return fifo_rdata;
      A_FIFO_STAT:  return {23'h0,fifo_level,2'b0,fifo_full,fifo_empty};
      A_SCRATCH:    return scratch;
      A_WAIT_CFG:   return {30'h0,wait_cfg};
      default:      return '0;
    endcase
  endfunction

  function automatic logic illegal_access(
    input logic [31:0] a,
    input logic wr,
    input logic [2:0] size,
    input logic [2:0] burst
  );
    if (!aligned(a,size))
      return 1'b1;

    if (!burst_supported(burst))
      return 1'b1;

    if (!(is_ram(a) || is_reg(a)))
      return 1'b1;

    if (wr && (a inside {A_STATUS,A_TIMER_VAL,A_FIFO_STAT}))
      return 1'b1;

    if ((a == A_FIFO_DATA) && !ctrl[2])
      return 1'b1;

    if (wr && (a == A_FIFO_DATA) && fifo_full)
      return 1'b1;

    if (!wr && (a == A_FIFO_DATA) && fifo_empty)
      return 1'b1;

    return 1'b0;
  endfunction

  always_comb begin
    HREADYOUT = !active_q || (wait_count == 0);
    HRESP = 1'b0;
    HRDATA = '0;

    fifo_push = 1'b0;
    fifo_pop  = 1'b0;

    if (active_q && (wait_count == 0)) begin
      HRESP = illegal_access(addr_q,write_q,size_q,burst_q);

      if (!write_q && !HRESP) begin
        if (is_ram(addr_q))
          HRDATA = read_ram(addr_q);
        else
          HRDATA = read_reg(addr_q);
      end

      if (!write_q && !HRESP && (addr_q == A_FIFO_DATA))
        fifo_pop = 1'b1;

      if (write_q && !HRESP && (addr_q == A_FIFO_DATA))
        fifo_push = 1'b1;
    end
  end

  always_ff @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      addr_q <= '0;
      write_q <= 1'b0;
      size_q <= 3'd2;
      burst_q <= 3'b000;
      active_q <= 1'b0;
      wait_count <= '0;

      ctrl <= '0;
      int_en <= '0;
      int_status <= '0;
      timer_load <= '0;
      timer_ctrl <= '0;
      scratch <= '0;
      wait_cfg <= '0;

      lfsr <= 16'hBEEF;

      for (int i=0;i<2048;i++)
        ram[i] <= 8'h00;
    end
    else begin
      lfsr <= {lfsr[14:0],lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};

      if (wait_count != 0)
        wait_count <= wait_count - 1'b1;

      if (timer_expiry)
        int_status[0] <= 1'b1;

      if (fifo_full)
        int_status[1] <= 1'b1;

      if (fifo_empty)
        int_status[2] <= 1'b1;

      if (active_q && (wait_count == 0) && HREADY) begin
        if (write_q && !illegal_access(addr_q,write_q,size_q,burst_q)) begin
          if (is_ram(addr_q)) begin
            case (size_q)
              3'd0:
                ram[addr_q] <= HWDATA[7:0];

              3'd1: begin
                ram[addr_q]   <= HWDATA[7:0];
                ram[addr_q+1] <= HWDATA[15:8];
              end

              default: begin
                for (int i=0;i<4;i++)
                  ram[addr_q+i] <= HWDATA[i*8 +: 8];
              end
            endcase
          end
          else begin
            case (addr_q)
              A_CTRL:
                ctrl <= HWDATA[3:0];

              A_INT_EN:
                int_en <= HWDATA[2:0];

              A_INT_STATUS:
                int_status <= int_status & ~HWDATA[2:0];

              A_TIMER_LOAD:
                timer_load <= HWDATA;

              A_TIMER_CTRL:
                timer_ctrl <= HWDATA[2:0];

              A_SCRATCH:
                scratch <= HWDATA;

              A_WAIT_CFG:
                wait_cfg <= HWDATA[1:0];

              default: ;
            endcase
          end
        end

        active_q <= 1'b0;
      end

      if (valid_addr_phase && (!active_q || ((wait_count == 0) && HREADY))) begin
        addr_q  <= HADDR;
        write_q <= HWRITE;
        size_q  <= HSIZE;
        burst_q <= HBURST;
        active_q <= 1'b1;

        if (wait_cfg == 0)
          wait_count <= 0;
        else
          wait_count <= lfsr[1:0] % (wait_cfg + 1);
      end
    end
  end

endmodule
