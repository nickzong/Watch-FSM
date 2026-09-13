`timescale 1ns/1ps
// areset now clears armed, state, and the alarm time -- tests below re-arm/re-set
// after each areset instead of assuming it survives, matching that intended behavior
module tb_alarm_view;
    // clock
    logic clk = 0;
    always #5 clk = ~clk; // 10ns clock period

    // test_clock inputs
    logic clk_rst = 0;
    logic tick = 0;
    logic inc_min_pulse_tk = 0;
    logic inc_hr_pulse_tk = 0;
    logic pause_sec = 0;

    // test_clock outputs, fed into alarm_view as the current hh:mm
    logic[5:0] ss;
    logic[5:0] mm;
    logic[5:0] hh;
    logic s_carry;

    // alarm_view inputs
    logic alarm_rst = 0;
    logic plus = 0;
    logic set_state = 0;

    // alarm_view outputs
    logic trigger_alarm;
    logic[5:0] alarm_mm;
    logic[5:0] alarm_hh;

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
    // (does not touch armed: plus is only pressed while state is set_hr/set_min here)
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

        // 2. test armed toggling functionality
        plus_pulse_for(1);
        check_eq(dut.armed, 1'b1, "armed toggles on from a single plus press in idle");
        check_eq(dut.state, 2'b00, "alarm_view stays in idle after toggling armed");
        check_eq(alarm_mm, 0, "alarm_mm untouched by toggling armed");
        check_eq(alarm_hh, 0, "alarm_hh untouched by toggling armed");

        plus_pulse_for(1);
        check_eq(dut.armed, 1'b0, "armed toggles back off from a second plus press in idle");

        plus_pulse_for(1);
        check_eq(dut.armed, 1'b1, "armed toggles on again; left armed for the rollover tests below");

        // 3. plus presses during set_hr/set_min increment the alarm time instead of
        //    toggling armed
        set_state_pulse(); // idle -> set_hr
        plus_pulse_for(1);
        check_eq(alarm_hh, 1, "alarm_hh incremented by plus while in set_hr");
        check_eq(dut.armed, 1'b1, "armed unaffected by plus while in set_hr");
        set_state_pulse(); // set_hr -> set_min
        plus_pulse_for(1);
        check_eq(alarm_mm, 1, "alarm_mm incremented by plus while in set_min");
        check_eq(dut.armed, 1'b1, "armed unaffected by plus while in set_min");
        set_state_pulse(); // set_min -> idle
        check_eq(dut.state, 2'b00, "alarm_view state back to idle after full cycle");

        // clear the alarm time back to 00:00 for the rollover test below;
        // areset now also clears armed and the set-state FSM, so re-arm afterward
        alarm_rst = 1;
        @(negedge clk);
        @(negedge clk);
        alarm_rst = 0;
        check_eq(alarm_mm, 0, "alarm_mm cleared back to 0 by areset");
        check_eq(alarm_hh, 0, "alarm_hh cleared back to 0 by areset");
        check_eq(dut.armed, 1'b0, "areset clears armed back to 0");

        // re-arm for the rollover tests below (armed does not survive areset anymore)
        plus_pulse_for(1);
        check_eq(dut.armed, 1'b1, "re-armed after reset for the rollover tests below");

        // 4. Test if trigger_alarm fires on sec rollover now that armed is on
        pulse_tick_for(59);
        @(negedge clk); tick = 1; #1;
        check_eq(trigger_alarm, 1'b1, "trigger_alarm high at rollover matching alarm 00:00");
        @(negedge clk); tick = 0; #1;
        check_eq(mm, 1, "real clock mm advanced to 1 after rollover");
        check_eq(trigger_alarm, 0, "trigger_alarm low again once rollover settles");

        // 5. reconfigure alarm to 00:01
        set_alarm(0, 1);
        check_eq(alarm_mm, 1, "alarm_mm set to 1");
        check_eq(alarm_hh, 0, "alarm_hh unchanged (0)");

        // 6. real clock rolls 00:01:59 -> 00:02:00: should now match the new alarm
        pulse_tick_for(59);
        @(negedge clk); tick = 1; #1;
        check_eq(trigger_alarm, 1'b1, "trigger_alarm high at rollover matching alarm 00:01");
        @(negedge clk); tick = 0; #1;
        check_eq(mm, 2, "real clock mm advanced to 2 after rollover");

        // 7. matching hh:mm, no sec rollover, must NOT trigger
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_min_for(1); // real clock mm: 0 -> 1, matches alarm_mm(1), but no s_carry occurred
        check_eq(mm, 1, "real clock mm fast-forwarded to 1 via inc_min_pulse");
        check_eq(trigger_alarm, 0, "trigger_alarm stays low without a genuine s_carry rollover");

        // 8. set alarm_hh to 2, don't touch min, confirm previously set alarm is stored
        set_alarm(2, 0);
        check_eq(alarm_hh, 2, "alarm_hh set to 2");
        check_eq(alarm_mm, 1, "alarm_mm still 1 (unchanged by a 0-press minute stage)");

        // 9. full hh+mm match: fast-forward real clock to 02:01, then roll into 02:02
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_hr_for(2);
        inc_min_for(1);
        check_eq(hh, 2, "real clock hh fast-forwarded to 2");
        check_eq(mm, 1, "real clock mm fast-forwarded to 1");
        pulse_tick_for(59);
        @(negedge clk); tick = 1; #1;
        check_eq(trigger_alarm, 1'b1, "trigger_alarm high at rollover matching alarm 02:01");
        @(negedge clk); tick = 0; #1;
        check_eq(mm, 2, "real clock mm advanced to 2 after rollover");
        check_eq(hh, 2, "real clock hh still 2 after rollover");

        // 10. hh mismatch, mm matches, trigger_alarm should not fire
        clk_rst = 1; @(negedge clk); @(negedge clk); clk_rst = 0;
        inc_hr_for(3);
        inc_min_for(1);
        check_eq(hh, 3, "real clock hh set to 3 (mismatched with alarm_hh=2)");
        check_eq(mm, 1, "real clock mm set to 1 (matches alarm_mm)");
        tick_to_rollover_and_check("trigger_alarm stays low: hh mismatch (3 != 2)", 1'b0);

        // 11. areset now resets the set-state FSM back to idle too, not just the alarm time
        set_state_pulse(); // idle -> set_hr
        check_eq(dut.state, 2'b01, "alarm_view state is set_hr");
        alarm_rst = 1;
        @(negedge clk);
        @(negedge clk);
        check_eq(alarm_mm, 0, "areset clears alarm_mm back to 0");
        check_eq(alarm_hh, 0, "areset clears alarm_hh back to 0");
        check_eq(dut.state, 2'b00, "areset resets alarm_view's set-state FSM back to idle");
        alarm_rst = 0;
        // (no extra set_state_pulse()s needed here anymore -- state is already idle
        // right out of the areset above, so pressing set twice more would actually
        // walk it to set_min instead of leaving it at idle)

        // 12. testing no trigger_alarm pulse when alarm rolls over and matches, but disarmed
        check_eq(dut.armed, 1'b0, "alarm_view starts disarmed after the areset above");
        set_alarm(3, 2);
        check_eq(alarm_hh, 3, "alarm_hh set to match real clock (3)");
        check_eq(alarm_mm, 2, "alarm_mm set to match real clock (2)");
        tick_to_rollover_and_check("trigger_alarm stays low at matching rollover while disarmed", 1'b0);

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end
endmodule