`timescale 1ns/1ps

module tb_time_keeper;
  logic clk = 0;
  logic areset = 0;
  
  logic tick = 0; 
  logic inc_min_pulse = 0;
  logic inc_hr_pulse = 0;
  logic pause_sec = 0;
  
  logic[5:0] ss;
  logic[5:0] mm;
  logic[4:0] hh;

  int errors = 0;
  
  time_keeper dut(
    .clk(clk), .areset(areset), .tick_1Hz(tick),
    .inc_min_pulse(inc_min_pulse), .inc_hr_pulse(inc_hr_pulse), .pause_sec(pause_sec), 
    .ss(ss), .mm(mm), .hh(hh)
  );
  
  always #5 clk = ~clk; // 10ps clock period
  
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
  
  task pulse_tick_for(input int iters);
    begin
      for (int i = 0; i < iters; i++) begin
        @(negedge clk); tick = 1; #1;
        @(negedge clk); tick = 0; #1;
      end
    end
  endtask

  task inc_min_for(input int iters);
    begin
      for (int i = 0; i < iters; i++) begin
        @(negedge clk); inc_min_pulse = 1; #1;
        @(negedge clk); inc_min_pulse = 0; #1;
      end
    end
  endtask

  task inc_hr_for(input int iters);
    begin
      for (int i = 0; i < iters; i++) begin
        @(negedge clk); inc_hr_pulse = 1; #1;
        @(negedge clk); inc_hr_pulse = 0; #1;
      end
    end
  endtask

  initial begin
    $dumpfile("tb_time_keeper.vcd");
    $dumpvars(0, tb_time_keeper);
    
    // 1. Test areset
    areset = 1;
    @(negedge clk);
    @(negedge clk);
    check_eq(ss, 0, "ss is 00");
    check_eq(mm, 0, "mm is 00");
    check_eq(hh, 0, "hh is 00");
    areset = 0;
    
    // 2. Normal operation (30 sec)
    pulse_tick_for(30);
    check_eq(ss, 30, "ss is 30 after thirty tick signals");
    check_eq(mm, 0, "mm is 0 after thirty tick signals");
    check_eq(hh, 0, "ss is 0 after thirty tick signals");
    
    // 3. pause_sec = 1 and 30 tick signals
    pause_sec = 1;
    pulse_tick_for(30);
    check_eq(ss, 30, "no change with pause_sec = 1");
    check_eq(mm, 0, "no change with pause_sec = 1");
    check_eq(hh, 0, "no change with pause_sec = 1");
    pause_sec = 0;
    
    // 4. After 40 more ticks, should be 00:01:10
    pulse_tick_for(40);
    check_eq(ss, 10, "ss is 10");
    check_eq(mm, 1, "mm is 01");
    check_eq(hh, 0, "hh is 00");
    
    // 5. Test 3 inc_min_pulses, expected: 
    // 00:01:10 --> 00:02:10 --> 00:03:10 --> 00:04:10
    inc_min_for(3);
    check_eq(ss, 10, "ss is 10");
    check_eq(mm, 4, "mm is 04");
    check_eq(hh, 0, "hh is 00");
    
    // 6. Test 3 inc_hr_pulses, expected: 
    // 00:04:10 --> 01:04:10 --> 02:04:10 --> 03:04:10
    inc_hr_for(3);
    check_eq(ss, 10, "ss is 10");
    check_eq(mm, 4, "mm is 04");
    check_eq(hh, 3, "hh is 03");
    
    if (errors == 0) $display("\nALL CHECKS PASSED");
    else   $display("\n%0d CHECK(S) FAILED", errors);

    $finish;
  end
endmodule
  