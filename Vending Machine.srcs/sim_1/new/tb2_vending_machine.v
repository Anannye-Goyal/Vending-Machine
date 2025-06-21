`timescale 1ns / 1ps

module tb2_vending_machine;

  reg         clk    = 0;
  reg         reset  = 1;
  reg  [2:0]  sel    = 0;
  reg         coin50 = 0;
  reg         coin100= 0;
  reg         cancel = 0;

  wire ready;
  wire dispense;
  wire coin50_out;
  wire coin100_out;
  wire out_of_stock;

  // Clock period 
  parameter CLK_PERIOD_NS = 10;

  vending_machine #(
    .clk_period_ns(CLK_PERIOD_NS),
    .timeout_nano_secs(100)
  ) dut (
    .clk(clk),
    .reset(reset),
    .sel(sel),
    .coin50(coin50),
    .coin100(coin100),
    .cancel(cancel),
    .ready(ready),
    .dispense(dispense),
    .coin50_out(coin50_out),
    .coin100_out(coin100_out),
    .out_of_stock(out_of_stock)
  );

  always #(CLK_PERIOD_NS/2) clk = ~clk;

  integer i;
  initial begin

    $display("Time | reset sel coin50 coin100 cancel | ready dispense c50_out c100_out out_of_stock");
    $monitor("%4t |   %b    %b    %b      %b      %b  |   %b      %b        %b       %b         %b", 
             $time, reset, sel, coin50, coin100, cancel,
             ready, dispense, coin50_out, coin100_out, out_of_stock);

    // Reset 
    #(CLK_PERIOD_NS * 2);
    reset = 0;

    // TESTCASE 1: Order product 2 by giving the exact amount
    wait (ready);
    // Select item 2
    @(posedge clk); sel <= 3'd2;
    @(posedge clk); sel <= 3'd0;
    // Insert 100
    @(posedge clk); coin100 <= 1;
    @(posedge clk); coin100 <= 0;
    // Wait for dispense then return to ready
    wait (dispense);
    wait (ready);
    # (CLK_PERIOD_NS);

    // TESTCASE 2: Order product 1 by paying 100 and expecting a change of 50
    // Select item 1
    wait (ready);
    @(posedge clk); sel <= 3'd1;
    @(posedge clk); sel <= 3'd0;
    // Insert 100
    @(posedge clk); coin100 <= 1;
    @(posedge clk); coin100 <= 0;
    // Wait for dispense
    wait (dispense);
    // Wait for the change
    wait (coin50_out);
    wait (ready);
    # (CLK_PERIOD_NS);

    // TESTCASE 3: Out of Stock 
    for (i = 0; i < 5; i = i + 1) begin
      wait (ready);
      // Select item 5
      @(posedge clk); sel <= 3'd5;
      @(posedge clk); sel <= 3'd0;
      // Pay 250 as 100+100+50
      @(posedge clk); coin100 <= 1; @(posedge clk); coin100 <= 0;
      @(posedge clk); coin100 <= 1; @(posedge clk); coin100 <= 0;
      @(posedge clk); coin50  <= 1; @(posedge clk); coin50  <= 0;
      // Wait for dispense & ready
      wait (dispense);
      wait (ready);
      # (CLK_PERIOD_NS);
    end
    // Now order one more time to trigger out_of_stock
    @(posedge clk); sel <= 3'd5;
    @(posedge clk); sel <= 3'd0;
    wait (out_of_stock);
    # (CLK_PERIOD_NS);

    // ------------ TESTCASE 4: Timeout and then refund 
    wait (ready);
    // Select item 4
    @(posedge clk); sel <= 3'd4;
    @(posedge clk); sel <= 3'd0;
    // Inseet 100
    @(posedge clk); coin100 <= 1;
    @(posedge clk) coin100 <= 0;
    // Wait for timeout
    // Wait for refund
    wait (coin100_out);
    wait (ready);
    # (CLK_PERIOD_NS);

    // TESTCASE 5: Cancel in between
    wait (ready);
    // Select item 3
    @(posedge clk); sel <= 3'd3;
    @(posedge clk); sel <= 3'd0;
    // Insert 50 then cancel
    @(posedge clk); coin50 <= 1;
    @(posedge clk); coin50 <= 0;
    # (CLK_PERIOD_NS * 3);
    @(posedge clk); cancel <= 1;
    @(posedge clk); cancel <= 0;
    // Wait for refund
    wait (coin50_out);
    wait (ready);
    # (CLK_PERIOD_NS);

    $display("\nAll tests completed.");
    $finish;
  end
endmodule
