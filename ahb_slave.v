`timescale 1ns/1ps
module ahb_slave #(
    parameter MEM_DEPTH   = 256,  // Number of 32-bit words in memory
    parameter WAIT_CYCLES = 2     // Normal wait cycles (for normal transfers)
)(
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        HSEL,      // Slave select (active high)
    // AHB Slave interface signals
    input  wire [31:0] HADDR,
    input  wire [1:0]  HTRANS,    // 2'b00: IDLE, 2'b01: BUSY, 2'b10: NONSEQ, 2'b11: SEQ
    input  wire [2:0]  HBURST,    // Not used here, but provided
    input  wire [2:0]  HSIZE,     // e.g., 3'b010 for 32-bit transfer
    input  wire        HWRITE,    // 1: Write, 0: Read
    input  wire [31:0] HWDATA,
    output reg  [31:0] HRDATA,
    input  wire        HREADY,    // From Master - indicates new transfer phase
    output reg         HREADYOUT, // Slave ready-out signal
    output reg         HRESP      // 0: OKAY, 1: ERROR
);

  // Internal memory (word-addressable)
  reg [31:0] mem [0:MEM_DEPTH-1];
  
  integer r;
  initial begin
    for(r = 0; r < 64; r = r + 1) begin
      mem[r] = r;
    end
  end 

  // Latches for current transaction parameters.
  // Only update when a valid transfer occurs (NONSEQ or SEQ).
  reg [31:0] latched_addr;
  reg        latched_HWRITE;
  reg [31:0] latched_HWDATA;
  reg [1:0]  latched_HTRANS;

  // Wait counter for normal wait cycles.
  reg [$clog2(WAIT_CYCLES+1)-1:0] wait_counter;

  
  // We'll use a simple FSM:
  // SL_IDLE: waiting for a valid transfer.
  // SL_WAIT: normal wait state (for latency).
  // SL_RESP: normal response state.
  // SL_ERRWAIT and SL_ERRRESP: for error responses.
  localparam SL_IDLE    = 3'b000;
  localparam SL_WAIT    = 3'b001;
  localparam SL_RESP    = 3'b010;
  localparam SL_ERRWAIT = 3'b011; // First error cycle: HRESP=1, HREADYOUT=0
  localparam SL_ERRRESP = 3'b100; // Second error cycle: HRESP=1, HREADYOUT=1

  reg [2:0] state, next_state;

  //-------------------------------------------------------------------------
  // Latch Transaction Parameters
  //-------------------------------------------------------------------------
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      latched_addr   <= 32'd0;
      latched_HWRITE <= 1'b0;
      latched_HWDATA <= 32'd0;
      latched_HTRANS <= 2'b00;
    end
    // Only latch when HSEL is asserted, HREADY is high,
    // and the transfer is NONSEQ or SEQ (ignore BUSY and IDLE).
    else if (HSEL && HREADY && ((HTRANS == 2'b10) || (HTRANS == 2'b11))) begin
      latched_addr   <= HADDR;
      latched_HWRITE <= HWRITE;
      latched_HWDATA <= HWDATA;
      latched_HTRANS <= HTRANS;
    end
  end

  //-------------------------------------------------------------------------
  // FSM: State Transition Logic
  //-------------------------------------------------------------------------
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn)
      state <= SL_IDLE;
    else
      state <= next_state;
  end

  always @(*) begin
    // Default next state: remain in current state.
    next_state = state;
    case (state)
      SL_IDLE: begin
        // If a valid transfer occurs (NONSEQ or SEQ) and not BUSY, go to wait state.
        if (HSEL && HREADY && ((HTRANS == 2'b10) || (HTRANS == 2'b11)))
          next_state = SL_WAIT;
        // For BUSY transfers, just ignore (remain in idle with immediate OKAY response).
        else if (HTRANS == 2'b01 || HTRANS == 2'b00)
          next_state = SL_IDLE;
      end

      SL_WAIT: begin
        // Stay in wait until the wait counter expires.
        if (wait_counter == 0) begin
          // Check error condition: For this example, an error is an out-of-range address.
          if (latched_addr[31:2] < MEM_DEPTH)
            next_state = SL_RESP;
          else
            next_state = SL_ERRWAIT;
        end else
          next_state = SL_WAIT;
      end

      SL_RESP: begin
        next_state = SL_IDLE;
      end

      SL_ERRWAIT: begin
        next_state = SL_ERRRESP;
      end

      SL_ERRRESP: begin
        next_state = SL_IDLE;
      end

      default: next_state = SL_IDLE;
    endcase
  end

  
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      wait_counter <= 0;
      HREADYOUT    <= 1'b1;
      HRESP        <= 1'b0;
      HRDATA       <= 32'd0;
    end else begin
      case (state)
        SL_IDLE: begin
          HREADYOUT <= 1'b1;
          HRESP     <= 1'b0;
          HRDATA    <= 32'd0;
          // Reload wait counter for next transaction.
          wait_counter <= WAIT_CYCLES;
        end

        SL_WAIT: begin
          // During normal wait, HREADYOUT is low.
          HREADYOUT <= 1'b0;
          if (wait_counter > 0)
            wait_counter <= wait_counter - 1;
        end

        SL_RESP: begin
          // Normal response: if it's a read, output memory; if write, update memory.
          if (latched_addr[31:2] < MEM_DEPTH) begin
            if (latched_HWRITE) begin
              mem[latched_addr[31:2]] <= latched_HWDATA;
              HRESP <= 1'b0;
            end 
            else begin
              HRDATA <= mem[latched_addr[31:2]];
              HRESP  <= 1'b0;
            end
          end
          HREADYOUT <= 1'b1;
        end

        SL_ERRWAIT: begin
          // First error cycle: assert error, but HREADYOUT remains low.
          HRESP     <= 1'b1;
          HREADYOUT <= 1'b0;
          HRDATA    <= 32'd0;
        end

        SL_ERRRESP: begin
          // Second error cycle: assert error, and drive HREADYOUT high.
          HRESP     <= 1'b1;
          HREADYOUT <= 1'b1;
          HRDATA    <= 32'd0;
        end

        default: begin
          HREADYOUT <= 1'b1;
          HRESP     <= 1'b0;
        end
      endcase
    end
  end

endmodule
