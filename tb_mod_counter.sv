`timescale 1ns/1ns

module tb_mod_counter;
  localparam STEPS    = 4; // small steps for simplicity
  localparam REG_SIZE = 2; 

  logic clk = 0;
  logic areset = 0;
  logic inc = 0;
  logic [REG_SIZE-1:0] out;
  logic carry;

  int errors = 0;

  mod_counter #(.STEPS(STEPS), .REG_SIZE(REG_SIZE)) dut (
    .clk(clk), .areset(areset), .inc(inc), .out(out), .carry(carry)
  );

  always #5 clk = ~clk; // 10ns period

  task check_eq(input [31:0] got, input [31:0] exp, input [8*80-1:0] msg);
    begin
      if (got !== exp) begin
        $display("FAIL: %0s (got=%0d expected=%0d) at t=%0t", msg, got, exp, $time);
        errors = errors + 1;
      end else begin
        $display("PASS: %0s (=%0d) at t=%0t", msg, got, $time);
      end
    end
  endtask

  // Hold inc high for one clock edge
  task pulse_inc;
    begin
      @(negedge clk); inc = 1; #1;
      @(negedge clk); inc = 0; #1;
    end
  endtask

  initial begin
    // $dumpfile("tb_mod_counter.vcd");
    // $dumpvars(0, tb_mod_counter);

    // 1. reset behavior
    areset = 1;
    @(negedge clk);
    @(negedge clk);
    check_eq(out, 0, "out is 0 after reset");
    areset = 0;

    // 2. holds steady when inc stays low
    @(negedge clk);
    @(negedge clk);
    check_eq(out, 0, "out holds at 0 when inc stays low");

    // 3. counts up normally: 0 -> 1 -> 2 -> 3, carry stays low the whole way
    pulse_inc();
    check_eq(out, 1, "out increments to 1");
    check_eq(carry, 0, "carry low, not at wrap yet");

    pulse_inc();
    check_eq(out, 2, "out increments to 2");
    check_eq(carry, 0, "carry still low");

    pulse_inc();
    check_eq(out, 3, "out increments to STEPS-1 (3)");
    check_eq(carry, 0, "carry still low -- out is AT the max, but inc isn't asserted right now");

    // 4. the wrap itself: assert inc while out == STEPS-1 and check carry
    //    BEFORE the clock edge that actually performs the wrap.
    @(negedge clk); inc = 1; #1;
    check_eq(out, 3, "out still 3 -- the wrapping posedge hasn't happened yet");
    check_eq(carry, 1, "carry pulses high exactly when out==STEPS-1 AND inc is asserted");

    @(negedge clk); inc = 0; #1;
    check_eq(out, 0, "out wrapped to 0 on the edge where carry was high");
    check_eq(carry, 0, "carry drops back low once out is no longer STEPS-1");

    // 5. normal counting resumes after the wrap
    pulse_inc();
    check_eq(out, 1, "counting resumes normally after a wrap: 0 -> 1");

    // 6. areset must work even when inc is NOT asserted -- the specific bug
    //    from earlier drafts, where reset got nested behind "if (inc)".
    inc = 0;
    areset = 1;
    @(negedge clk);
    check_eq(out, 0, "areset clears out even while inc is low");
    areset = 0;

    if (errors == 0) $display("\nALL CHECKS PASSED");
    else              $display("\n%0d CHECK(S) FAILED", errors);

    $finish;
  end

endmodule