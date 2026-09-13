`timescale 1ns/1ps
module tb_watch;
    // clock
    logic clk = 0;
    always #5 clk = ~clk; // 10ns clock period

    // watch inputs (raw, pre-debounce -- watch.sv filters these itself now)
    logic tick_1Hz = 0;
    logic blink_en = 0;
    logic b_mode = 0;
    logic b_set = 0;
    logic b_plus = 0;

    // watch outputs
    logic[5:0] disp_pair1;
    logic[5:0] disp_pair2;

    int errors = 0;

    // debouncer.sv's THRESHOLD defaults to 200 clk cycles; hold every raw
    // button level for longer than that (with margin) so the debounced
    // signal actually settles before we check anything downstream of it
    localparam int HOLD = 210;

    watch dut (
        .clk(clk),
        .tick_1Hz(tick_1Hz),
        .blink_en(blink_en),
        .b_mode_raw(b_mode),
        .b_set_raw(b_set),
        .b_plus_raw(b_plus),
        .disp_pair1(disp_pair1),
        .disp_pair2(disp_pair2)
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

    // single button press: raw held long enough to clear the debouncer's
    // threshold, then released and held long enough for the release to
    // clear too -- so each call leaves the debounced signal fully settled
    // back at 0, ready for the next press
    task mode_press();
        begin
            @(negedge clk); b_mode = 1;
            repeat (HOLD) @(negedge clk);
            b_mode = 0;
            repeat (HOLD) @(negedge clk);
        end
    endtask

    task set_press();
        begin
            @(negedge clk); b_set = 1;
            repeat (HOLD) @(negedge clk);
            b_set = 0;
            repeat (HOLD) @(negedge clk);
        end
    endtask

    task plus_press_for(input int iters);
        begin
            for (int i = 0; i < iters; i++) begin
                @(negedge clk); b_plus = 1;
                repeat (HOLD) @(negedge clk);
                b_plus = 0;
                repeat (HOLD) @(negedge clk);
            end
        end
    endtask

    task tick_for(input int iters);
        begin
            for (int i = 0; i < iters; i++) begin
                @(negedge clk); tick_1Hz = 1; #1;
                @(negedge clk); tick_1Hz = 0; #1;
            end
        end
    endtask

    // two (or three) buttons pressed together, onset on the same clk cycle --
    // used to check AMSP priority ordering. Once debounced and edge-detected,
    // mode_pulse/set_pulse/plus_pulse are a full clk-period wide (the debounced
    // signal only changes exactly at a posedge, unlike the raw pre-debounce
    // design where the pulse was a sub-cycle transient) -- so this just waits
    // for whichever pulse fires first and samples true_mode/true_set/true_plus
    // right after, comfortably before that pulse falls a full cycle later.
    task press_together(input bit m, input bit s, input bit p);
        begin
            @(negedge clk);
            b_mode = m; b_set = s; b_plus = p;
            @(posedge dut.mode_pulse or posedge dut.set_pulse or posedge dut.plus_pulse);
            #1;
            check_eq(dut.true_mode, m, "true_mode reflects priority winner while pulse is live");
            check_eq(dut.true_set, (m) ? 1'b0 : s, "true_set reflects priority winner while pulse is live");
            check_eq(dut.true_plus, 1'b0, "true_plus suppressed while a higher-priority pulse is live");
            repeat (HOLD) @(negedge clk);
            b_mode = 0; b_set = 0; b_plus = 0;
            repeat (HOLD) @(negedge clk);
        end
    endtask

    // staggered-but-overlapping hold, the way a person actually presses three
    // physical buttons -- onsets a few cycles apart, then held together long
    // enough past the last onset for all three debouncers to clear
    task hold_all_three_staggered();
        begin
            @(negedge clk); b_mode = 1;
            repeat (5) @(negedge clk); b_set = 1;
            repeat (5) @(negedge clk); b_plus = 1;
            repeat (HOLD) @(negedge clk);
        end
    endtask

    task release_all();
        begin
            b_mode = 0; b_set = 0; b_plus = 0;
            repeat (HOLD) @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("tb_watch.vcd");
        $dumpvars(0, tb_watch);

        // 1. state has no reset initializer, so the only way into a known state
        //    is fact_rst -- hold all three buttons to get there
        hold_all_three_staggered();
        check_eq(dut.fact_rst, 1'b1, "fact_rst asserts on a realistic staggered 3-button hold");
        release_all();
        check_eq(dut.state, 2'b00, "state is TIME after factory reset");
        check_eq(dut.c_state, 2'b00, "clock sub-state is idle after factory reset");
        check_eq(dut.a_state, 2'b00, "alarm sub-state is idle after factory reset");

        // 2. mode cycles TIME -> STOPWATCH -> ALARM_VIEW -> TIME, one state per
        //    single press (this is the double-step bug from before: a single
        //    press must not walk two states at once)
        mode_press();
        check_eq(dut.state, 2'b01, "single mode press: TIME -> STOPWATCH");
        mode_press();
        check_eq(dut.state, 2'b10, "single mode press: STOPWATCH -> ALARM_VIEW");
        mode_press();
        check_eq(dut.state, 2'b00, "single mode press: ALARM_VIEW -> TIME (a_state was idle)");

        // 3. AMSP priority: mode beats plus when pressed together
        press_together(1, 0, 1);
        check_eq(dut.state, 2'b01, "state advanced on mode's transition, not plus's");
        check_eq(dut.time_hh, 5'd0, "time_hh untouched -- plus's action was suppressed");
        mode_press(); // STOPWATCH -> ALARM_VIEW, back toward TIME for the next check
        mode_press(); // ALARM_VIEW -> TIME
        check_eq(dut.state, 2'b00, "back in TIME for the next priority check");

        // 4. AMSP priority: set beats plus when pressed together
        press_together(0, 1, 1);

        // 5. factory reset again to get back to a clean, known state before the
        //    alarm-set / blink checks below (step 4 may have nudged c_state via
        //    the set pulse depending on how u_clock.set is wired -- see step 7)
        hold_all_three_staggered();
        release_all();
        check_eq(dut.state, 2'b00, "state is TIME after second factory reset");
        check_eq(dut.a_state, 2'b00, "alarm sub-state is idle after second factory reset");

        // 6. enter ALARM_VIEW, cycle into its set_hr/set_min, and check blinking
        mode_press(); // TIME -> STOPWATCH
        mode_press(); // STOPWATCH -> ALARM_VIEW
        check_eq(dut.state, 2'b10, "state is ALARM_VIEW");
        set_press();  // idle -> set_hr
        check_eq(dut.a_state, 2'b01, "alarm sub-state is set_hr");
        blink_en = 0;
        #1; check_eq(disp_pair1, 6'b111111, "disp_pair1 blanked while blink_en=0 in alarm set_hr");
        blink_en = 1;
        #1; check_eq(disp_pair1, {1'b0, dut.alarm_hh}, "disp_pair1 shows alarm_hh while blink_en=1 in alarm set_hr");
        plus_press_for(2);
        #1; check_eq(disp_pair1, {1'b0, dut.alarm_hh}, "disp_pair1 tracks alarm_hh after plus presses (blink_en=1)");
        check_eq(dut.alarm_hh, 5'd2, "alarm_hh incremented to 2 by two plus presses");
        set_press(); // set_hr -> set_min
        check_eq(dut.a_state, 2'b10, "alarm sub-state is set_min");
        blink_en = 0;
        #1; check_eq(disp_pair2, 6'b111111, "disp_pair2 blanked while blink_en=0 in alarm set_min");
        blink_en = 1;
        #1; check_eq(disp_pair2, dut.alarm_mm, "disp_pair2 shows alarm_mm while blink_en=1 in alarm set_min");
        set_press(); // set_min -> idle
        check_eq(dut.a_state, 2'b00, "alarm sub-state back to idle");
        mode_press(); // ALARM_VIEW -> TIME, only legal now that a_state is idle
        check_eq(dut.state, 2'b00, "mode press returns to TIME now that alarm sub-state is idle");

        // 7. entering the clock's own set_hr from TIME -- confirms u_clock's
        //    .set(...) is gated on (state==2'b00), matching .plus(...)
        check_eq(dut.state, 2'b00, "confirm in TIME before testing clock set-entry");
        set_press();
        check_eq(dut.c_state, 2'b01, "set press in TIME moves clock to set_hr");
        set_press(); // set_hr -> set_min
        set_press(); // set_min -> idle, back to a clean state
        check_eq(dut.c_state, 2'b00, "clock sub-state back to idle");

        // 8. ALARM_RING: force trigger_alarm directly to test the FSM's reaction
        //    without re-deriving alarm_view's own hh:mm match logic (already
        //    covered by tb_alarm_view.sv)
        hold_all_three_staggered();
        release_all();
        force dut.trigger_alarm = 1'b1;
        @(negedge clk); @(negedge clk);
        check_eq(dut.state, 2'b11, "trigger_alarm forces state to ALARM_RING from anywhere");
        blink_en = 0;
        #1;
        check_eq(disp_pair1, 6'b111111, "disp_pair1 blanked while blink_en=0 in ALARM_RING");
        check_eq(disp_pair2, 6'b111111, "disp_pair2 blanked while blink_en=0 in ALARM_RING");
        blink_en = 1;
        #1;
        check_eq(disp_pair1, {1'b0, dut.time_hh}, "disp_pair1 shows time_hh while blink_en=1 in ALARM_RING");
        check_eq(disp_pair2, dut.time_mm, "disp_pair2 shows time_mm while blink_en=1 in ALARM_RING");
        release dut.trigger_alarm;
        mode_press(); // any press should silence the ring and return to TIME
        check_eq(dut.state, 2'b00, "a button press silences ALARM_RING back to TIME");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end
endmodule