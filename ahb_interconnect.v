module ahb_interconnect(
    input  wire         HCLK,
    input  wire         HRESETn,
    // Master side signals:
    input  wire [31:0]  M_HADDR,
    input  wire [1:0]   M_HTRANS,
    input  wire [2:0]   M_HBURST,
    input  wire [2:0]   M_HSIZE,
    input  wire         M_HWRITE,
    input  wire [31:0]  M_HWDATA,
    output wire [31:0]  M_HRDATA,
    output wire         M_HREADY,
    output wire    M_HRESP,
    // Slave 0 interface
    output wire         HSEL0,
    output wire [31:0]  S0_HADDR,
    output wire [1:0]   S0_HTRANS,
    output wire [2:0]   S0_HBURST,
    output wire [2:0]   S0_HSIZE,
    output wire         S0_HWRITE,
    output wire [31:0]  S0_HWDATA,
    input  wire [31:0]  S0_HRDATA,
    input  wire         S0_HREADYOUT,
    input  wire    S0_HRESP,
    // Slave 1 interface
    output wire         HSEL1,
    output wire [31:0]  S1_HADDR,
    output wire [1:0]   S1_HTRANS,
    output wire [2:0]   S1_HBURST,
    output wire [2:0]   S1_HSIZE,
    output wire         S1_HWRITE,
    output wire [31:0]  S1_HWDATA,
    input  wire [31:0]  S1_HRDATA,
    input  wire         S1_HREADYOUT,
    input  wire    S1_HRESP,
    // Slave 2 interface
    output wire         HSEL2,
    output wire [31:0]  S2_HADDR,
    output wire [1:0]   S2_HTRANS,
    output wire [2:0]   S2_HBURST,
    output wire [2:0]   S2_HSIZE,
    output wire         S2_HWRITE,
    output wire [31:0]  S2_HWDATA,
    input  wire [31:0]  S2_HRDATA,
    input  wire         S2_HREADYOUT,
    input  wire    S2_HRESP
);

 
  
  assign HSEL0 = (M_HADDR[31:16] == 16'h0000);
  assign HSEL1 = (M_HADDR[31:16] == 16'h0001);
  assign HSEL2 = (M_HADDR[31:16] == 16'h0002);


  assign S0_HADDR   = M_HADDR;
  assign S0_HTRANS  = M_HTRANS;
  assign S0_HBURST  = M_HBURST;
  assign S0_HSIZE   = M_HSIZE;
  assign S0_HWRITE  = M_HWRITE;
  assign S0_HWDATA  = M_HWDATA;

  assign S1_HADDR   = M_HADDR;
  assign S1_HTRANS  = M_HTRANS;
  assign S1_HBURST  = M_HBURST;
  assign S1_HSIZE   = M_HSIZE;
  assign S1_HWRITE  = M_HWRITE;
  assign S1_HWDATA  = M_HWDATA;

  assign S2_HADDR   = M_HADDR;
  assign S2_HTRANS  = M_HTRANS;
  assign S2_HBURST  = M_HBURST;
  assign S2_HSIZE   = M_HSIZE;
  assign S2_HWRITE  = M_HWRITE;
  assign S2_HWDATA  = M_HWDATA;

 
  reg [31:0] mux_HRDATA;
  reg [1:0]  mux_HRESP;
  reg        mux_HREADYOUT;

  always @(posedge HCLK or negedge HRESETn) begin
  if(!HRESETn) begin
   mux_HRDATA=32'd0;
   mux_HRESP=2'b0;
   mux_HREADYOUT=1'b0;
  end
  
  else begin
  
    if (HSEL0) begin
      mux_HRDATA     = S0_HRDATA;
      mux_HRESP      = S0_HRESP;
      mux_HREADYOUT  = S0_HREADYOUT;
    end
    else if (HSEL1) begin
      mux_HRDATA     = S1_HRDATA;
      mux_HRESP      = S1_HRESP;
      mux_HREADYOUT  = S1_HREADYOUT;
    end 
    else if (HSEL2) begin
      mux_HRDATA     = S2_HRDATA;
      mux_HRESP      = S2_HRESP;
      mux_HREADYOUT  = S2_HREADYOUT;
    end 
    else begin
      mux_HRDATA     = 32'd0;
      mux_HRESP      = 2'b00;  // OKAY response
      mux_HREADYOUT  = 1'b1;
    end
   end
  end

  // Connect the multiplexed outputs to the master interface.
  assign M_HRDATA = mux_HRDATA;
  assign M_HRESP  = mux_HRESP;
  assign M_HREADY = mux_HREADYOUT;

endmodule


