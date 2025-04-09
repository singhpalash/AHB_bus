module ahb_bus (
    input  wire        HCLK,
    input  wire        HRESETn,
    // Control signals for the master
    input  wire        op_mode,       // 1 = write, 0 = read
    input  wire        start_transfer,
    input  wire [2:0]  burst_type,
    input  wire [31:0] init_addr,
    output reg [31:0] read_data_out
);

  // Master interface wires
  wire [31:0] HADDR;
  wire [1:0]  HTRANS;
  wire [2:0]  HBURST;
  wire [2:0]  HSIZE;
  wire [31:0] HWDATA;
  wire [31:0] HRDATA;
  wire        HREADY;
  wire   HRESP;
  wire        HWRITE;
  wire        done;
  wire [31:0] read_data;
  
  // Interconnect slave-side wires for Slave 0
  wire        HSEL0;
  wire [31:0] S0_HADDR;
  wire [1:0]  S0_HTRANS;
  wire [2:0]  S0_HBURST;
  wire [2:0]  S0_HSIZE;
  wire        S0_HWRITE;
  wire [31:0] S0_HWDATA;
  wire [31:0] S0_HRDATA;
  wire        S0_HREADYOUT;
  wire   S0_HRESP;
  
  // Interconnect slave-side wires for Slave 1
  wire        HSEL1;
  wire [31:0] S1_HADDR;
  wire [1:0]  S1_HTRANS;
  wire [2:0]  S1_HBURST;
  wire [2:0]  S1_HSIZE;
  wire        S1_HWRITE;
  wire [31:0] S1_HWDATA;
  wire [31:0] S1_HRDATA;
  wire        S1_HREADYOUT;
  wire   S1_HRESP;
  
  // Interconnect slave-side wires for Slave 2
  wire        HSEL2;
  wire [31:0] S2_HADDR;
  wire [1:0]  S2_HTRANS;
  wire [2:0]  S2_HBURST;
  wire [2:0]  S2_HSIZE;
  wire        S2_HWRITE;
  wire [31:0] S2_HWDATA;
  wire [31:0] S2_HRDATA;
  wire        S2_HREADYOUT;
  wire   S2_HRESP;
  
  
  ahb_master master_inst (
    .HCLK         (HCLK),
    .HRESETn      (HRESETn),
    .op_mode      (op_mode),
    .HADDR        (HADDR),
    .HTRANS       (HTRANS),
    .HBURST       (HBURST),
    .HSIZE        (HSIZE),
    .HWDATA       (HWDATA),
    .HRDATA       (HRDATA),
    .HREADY       (HREADY),
    .HRESP        (HRESP),  // Assuming only bit0 is used for error response in master
    .HWRITE       (HWRITE),
    .start_transfer(start_transfer),
    .burst_type   (burst_type),
    .init_addr    (init_addr),
    .done         (done),
    .read_data    (read_data)
  );

  
  ahb_interconnect interconnect_inst (
    .HCLK         (HCLK),
    .HRESETn      (HRESETn),
    // Master side signals:
    .M_HADDR      (HADDR),
    .M_HTRANS     (HTRANS),
    .M_HBURST     (HBURST),
    .M_HSIZE      (HSIZE),
    .M_HWRITE     (HWRITE),
    .M_HWDATA     (HWDATA),
    .M_HRDATA     (HRDATA),
    .M_HREADY     (HREADY),
    .M_HRESP      (HRESP),
    // Slave 0 interface
    .HSEL0        (HSEL0),
    .S0_HADDR     (S0_HADDR),
    .S0_HTRANS    (S0_HTRANS),
    .S0_HBURST    (S0_HBURST),
    .S0_HSIZE     (S0_HSIZE),
    .S0_HWRITE    (S0_HWRITE),
    .S0_HWDATA    (S0_HWDATA),
    .S0_HRDATA    (S0_HRDATA),
    .S0_HREADYOUT (S0_HREADYOUT),
    .S0_HRESP     (S0_HRESP),
    // Slave 1 interface
    .HSEL1        (HSEL1),
    .S1_HADDR     (S1_HADDR),
    .S1_HTRANS    (S1_HTRANS),
    .S1_HBURST    (S1_HBURST),
    .S1_HSIZE     (S1_HSIZE),
    .S1_HWRITE    (S1_HWRITE),
    .S1_HWDATA    (S1_HWDATA),
    .S1_HRDATA    (S1_HRDATA),
    .S1_HREADYOUT (S1_HREADYOUT),
    .S1_HRESP     (S1_HRESP),
    // Slave 2 interface
    .HSEL2        (HSEL2),
    .S2_HADDR     (S2_HADDR),
    .S2_HTRANS    (S2_HTRANS),
    .S2_HBURST    (S2_HBURST),
    .S2_HSIZE     (S2_HSIZE),
    .S2_HWRITE    (S2_HWRITE),
    .S2_HWDATA    (S2_HWDATA),
    .S2_HRDATA    (S2_HRDATA),
    .S2_HREADYOUT (S2_HREADYOUT),
    .S2_HRESP     (S2_HRESP)
  );

  
  ahb_slave #(
    .MEM_DEPTH   (256),
    .WAIT_CYCLES (2)
  ) slave0_inst (
    .HCLK     (HCLK),
    .HRESETn  (HRESETn),
    .HSEL     (HSEL0),
    .HADDR    (S0_HADDR),
    .HTRANS   (S0_HTRANS),
    .HBURST   (S0_HBURST),
    .HSIZE    (S0_HSIZE),
    .HWRITE   (S0_HWRITE),
    .HWDATA   (S0_HWDATA),
    .HRDATA   (S0_HRDATA),
    .HREADY   (HREADY),
    .HREADYOUT(S0_HREADYOUT),
    .HRESP    (S0_HRESP)
  );

 
  ahb_slave #(
    .MEM_DEPTH   (256),
    .WAIT_CYCLES (2)
  ) slave1_inst (
    .HCLK     (HCLK),
    .HRESETn  (HRESETn),
    .HSEL     (HSEL1),
    .HADDR    (S1_HADDR),
    .HTRANS   (S1_HTRANS),
    .HBURST   (S1_HBURST),
    .HSIZE    (S1_HSIZE),
    .HWRITE   (S1_HWRITE),
    .HWDATA   (S1_HWDATA),
    .HRDATA   (S1_HRDATA),
    .HREADY   (HREADY),
    .HREADYOUT(S1_HREADYOUT),
    .HRESP    (S1_HRESP)
  );

  
  ahb_slave #(
    .MEM_DEPTH   (256),
    .WAIT_CYCLES (2)
  ) slave2_inst (
    .HCLK     (HCLK),
    .HRESETn  (HRESETn),
    .HSEL     (HSEL2),
    .HADDR    (S2_HADDR),
    .HTRANS   (S2_HTRANS),
    .HBURST   (S2_HBURST),
    .HSIZE    (S2_HSIZE),
    .HWRITE   (S2_HWRITE),
    .HWDATA   (S2_HWDATA),
    .HRDATA   (S2_HRDATA),
    .HREADY   (HREADY),
    .HREADYOUT(S2_HREADYOUT),
    .HRESP    (S2_HRESP)
  );
  
  always@(posedge HCLK or negedge HRESETn) begin
   if(! HRESETn) 
    read_data_out<=32'd0;
   else
    read_data_out<=read_data;
  end

endmodule

