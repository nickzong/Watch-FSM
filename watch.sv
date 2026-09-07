// clk_rst, finish button, maybe put each hh, mm, ss as internal logic 
// and replace with two output logic regs called first_two and last_two. 
// add to the mode cycle an update of which two are being used to display currently
// add blinking when setting hr and min
module watch (
    input logic clk,
    input logic tick_1Hz,
    input logic b_mode,
    input logic b_set,
    input logic b_plus,
    
    output logic[5:0] disp_first_two,
    output logic[5:0] disp_second_two
);

    logic[1:0] state = 2'b00;
    logic[1:0] c_state = 2'b00; // tracker for the current clock state
    logic[1:0] a_state = 2'b00; // tracker for the current alarm state

    logic clk_rst = 0; // when in time state, if all three buttons are pressed at once, factory reset everything
    logic trigger_alarm = 0;

    // internal registers used to store time for all three modes
    logic[5:0] time_ss = 0; 
    logic[5:0] time_mm = 0;
    logic[4:0] time_hh = 0;
    logic[5:0] sw_ss = 0;
    logic[5:0] sw_mm = 0;
    logic[5:0] alarm_mm = 0;
    logic[4:0] alarm_hh = 0;

    //TODO add a combo logic block to control the display flow

    // sequential block to handle mode, set, and plus buttons and encode AMSP button priority: async alarm > mode > set > plus
    always_ff @(posedge trigger_alarm, posedge b_mode, posedge b_set, posedge b_plus) begin
        if (trigger_alarm) begin 
            state = 2'b11;
        end else if (b_mode) begin // mode button functions
            // define mode cycle: time (00) --> stopwatch (01) --> alarm (10) --> time (00)
            // mode switch only allowed in idle states, not in set states
            case (state)
                2'b00: if (c_state == 2'b00) state = 2'b01;
                2'b01: state = 2'b10;
                2'b10: if (a_state == 2'b00) state = 2'b00;
                2'b11: state = 2'b00; // silence alarm, alarm_ring state
                default: state = 2'b00;
            endcase
        end else if (b_set) begin // set button functions
            // create time set cycle: time (00) --> set_hr (01) --> set_min (10) --> time (00)
            if (state == 2'b00) begin
                case (t_state)
                    2'b00: t_state = 2'b01;
                    2'b01: t_state = 2'b10;
                    2'b10: t_state = 2'b00;
                    default: t_state = 2'b00;
                endcase
            end else if (state == 2'b11) begin // silence alarm, alarm_ring state
                state = 2'b00;
            end
        end else if (b_plus) begin // plus button functions
            
        end
    end
    

    clock u_clock ( 
        .clk(clk),
        .areset(),
        .tick_1Hz(tick_1Hz),
        .plus(),
        .set(),
        .pause_sec(pause_sec),
        .s_carry(s_carry),
        .state(c_state),
        .ss(time_ss),
        .mm(time_mm),
        .hh(time_hh)
    );

    stopwatch u_stopwatch (
        .clk(clk), 
        .areset(b_plus && (state == 2'b01)), 
        .tick(tick_1Hz),
        .set(b_set && (state == 2'b01)), 
        .ss(sw_ss), 
        .mm(sw_mm)
    );

    alarm_view u_alarm (
        .clk(clk),
        .areset(alarm_rst),
        .plus(plus),
        .set_state(set_state),
        .s_carry(s_carry),
        .mm(mm),
        .hh(hh),
        .trigger_alarm(trigger_alarm),
        .state(a_state),
        .alarm_mm(alarm_mm),
        .alarm_hh(alarm_hh)
    );
    
endmodule