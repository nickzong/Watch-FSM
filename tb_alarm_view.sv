`timescale 1ns/1ps

module tb_alarm_view;
    // clock
    logic clk = 0;
    always #5 clk = ~clk; // 10ps clock period

    // test_clock inputs
    logic clk_rst = 0;
    logic tick = 0;
    logic inc_min_pulse_tk = 0;
    logic inc_hr_pulse_tk = 0;
    logic pause_sec = 0;

    // test_clock outputs, fed into alarm_view as the current hh:mm
    logic[5:0] ss;
    logic[5:0] mm;
    logic[4:0] hh;
    logic s_carry;

    // alarm_view inputs
    logic alarm_rst = 0;
    logic plus = 0;
    logic set_state = 0;

    // alarm_view outputs
    logic trigger_alarm;
    logic[5:0] alarm_mm;
    logic[4:0] alarm_hh;

    int errors = 0;

    time_keeper test_clock ( // drives the "current time" into alarm_view for testing alarm triggering
        .clk(clk), 
        .areset(clk_rst), 
        .tick_1Hz(tick),
        .inc_min_pulse(inc_min_pulse_tk), 
        .inc_hr_pulse(inc_hr_pulse_tk), 
        .pause_sec(pause_sec),
        .ss(ss), 
        .mm(mm), 
        .hh(hh), 
        .s_carry(s_carry)
    );

    alarm_view dut (
        .clk(clk),
        .areset(alarm_rst),
        .plus(plus),
        .set_state(set_state),
        .s_carry(s_carry),
        .mm(mm),
        .hh(hh),
        .trigger_alarm(trigger_alarm),
        .alarm_mm(alarm_mm),
        .alarm_hh(alarm_hh)
    );
    
    // ------ HELPER FUNCTIONS ------
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

    // pulse signal functions for test_clock
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
                @(negedge clk); inc_min_pulse_tk = 1; #1;
                @(negedge clk); inc_min_pulse_tk = 0; #1;
            end
        end
    endtask

    task inc_hr_for(input int iters);
        begin
            for (int i = 0; i < iters; i++) begin
                @(negedge clk); inc_hr_pulse_tk = 1; #1;
                @(negedge clk); inc_hr_pulse_tk = 0; #1;
            end
        end
    endtask

    // for DUT
    task set_state_pulse(); 
        begin
            @(negedge clk); set_state = 1; #1;
            @(negedge clk); set_state = 0; #1;
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

    // cycles idle -> set_hr -> set_min -> idle, pressing plus hr/min times in each stage
    task set_alarm(input int hr, input int min);
        begin
            set_state_pulse();
            plus_pulse_for(hr);
            set_state_pulse();
            plus_pulse_for(min);
            set_state_pulse();
        end
    endtask

    // ticks the real clock through the last second of iters minutes and captures
    // trigger_alarm exactly during the final second-rollover pulse, before the
    // minute counter actually increments
    task tick_to_rollover_and_check(input [8*80-1:0] msg, input bit exp_trigger);
        begin
            pulse_tick_for(59);
            @(negedge clk); tick = 1; #1;
            check_eq(trigger_alarm, exp_trigger, msg);
            @(negedge clk); tick = 0; #1;
        end
    endtask

    initial begin
        $dumpfile("tb_alarm_view.vcd");
        $dumpvars(0, tb_alarm_view);

        // 1. reset both the real clock and the alarm
        clk_rst = 1; alarm_rst = 1;
        pulse_tick_for(1);
        @(negedge clk);
        @(negedge clk);
        check_eq(mm, 0, "real clock mm is 0 after reset");
        check_eq(hh, 0, "real clock hh is 0 after reset");
        check_eq(alarm_mm, 0, "alarm_mm is 0 after reset");
        check_eq(alarm_hh, 0, "alarm_hh is 0 after reset");
        check_eq(trigger_alarm, 0, "trigger_alarm low after reset");
        check_eq(dut.state, 2'b00, "alarm_view state is idle after reset");
        check_eq(dut.armed, 1'b0, "alarm_view armed is 0 after reset");
        clk_rst = 0; alarm_rst = 0;

        // 2. Testing set state cycle idle --> set_hr --> set_min --> idle
        set_alarm(0, 0);
        check_eq(alarm_mm, 0, "alarm_mm unchanged (0) after a 0-press set cycle");
        check_eq(alarm_hh, 0, "alarm_hh unchanged (0) after a 0-press set cycle");
        check_eq(dut.state, 2'b00, "alarm_view state back to idle after full cycle");
        check_eq(dut.armed, 1'b1, "alarm_view armed goes high after full cycle");

        // 3. Test if trigger_alarm fires on sec rollover
        tick_to_rollover_and_check("trigger_alarm high at rollover matching alarm 00:00", 1'b1);
        check_eq(mm, 1, "real clock mm advanced to 1 after rollover");
        check_eq(trigger_alarm, 0, "trigger_alarm low again once rollover settles");

        // 4. reconfigure alarm to 00:01 
        set_alarm(0, 1);
        check_eq(alarm_mm, 1, "alarm_mm set to 1");
        check_eq(alarm_hh, 0, "alarm_hh unchanged (0)");

        // 5. real clock rolls 00:01:59 -> 00:02:00: should now match the new alarm
        tick_to_rollover_and_check("trigger_alarm high at rollover matching alarm 00:01", 1'b1);
        check_eq(mm, 2, "real clock mm advanced to 2 after rollover");

        // 6. matching hh:mm, no sec rollover, must NOT trigger
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_min_for(1); // real clock mm: 0 -> 1, matches alarm_mm(1), but no s_carry occurred
        check_eq(mm, 1, "real clock mm fast-forwarded to 1 via inc_min_pulse");
        check_eq(trigger_alarm, 0, "trigger_alarm stays low without a genuine s_carry rollover");

        // 7. set alarm_hh to 2, don't touch min, confirm previously set alarm is stored
        set_alarm(2, 0);
        check_eq(alarm_hh, 2, "alarm_hh set to 2");
        check_eq(alarm_mm, 1, "alarm_mm still 1 (unchanged by a 0-press minute stage)");

        // 8. full hh+mm match: fast-forward real clock to 02:01, then roll into 02:02
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_hr_for(2);
        inc_min_for(1);
        check_eq(hh, 2, "real clock hh fast-forwarded to 2");
        check_eq(mm, 1, "real clock mm fast-forwarded to 1");
        tick_to_rollover_and_check("trigger_alarm high at rollover matching alarm 02:01", 1'b1);
        check_eq(mm, 2, "real clock mm advanced to 2 after rollover");
        check_eq(hh, 2, "real clock hh still 2 after rollover");

        // 9. hh mismatch, mm matches, trigger_alarm should not fire
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_hr_for(3);
        inc_min_for(1);
        check_eq(hh, 3, "real clock hh set to 3 (mismatched with alarm_hh=2)");
        check_eq(mm, 1, "real clock mm set to 1 (matches alarm_mm)");
        tick_to_rollover_and_check("trigger_alarm stays low: hh mismatch (3 != 2)", 1'b0);

        // 10. areset does not reset the set-state FSM, only the internal alarm time
        set_state_pulse(); // idle -> set_hr
        check_eq(dut.state, 2'b01, "alarm_view state is set_hr");
        alarm_rst = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(alarm_mm, 0, "areset clears alarm_mm back to 0");
        check_eq(alarm_hh, 0, "areset clears alarm_hh back to 0");
        check_eq(dut.state, 2'b01, "areset does NOT affect alarm_view's set_state FSM");
        alarm_rst = 0;
        set_state_pulse(); // set_hr -> set_min
        set_state_pulse(); // set_min -> idle
        check_eq(dut.state, 2'b00, "alarm_view state back to idle");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end
endmodule
