// clk_rst, finish button, maybe put each hh, mm, ss as internal logic 
// and replace with two output logic regs called first_two and last_two. 
// add to the mode cycle an update of which two are being used to display currently
// add blinking when setting hr and min

// ADD ARESET CAPABILITIES TO OTHER MODULES
module watch (
    input logic clk,
    input logic tick_1Hz,
    input logic blink_en, // 2 Hz signal to drive blinking in set modes
    input logic b_mode,
    input logic b_set,
    input logic b_plus,
    
    output logic[5:0] disp_pair1,
    output logic[5:0] disp_pair2
);

    logic[1:0] state, next_state;
    logic[1:0] c_state; // tracker for the current clock state
    logic[1:0] a_state; // tracker for the current alarm state
    logic s_carry;

    // internal registers used to store time for all three modes
    logic[5:0] time_ss; 
    logic[5:0] time_mm;
    logic[4:0] time_hh;
    logic[5:0] sw_ss;
    logic[5:0] sw_mm;
    logic[5:0] alarm_mm;
    logic[4:0] alarm_hh;

    // signals for watch mode instances' inputs
    logic fact_rst; // when in time state, if all three buttons are pressed at once, factory reset everything
    logic trigger_alarm;
    logic true_mode, true_set, true_plus; // encodes AMSP hierarchy

    // button pulses that stay at 1 for only 1 clk cycle
    logic b_mode_prev, mode_pulse;
    always_ff @(posedge clk) b_mode_prev <= b_mode;
    assign mode_pulse = b_mode & ~b_mode_prev; // one cycle wide exactly on the rising edge

    logic b_set_prev, set_pulse;
    always_ff @(posedge clk) b_set_prev <= b_set;
    assign set_pulse = b_set & ~b_set_prev; // one cycle wide, exactly on the rising edge

    logic b_plus_prev, plus_pulse;
    always_ff @(posedge clk) b_plus_prev <= b_plus;
    assign plus_pulse = b_plus & ~b_plus_prev; // one cycle wide, exactly on the rising edge

    clock u_clock ( 
        .clk(clk),
        .areset(fact_rst),
        .tick_1Hz(tick_1Hz),
        .plus(true_plus && (state == 2'b00)),
        .set(true_set && (state == 2'b01)),
        .s_carry(s_carry),
        .state(c_state),
        .ss(time_ss),
        .mm(time_mm),
        .hh(time_hh)
    );

    stopwatch u_stopwatch (
        .clk(clk), 
        .areset(fact_rst | (true_plus && (state == 2'b01))), 
        .tick(tick_1Hz),
        .set(true_set && (state == 2'b01)), 
        .ss(sw_ss), 
        .mm(sw_mm)
    );

    alarm_view u_alarm (
        .clk(clk),
        .areset(fact_rst),
        .plus(true_plus && (state == 2'b10)),
        .set_state(true_set && (state == 2'b10)),
        .s_carry(s_carry),
        .mm(time_mm),
        .hh(time_hh),
        .trigger_alarm(trigger_alarm),
        .state(a_state),
        .alarm_mm(alarm_mm),
        .alarm_hh(alarm_hh)
    );
    
    // true signals go to 1 if the signal is the highest priority in the AMSP hierarchy: async alarm > mode > set > plus
    assign true_mode = !trigger_alarm & mode_pulse;
    assign true_set = !trigger_alarm & !mode_pulse & set_pulse;
    assign true_plus = !trigger_alarm & !mode_pulse & !set_pulse & plus_pulse;

    always_comb begin
        next_state = state; // default
        if (trigger_alarm)  next_state = 2'b11; 

        // mode button and alarm silence functions
        // define mode cycle: time (00) --> stopwatch (01) --> alarm (10) --> time (00)
        case (state)
            2'b00: if (true_mode && c_state == 2'b00) next_state = 2'b01; // can only switch if idle
            2'b01: if (true_mode) next_state = 2'b10;
            2'b10: if (true_mode && a_state == 2'b00) next_state = 2'b00; // can only switch if idle
            2'b11: if (true_mode || true_set || true_plus) next_state = 2'b00; // silence alarm, alarm_ring state
            default: next_state = state;
        endcase
        
        // display output logic
        case (state)
            2'b00: begin
                case (c_state) 
                    2'b00: begin // idle
                        disp_pair1 = time_hh;
                        disp_pair2 = time_mm;
                    end
                    2'b01: begin // set_hr
                        disp_pair1 = (blink_en) ? time_hh : '0;
                        disp_pair2 = time_mm;
                    end
                    2'b10: begin // set_min
                        disp_pair1 = time_hh;
                        disp_pair2 = (blink_en) ? time_mm : '0;
                    end
                    default: begin
                        disp_pair1 = time_hh;
                        disp_pair2 = time_mm;
                    end
                endcase
            end
            2'b01: begin
                disp_pair1 = sw_mm;
                disp_pair2 = sw_ss;
            end
            2'b10: begin
                case (a_state) 
                    2'b00: begin // idle
                        disp_pair1 = alarm_hh;
                        disp_pair2 = alarm_mm;
                    end
                    2'b01: begin // set_hr
                        disp_pair1 = (blink_en) ? alarm_hh : '0;
                        disp_pair2 = alarm_mm;
                    end
                    2'b10: begin // set_min
                        disp_pair1 = alarm_hh;
                        disp_pair2 = (blink_en) ? alarm_mm : '0;
                    end
                    default: begin
                        disp_pair1 = alarm_hh;
                        disp_pair2 = alarm_mm;
                    end
                endcase
            end
            2'b11: begin
                disp_pair1 = (blink_en) ? time_hh : '0;
                disp_pair2 = (blink_en) ? time_mm : '0;
            end
            default:  begin
                disp_pair1 = time_hh;
                disp_pair2 = time_mm;
            end
        endcase

    end

    always_ff @(posedge clk, posedge fact_rst) begin
        if (fact_rst) state <= 2'b00;
        else state <= next_state;
    end
    
    assign fact_rst = b_mode & b_set & b_plus;
    
endmodule