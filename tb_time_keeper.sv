`timescale 1ns/1ps

module tb_time_keeper 
  logic clk = 0;
  logic areset = 0;
  
  logic tick = 0; 
  logic inc_min_pulse = 0;
  logic inc_hr_pulse = 0;
  logic pause_sec = 0;
  
  logic[5:0] ss;
  logic[5:0] mm;
  logic[4:0] hh;
  
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
  
  task pulse_inc;
    begin
      @(negedge clk); tick = 1; #1;
      @(negedge clk); tick = 0; #1;
    end
  endtask
  
  task pulse_inc_for(int iters)
    begin
      for (int i = 0; i < iters; i++) begin
        pulse_inc;
      end
    end
  endtask
  
  initial begin
    $dumpfile("tb_time_keeper.vcd");
    $dumpvars(0, tb_time_keeper);
    
    // 1. Normal operation (30 sec)
    pulse_inc_for(30);
    check_eq(ss, 29, "ss is 29 after thirty tick signals");
    check_eq(mm, 0, "mm is 0 after thirty tick signals");
    check_eq(hh, 0, "ss is 0 after thirty tick signals");
    
    // 2. pause_sec = 1 and 30 tick signals
    pause_sec = 1;
    pulse_inc_for(30);
    check_eq(ss, 29, "no change with pause_sec = 1");
    check_eq(mm, 0, "no change with pause_sec = 1");
    check_eq(hh, 0, "no change with pause_sec = 1");
    pause_sec = 0;
    
    // 3. After 40 more ticks, should be 00:01:09
    
    // 4. Test 3 inc_min_pulses, expected: 
    // 00:01:09 --> 00:02:09 --> 00:03:09 --> 00:04:09
    
    // 5. Test 3 inc_hr_pulses, expected: 
    // 00:04:09 --> 01:04:09 --> 02:04:09 --> 03:04:09
    
    // 6. Test areset
    
    
  
endmodule
  
