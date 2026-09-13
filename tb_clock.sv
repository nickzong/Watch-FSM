`timescale 1ns/1ps
// check tb_alarm_view.sv header comment, changed areset behavior
module tb_clock;
    logic clk = 0;
    logic areset = 0;
    logic tick_1Hz = 0;
    logic plus = 0;
    logic set = 0;

    logic s_carry;
    logic[5:0] ss;
    logic[5:0] mm;
    logic[5:0] hh;

    int errors = 0;

    clock dut (
        .clk(clk), .areset(areset), .tick_1Hz(tick_1Hz),
        .plus(plus), .set(set), .s_carry(s_carry), 
        .ss(ss), .mm(mm), .hh(hh)
    );

    always #5 clk = ~clk; // 10ns clock period

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
                @(negedge clk); tick_1Hz = 1; #1;
                @(negedge clk); tick_1Hz = 0; #1;
            end
        end
    endtask

    task pulse_set;
        begin
            @(negedge clk); set = 1; #1;
            @(negedge clk); set = 0; #1;
        end
    endtask

    task plus_pulse_for(input int iters);
        begin
            for (int i = 0; i < iters; i++) begin
                @(negedge clk); plus = 1; #1;
                @(negedge clk); plus = 0; #1;
            end
        end
    endtask

    initial begin
        $dumpfile("tb_clock.vcd");
        $dumpvars(0, tb_clock);

        // 1. Test areset, should be 00:00:00 and in TIME state after reset
        areset = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(ss, 0, "ss is 00");
        check_eq(mm, 0, "mm is 00");
        check_eq(hh, 0, "hh is 00");
        check_eq(dut.state, 2'b00, "clock state is TIME after reset");
        areset = 0;

        // 2. Normal operation in TIME state (30 sec)
        pulse_tick_for(30);
        check_eq(ss, 30, "ss is 30 after thirty tick signals");
        check_eq(mm, 0, "mm is 0 after thirty tick signals");

        // 3. After 40 more ticks, should be 00:01:10, sec_carry wraps through to mm
        pulse_tick_for(40);
        check_eq(ss, 10, "ss is 10");
        check_eq(mm, 1, "mm is 01");
        check_eq(hh, 0, "hh is 00");

        // 4. plus in TIME state should do nothing -- inc_hr/inc_min pulses are gated
        //    off unless state is SET_HR/SET_MIN
        plus_pulse_for(3);
        check_eq(ss, 10, "ss untouched by plus while in TIME state");
        check_eq(mm, 1, "mm untouched by plus while in TIME state");
        check_eq(hh, 0, "hh untouched by plus while in TIME state");

        // 5. set cycles TIME (00) --> SET_HR (01) --> SET_MIN (10) --> TIME (00)
        pulse_set();
        check_eq(dut.state, 2'b01, "state is SET_HR after first set press");
        pulse_set();
        check_eq(dut.state, 2'b10, "state is SET_MIN after second set press");
        pulse_set();
        check_eq(dut.state, 2'b00, "state back to TIME after third set press");

        // 6. Test 3 plus presses in SET_HR, expected hh: 00 -> 01 -> 02 -> 03
        pulse_set(); // TIME --> SET_HR
        plus_pulse_for(3);
        check_eq(hh, 3, "hh is 03 after 3 plus presses in SET_HR");
        check_eq(ss, 10, "ss untouched while setting hr");
        check_eq(mm, 1, "mm untouched while setting hr");

        // 7. Test 2 plus presses in SET_MIN, expected mm: 01 -> 02 -> 03
        pulse_set(); // SET_HR --> SET_MIN
        plus_pulse_for(2);
        check_eq(mm, 3, "mm is 03 after 2 plus presses in SET_MIN");
        check_eq(hh, 3, "hh untouched while setting min");
        pulse_set(); // SET_MIN --> TIME

        // 8. Test if time remains unchanged when in set mode (pause_sec functionality)
        pulse_set(); // TIME --> SET_HR
        pulse_tick_for(30);
        check_eq(hh, 3, "hh has not changed even with 30 tick pulses");
        check_eq(mm, 3, "mm has not changed even with 30 tick pulses");
        check_eq(ss, 10, "ss has not changed even with 30 tick pulses");
        pulse_set(); // SET_HR --> SET_MIN
        pulse_tick_for(30);
        check_eq(hh, 3, "hh has not changed even with 30 tick pulses");
        check_eq(mm, 3, "mm has not changed even with 30 tick pulses");
        check_eq(ss, 10, "ss has not changed even with 30 tick pulses");
        pulse_set(); // SET_MIN --> TIME
        pulse_tick_for(30);
        check_eq(hh, 3, "hh has not changed even with 30 tick pulses");
        check_eq(mm, 3, "mm has not changed even with 30 tick pulses");
        check_eq(ss, 40, "ss now changes");

        // 9. areset resets everything
        pulse_set(); // TIME --> SET_HR
        areset = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(ss, 0, "areset clears ss back to 0");
        check_eq(mm, 0, "areset clears mm back to 0");
        check_eq(hh, 0, "areset clears hh back to 0");
        check_eq(dut.state, 2'b00, "state back to TIME after reset");
        // ARESET
        // check_eq(dut.state, 2'b01, "areset does NOT affect clock's set-state FSM");
        areset = 0;
        // check_eq(dut.state, 2'b00, "state back to TIME after full cycle");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end
endmodule
