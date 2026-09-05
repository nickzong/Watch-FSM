`timescale  1ns/1ps

module tb_stopwatch;
    logic clk = 0;
    logic areset = 0;
    logic tick = 0;
    logic set = 0;

    logic[5:0] ss, mm;

    int errors = 0;

    stopwatch dut (
        .clk(clk), .areset(areset), .tick(tick),
        .set(set), .ss(ss), .mm(mm)
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

    task pulse_set;
        begin
            @(negedge clk); set = 1; #1;
            @(negedge clk); set = 0; #1;
        end
    endtask

    initial begin
        $dumpfile("tb_stopwatch.vcd");
        $dumpvars(0, tb_stopwatch);

        // 1. Test areset, should be stopped after reset
        areset = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(ss, 0, "ss is 00");
        check_eq(mm, 0, "mm is 00");
        areset = 0;

        // 2. Normal operation (30 sec)
        // no time change should happen for first 30 ticks
        pulse_tick_for(30);
        check_eq(ss, 0, "ss is 00");
        check_eq(mm, 0, "mm is 00");
        pulse_set(); // running = 1
        pulse_tick_for(30);
        check_eq(ss, 30, "ss is 30");
        check_eq(mm, 0, "mm is 00");

        // 3. Test areset while running 
        areset = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(ss, 30, "ss is 30");
        check_eq(mm, 0, "mm is 00");
        areset = 0; // running = 0 from reset

        // 4. Normal operation (40), test wraparound
        pulse_set(); // running = 1
        pulse_tick_for(40);
        check_eq(ss, 10, "ss is 10");
        check_eq(mm, 1, "mm is 01");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end

    
endmodule