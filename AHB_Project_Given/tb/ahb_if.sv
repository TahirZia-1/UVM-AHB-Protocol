interface ahb_if #(parameter ADDR_W=32, DATA_W=32) (input logic HCLK);

  logic HRESETn;

  logic              HSEL;
  logic [ADDR_W-1:0] HADDR;
  logic [1:0]        HTRANS;
  logic              HWRITE;
  logic [2:0]        HSIZE;
  logic [2:0]        HBURST;
  logic [3:0]        HPROT;
  logic [DATA_W-1:0] HWDATA;
  logic              HREADY;

  logic [DATA_W-1:0] HRDATA;
  logic              HREADYOUT;
  logic              HRESP;

endinterface
