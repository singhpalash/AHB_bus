interface ahb_if(input HCLK);
  logic HRESETn;
  logic op_mode;
  logic start_transfer;
  logic [2:0] burst_type;
  logic [31:0] init_addr; 
  logic [31:0] read_data_out;
endinterface

class transaction;
  rand bit op_mode;
  rand bit start_transfer;
  randc bit [2:0] burst_type;  // Fixed width
  randc bit [31:0] init_addr;
  bit [31:0] read_data_out;

  constraint operation { 
    op_mode dist { 0 := 50, 1 := 90 };
  }

  constraint start_operation {
    start_transfer dist { 0 := 50, 1 := 90 };
  }

  function void display();
    $display("op_mode %0b | start_transfer %0b | burst_type %0b | init_addr %0d | read_data_out %0d",
             op_mode, start_transfer, burst_type, init_addr, read_data_out);
  endfunction

  function transaction copy();
    copy = new();
    copy.op_mode = this.op_mode;
    copy.start_transfer = this.start_transfer;
    copy.burst_type = this.burst_type;
    copy.init_addr = this.init_addr;
    copy.read_data_out = this.read_data_out;
    return copy;
  endfunction
endclass

class generator;
  transaction tr;
  mailbox #(transaction) mbxgd;
  event done, drvnext, sconext;
  int i;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
    tr = new();
  endfunction

  task run();
    for (i = 0; i < 20; i++) begin
      assert(tr.randomize()) else $display("Randomization failed");
      $display("Generator data sent:");
      tr.display();
      mbxgd.put(tr.copy());
      @(drvnext);
      if (tr.start_transfer)
        @(sconext); // Only wait if monitor will respond
    end
    ->done;
  endtask
endclass

class driver;
  transaction tr_drv;
  mailbox #(transaction) mbxgd;
  virtual ahb_if vif;
  event drvnext;

  function new(mailbox #(transaction) mbxgd);
    this.mbxgd = mbxgd;
  endfunction

  task reset();
    vif.HRESETn <= 1'b0;
    vif.op_mode <= 1'b0;
    vif.start_transfer <= 1'b0;
    repeat(5) @(posedge vif.HCLK);
    vif.HRESETn <= 1'b1;
    $display("DRV reset done");
  endtask

  task run();
    forever begin
      mbxgd.get(tr_drv);
      @(posedge vif.HCLK);
      vif.op_mode <= tr_drv.op_mode;
      vif.start_transfer <= tr_drv.start_transfer;
      vif.burst_type <= tr_drv.burst_type;
      vif.init_addr <= tr_drv.init_addr;
      vif.read_data_out <= tr_drv.read_data_out;
      $display("Driver sent data:");
      tr_drv.display();
      ->drvnext;
    end
  endtask
endclass

class monitor;
  virtual ahb_if vif;
  mailbox #(transaction) mbxms;
  transaction tr;

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
    tr = new();
  endfunction

  task run();
    forever begin
      @(posedge vif.HCLK);
      if (vif.start_transfer) begin
        tr.op_mode = vif.op_mode;
        tr.start_transfer = vif.start_transfer;
        tr.burst_type = vif.burst_type;
        tr.init_addr = vif.init_addr;
        tr.read_data_out = vif.read_data_out;
        $display("Monitor captured data:");
        tr.display();
        mbxms.put(tr.copy());
      end
    end
  endtask
endclass

class scoreboard;
  mailbox #(transaction) mbxms;
  transaction tr_sco;
  event sconext;
  integer i, index;
  reg [31:0] mem[0:127];

  function new(mailbox #(transaction) mbxms);
    this.mbxms = mbxms;
    for (i = 0; i < 64; i++) mem[i] = i;
  endfunction

  task run();
    forever begin
      mbxms.get(tr_sco);
      index = tr_sco.init_addr % 64;
      if (tr_sco.read_data_out == mem[index]) begin
        $display("✅ Read successful! Address: %0d, Expected: %0d, Got: %0d",
                 tr_sco.init_addr, mem[index], tr_sco.read_data_out);
      end else begin
        $error("❌ Mismatch in read_data_out! Expected: %0d, Got: %0d", 
               mem[index], tr_sco.read_data_out);
      end
      ->sconext;
    end
  endtask
endclass

class env;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;

  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxms;
  event drvnext, sconext, done;

  virtual ahb_if vif;

  function new(virtual ahb_if vif);
    this.vif = vif;

    mbxgd = new();
    mbxms = new();

    gen = new(mbxgd);
    drv = new(mbxgd);
    mon = new(mbxms);
    sco = new(mbxms);

    drv.drvnext = drvnext;
    gen.drvnext = drvnext;
    gen.sconext = sconext;
    sco.sconext = sconext;

    drv.vif = vif;
    mon.vif = vif;
  endfunction

  task pre_test();
    drv.reset();
  endtask

  task test();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any
  endtask

  task post_test();
    wait(gen.done.triggered);
    $display("Simulation completed.");
    $finish;
  endtask

  task run();
    pre_test();
    test();
    post_test();
  endtask
endclass

module ahb_bus_tb;
  bit HCLK = 0;
  bit HRESETn;

  always #5 HCLK = ~HCLK;

  ahb_if vif(HCLK);
  env e;

  // Dummy DUT instance - replace with your real module
  ahb_bus dut (
    .HCLK(vif.HCLK),
    .HRESETn(vif.HRESETn),
    .op_mode(vif.op_mode),
    .start_transfer(vif.start_transfer),
    .burst_type(vif.burst_type),
    .init_addr(vif.init_addr),
    .read_data_out(vif.read_data_out)
  );

  initial begin
    HRESETn = 0;
    #10 HRESETn = 1;
  end

  initial begin
    e = new(vif);
    e.run();
  end

  initial begin
    $dumpfile("ahb_bus_tb.vcd");
    $dumpvars(0, ahb_bus_tb);
    #2000 $stop;
  end
endmodule

