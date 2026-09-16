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

    // watch outputs -- display.sv is now instantiated inside watch.sv, so
    // the DUT exposes 7-segment codes (and trigger_alarm) instead of the
    // raw 6-bit disp_pair1/disp_pair2 it used to. The pair-level checks
    // below still reach in via dut.disp_pair1/dut.disp_pair2 (the internal
    // signals that feed display.sv) rather than decoding 7-segment codes.
    logic[6:0] top_tens_7sd;
    logic[6:0] top_ones_7sd;
    logic[6:0] bottom_tens_7sd;
    logic[6:0] bottom_ones_7sd;
    logic trigger_alarm;

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
        .top_tens_7sd(top_tens_7sd),
        .top_ones_7sd(top_ones_7sd),
        .bottom_tens_7sd(bottom_tens_7sd),
        .bottom_ones_7sd(bottom_ones_7sd),
        .trigger_alarm(trigger_alarm)
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

    task check_seg(input logic[6:0] got, input logic[6:0] exp, input string msg);
        begin
            if (got !== exp) begin
                $display("FAIL: %0s (got=%07b expected=%07b) at t=%0t", msg, got, exp, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: %0s (=%07b) at t=%0t", msg, got, $time);
            end
        end
    endtask

    // standalone 0-9 -> [a b c d e f g] 7-segment lookup, independent of
    // display.sv's own localparams, so this actually checks the decoding
    // rather than just echoing the DUT's constants back at itself
    function automatic logic [6:0] digit_seg(input int digit);
        case (digit)
            0: digit_seg = 7'b1111110;
            1: digit_seg = 7'b0110000;
            2: digit_seg = 7'b1101101;
            3: digit_seg = 7'b1111001;
            4: digit_seg = 7'b0110011;
            5: digit_seg = 7'b1011011;
            6: digit_seg = 7'b1011111;
            7: digit_seg = 7'b1110000;
            8: digit_seg = 7'b1111111;
            9: digit_seg = 7'b1110011;
            default: digit_seg = 7'b1111110; // display.sv's default case also shows 0
        endcase
    endfunction

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

    // Exercises display.sv in isolation by forcing its inputs (dut.disp_pair1/
    // disp_pair2, the signals watch.sv's own always_comb block normally drives)
    // directly, rather than steering the whole FSM through button presses just
    // to land on a particular pair value. Forcing wins over the always_comb
    // driver until released at the end, so this can hit every case -- including
    // the blink code and out-of-range values -- that the FSM tests below never
    // visit on their own.
    task test_display_decoding();
        int top_val, bottom_val;
        logic [6:0] exp_top_tens, exp_top_ones, exp_bottom_tens, exp_bottom_ones;
        begin
            // sweep every valid BCD-pair value 0-59; top and bottom are given
            // different values each iteration so a top/bottom cross-wiring bug
            // would also get caught
            for (top_val = 0; top_val <= 59; top_val++) begin
                bottom_val = 59 - top_val;
                force dut.disp_pair1 = top_val[5:0];
                force dut.disp_pair2 = bottom_val[5:0];
                @(posedge clk); #1;
                exp_top_tens    = digit_seg(top_val / 10);
                exp_top_ones    = digit_seg(top_val % 10);
                exp_bottom_tens = digit_seg(bottom_val / 10);
                exp_bottom_ones = digit_seg(bottom_val % 10);
                check_seg(top_tens_7sd, exp_top_tens, $sformatf("display: top_pair=%0d tens digit", top_val));
                check_seg(top_ones_7sd, exp_top_ones, $sformatf("display: top_pair=%0d ones digit", top_val));
                check_seg(bottom_tens_7sd, exp_bottom_tens, $sformatf("display: bottom_pair=%0d tens digit", bottom_val));
                check_seg(bottom_ones_7sd, exp_bottom_ones, $sformatf("display: bottom_pair=%0d ones digit", bottom_val));
            end

            // reserved blink/blank code (6'b111111) blanks both digits on both pairs
            force dut.disp_pair1 = 6'b111111;
            force dut.disp_pair2 = 6'b111111;
            @(posedge clk); #1;
            check_seg(top_tens_7sd, 7'b0000000, "display: top_pair=blink blanks top_tens_7sd");
            check_seg(top_ones_7sd, 7'b0000000, "display: top_pair=blink blanks top_ones_7sd");
            check_seg(bottom_tens_7sd, 7'b0000000, "display: bottom_pair=blink blanks bottom_tens_7sd");
            check_seg(bottom_ones_7sd, 7'b0000000, "display: bottom_pair=blink blanks bottom_ones_7sd");

            // out-of-range pair values (60-62; 63 is the blink code above) fall
            // through to display.sv's default case, which shows "00"
            for (top_val = 60; top_val <= 62; top_val++) begin
                force dut.disp_pair1 = top_val[5:0];
                force dut.disp_pair2 = top_val[5:0];
                @(posedge clk); #1;
                check_seg(top_tens_7sd, digit_seg(0), $sformatf("display: out-of-range pair=%0d defaults top tens to 0", top_val));
                check_seg(top_ones_7sd, digit_seg(0), $sformatf("display: out-of-range pair=%0d defaults top ones to 0", top_val));
                check_seg(bottom_tens_7sd, digit_seg(0), $sformatf("display: out-of-range pair=%0d defaults bottom tens to 0", top_val));
                check_seg(bottom_ones_7sd, digit_seg(0), $sformatf("display: out-of-range pair=%0d defaults bottom ones to 0", top_val));
            end

            release dut.disp_pair1;
            release dut.disp_pair2;
        end
    endtask

    initial begin
        $dumpfile("tb_watch.vcd");
        $dumpvars(0, tb_watch);

        // 1. verify display.sv's 7-segment decoding directly, before the FSM
        //    tests below reclaim disp_pair1/disp_pair2 for themselves
        test_display_decoding();

        // 2. state has no reset initializer, so the only way into a known state
        //    is fact_rst -- hold all three buttons to get there
        hold_all_three_staggered();
        check_eq(dut.fact_rst, 1'b1, "fact_rst asserts on a realistic staggered 3-button hold");
        release_all();
        check_eq(dut.state, 2'b00, "state is TIME after factory reset");
        check_eq(dut.c_state, 2'b00, "clock sub-state is idle after factory reset");
        check_eq(dut.a_state, 2'b00, "alarm sub-state is idle after factory reset");

        // 3. mode cycles TIME -> STOPWATCH -> ALARM_VIEW -> TIME, one state per
        //    single press (this is the double-step bug from before: a single
        //    press must not walk two states at once)
        mode_press();
        check_eq(dut.state, 2'b01, "single mode press: TIME -> STOPWATCH");
        mode_press();
        check_eq(dut.state, 2'b10, "single mode press: STOPWATCH -> ALARM_VIEW");
        mode_press();
        check_eq(dut.state, 2'b00, "single mode press: ALARM_VIEW -> TIME (a_state was idle)");

        // 4. AMSP priority: mode beats set when pressed together
        press_together(1, 1, 0);

        // 4. AMSP priority: mode beats plus when pressed together
        // note: the previous press_together(1, 1, 0) call already won mode's
        // priority and drove a real mode transition (TIME -> STOPWATCH), so
        // this second mode-priority win advances STOPWATCH -> ALARM_VIEW
        press_together(1, 0, 1);
        check_eq(dut.state, 2'b10, "state advanced on mode's transition, not plus's");
        check_eq(dut.time_hh, 5'd0, "time_hh untouched -- plus's action was suppressed");
        mode_press(); // ALARM_VIEW -> TIME
        check_eq(dut.state, 2'b00, "back in TIME for the next priority check");

        // 4. AMSP priority: set beats plus when pressed together
        press_together(0, 1, 1);

        // 4. AMSP priority: all press
        press_together(1, 1, 1);

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
        #1; check_eq(dut.disp_pair1, 6'b111111, "disp_pair1 blanked while blink_en=0 in alarm set_hr");
        blink_en = 1;
        #1; check_eq(dut.disp_pair1, {1'b0, dut.alarm_hh}, "disp_pair1 shows alarm_hh while blink_en=1 in alarm set_hr");
        plus_press_for(2);
        #1; check_eq(dut.disp_pair1, {1'b0, dut.alarm_hh}, "disp_pair1 tracks alarm_hh after plus presses (blink_en=1)");
        check_eq(dut.alarm_hh, 5'd2, "alarm_hh incremented to 2 by two plus presses");
        set_press(); // set_hr -> set_min
        check_eq(dut.a_state, 2'b10, "alarm sub-state is set_min");
        blink_en = 0;
        #1; check_eq(dut.disp_pair2, 6'b111111, "disp_pair2 blanked while blink_en=0 in alarm set_min");
        blink_en = 1;
        #1; check_eq(dut.disp_pair2, dut.alarm_mm, "disp_pair2 shows alarm_mm while blink_en=1 in alarm set_min");
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
        check_eq(dut.disp_pair1, 6'b111111, "disp_pair1 blanked while blink_en=0 in ALARM_RING");
        check_eq(dut.disp_pair2, 6'b111111, "disp_pair2 blanked while blink_en=0 in ALARM_RING");
        blink_en = 1;
        #1;
        check_eq(dut.disp_pair1, {1'b0, dut.time_hh}, "disp_pair1 shows time_hh while blink_en=1 in ALARM_RING");
        check_eq(dut.disp_pair2, dut.time_mm, "disp_pair2 shows time_mm while blink_en=1 in ALARM_RING");
        release dut.trigger_alarm;
        mode_press(); // any press should silence the ring and return to TIME
        check_eq(dut.state, 2'b00, "a button press silences ALARM_RING back to TIME");

        if (errors == 0) $display("\nALL CHECKS PASSED");
        else   $display("\n%0d CHECK(S) FAILED", errors);

        $finish;
    end
endmodule