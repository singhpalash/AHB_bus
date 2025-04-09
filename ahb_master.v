module ahb_master(
    input  wire        HCLK,
    input  wire        HRESETn,
    input  wire        op_mode,      // External control: 1 = write, 0 = read
    // AHB bus signals
    output reg [31:0]  HADDR,
    output reg [1:0]   HTRANS,
    output reg [2:0]   HBURST,
    output reg [2:0]   HSIZE,
    output reg [31:0]  HWDATA,
    input  wire [31:0] HRDATA,
    input  wire        HREADY,
    input  wire        HRESP,        // 0 = OKAY, 1 = ERROR
    output reg         HWRITE,
    // Control signals to start a transfer and indicate completion
    input  wire        start_transfer,
    input  wire [2:0]  burst_type,   // 3'b000: SINGLE, 3'b001: UNDEFINED (INCR),
                                    // 3'b010: WRAP4, 3'b101: INCR8, 3'b100: WRAP8
    input  wire [31:0] init_addr,    // initial address for the burst
    output reg         done,
    // Captured read data (valid when op_mode = 0)
    output reg [31:0]  read_data
);

  // FSM state encoding
  localparam IDLE     = 3'b000;
  localparam ADDR     = 3'b001;
  localparam DATA     = 3'b010;
  localparam WAIT     = 3'b011;
  localparam ERROR    = 3'b100;
  localparam COMPLETE = 3'b101;

  reg [2:0] state, next_state;
  reg [3:0] beat_count;    // Current beat count within the burst
  reg [3:0] burst_length;  // Total beats in the current burst
  reg [31:0] start_addr;   // Latches the initial address of the burst

  // Define burst lengths for different types (for 32-bit transfers, increment by 4 bytes)
  localparam SINGLE_LENGTH       = 1;
  localparam DEFAULT_INCR_LENGTH = 4; // For UNDEFINED (INCR) bursts, assume 4 beats by default
  localparam WRAP4_LENGTH        = 4;
  localparam INCR4_LENGTH        = 4;
  localparam WRAP8_LENGTH        = 8;
  localparam INCR8_LENGTH        = 8;

  // State and beat counter update
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      state      <= IDLE;
      beat_count <= 0;
    end 
    else begin
      state <= next_state;
      if ((state == ADDR || state == DATA) && HREADY) begin
        if (HTRANS == 2'b10) // NONSEQ (first beat)
          beat_count <= 1;
        else if (HTRANS == 2'b11) // SEQ (subsequent beats)
          beat_count <= beat_count + 1;
      end
    end
  end

  // Burst length determination
  always @(*) begin
    case (burst_type)
      3'b000: burst_length = SINGLE_LENGTH;
      3'b001: burst_length = DEFAULT_INCR_LENGTH;
      3'b010: burst_length = WRAP4_LENGTH;
      3'b101: burst_length = INCR8_LENGTH;
      3'b100: burst_length = WRAP8_LENGTH;
      default: burst_length = SINGLE_LENGTH;
    endcase
  end

  // Compute next address (with wrapping support)
  reg [31:0] next_addr;
  reg [31:0] wrap_boundary;
  reg [31:0] wrap_range;
  reg [31:0] offset;
  wire [31:0] inc_addr;
  assign inc_addr = HADDR + 4;
  always @(*) begin
    next_addr = inc_addr;  // default: incremental
    if (burst_type == 3'b010 || burst_type == 3'b100) begin
      wrap_range    = burst_length * 4;
      wrap_boundary = start_addr & ~(wrap_range - 1);
      offset        = (HADDR + 4) - wrap_boundary;
      if (offset >= wrap_range)
        offset = offset - wrap_range;
      next_addr <= wrap_boundary + offset;
     end
     
    else if (burst_type==3'b101) begin
      next_addr <= HADDR + 8;
    end
    else begin
      next_addr <= HADDR + 1;
      
    end
  end

  // FSM: Next state logic with error condition detected only when both HREADY and HRESP are high
  always @(*) begin
    next_state = state;
    case (state)
      IDLE: begin
        if (start_transfer)
          next_state = ADDR;
      end

      ADDR: begin
        if (HREADY && HRESP)
          next_state = ERROR;
        else if (!HREADY)
          next_state = WAIT;
        else
          next_state = DATA;
      end

      DATA: begin
        if (HREADY && HRESP)
          next_state = ERROR;
        else if (!HREADY)
          next_state = WAIT;
        else if (beat_count == burst_length)
          next_state = COMPLETE;
        else
          next_state = DATA;
      end

      WAIT: begin
        if (HREADY) begin
          if (HRESP)
            next_state = ERROR;
          else if (beat_count == burst_length)
            next_state = COMPLETE;
          else
            next_state = DATA;
        end
      end

      ERROR: begin
        next_state = COMPLETE;
      end

      COMPLETE: begin
        next_state = IDLE;
      end

      default: next_state = IDLE;
    endcase
  end

  // Output logic and bus signal generation
  always @(posedge HCLK or negedge HRESETn) begin
    if (!HRESETn) begin
      HADDR      <= 32'd0;
      HTRANS     <= 2'b00;  // IDLE
      HBURST     <= 3'b000;
      HSIZE      <= 3'b010; // 32-bit transfer
      HWDATA     <= 32'd0;
      HWRITE     <= 1'b0;
      done       <= 1'b0;
      start_addr <= 32'd0;
      read_data  <= 32'd0;
    end 
    else begin
      case (state)
        IDLE: begin
          done   <= 1'b0;
          HTRANS <= 2'b00; // IDLE
          if (start_transfer) begin
            // Latch initial address
            start_addr <= init_addr;
            HADDR      <= init_addr;
            HBURST     <= burst_type;
            HSIZE      <= 3'b010; // 32-bit word transfer
            // First beat uses NONSEQ
            HTRANS     <= 2'b10;
            // For write transfers, provide initial write data.
            if (op_mode) begin
              HWDATA <= 32'hDEADBEEF;
            end
          end
        end

        ADDR: begin
          if (!HREADY) begin
            // Hold bus signals if not ready.
            HADDR  <= HADDR;
            HTRANS <= HTRANS;
          end
          else begin
            HADDR  <= next_addr;
            HTRANS <= 2'b11; // SEQ for subsequent beats
          end
        end

        DATA: begin
          // Set HWRITE according to op_mode (external control)
          HWRITE <= op_mode;
          if (!HREADY) begin
            HADDR  <= HADDR;
            HTRANS <= HTRANS;
          end 
          else begin
            // For read transfers, capture HRDATA.
            if (!op_mode)
              read_data <= HRDATA;
            // For write transfers, update HWDATA (here incrementing as an example)
            if (op_mode)
              HWDATA <= HWDATA + 1;
            // Continue burst if more beats remain.
            if (beat_count < burst_length) begin
              HADDR  <= next_addr;
              HTRANS <= 2'b11;
            end
          end
        end

        WAIT: begin
          // Hold signals during wait.
          HADDR  <= HADDR;
          HTRANS <= HTRANS;
        end

        ERROR: begin
          // On error, cancel burst (drive IDLE).
          HTRANS <= 2'b00;
        end

        COMPLETE: begin
          done   <= 1'b1;
          HTRANS <= 2'b00;
        end

        default: begin
          HTRANS <= 2'b00;
        end
      endcase
    end
  end

endmodule
