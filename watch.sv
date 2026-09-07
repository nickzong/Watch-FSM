// clk_rst, finish button, maybe put each hh, mm, ss as internal logic 
// and replace with two output logic regs called first_two and last_two. 
// add to the mode cycle an update of which two are being used to display currently
// add blinking when setting hr and min

// ADD ARESET CAPABILITIES TO OTHER MODULES
module watch (
    input logic clk,
    input logic tick_1Hz,
    input logic b_mode,
    input logic b_set,
    input logic b_plus,
    
    output logic[5:0] disp_pair1,
    output logic[5:0] disp_pair2
);

    logic[1:0] state, next_state;
    logic[1:0] c_state = 2'b00; // tracker for the current clock state
    logic[1:0] a_state = 2'b00; // tracker for the current alarm state

    // signals for watch mode instance inputs
    logic fact_rst; // when in time state, if all three buttons are pressed at once, factory reset everything
    logic trigger_alarm = 0;
    logic true_mode, true_set, true_plus;

    // internal registers used to store time for all three modes
    logic[5:0] time_ss = 0; 
    logic[5:0] time_mm = 0;
    logic[4:0] time_hh = 0;
    logic[5:0] sw_ss = 0;
    logic[5:0] sw_mm = 0;
    logic[5:0] alarm_mm = 0;
    logic[4:0] alarm_hh = 0;

    clock u_clock ( 
        .clk(clk),
        .areset(fact_rst),
        .tick_1Hz(tick_1Hz),
        .plus(true_plus && (state == 2'b00)),
        .set(true_set && (state == 2'b01)),
        .pause_sec(pause_sec),
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
    assign true_mode = !trigger_alarm & b_mode;
    assign true_set = !trigger_alarm & !b_mode & b_set;
    assign true_plus = !trigger_alarm & !b_mode & !b_set & b_plus;

    always_comb @(*) begin
        if (trigger_alarm) begin 
            next_state = 2'b11;
        end 
        // mode button and alarm silence functions
        // define mode cycle: time (00) --> stopwatch (01) --> alarm (10) --> time (00)
        case (state)
            2'b00: if (true_mode && c_state == 2'b00) next_state = 2'b01; // can only switch if idle
            2'b01: if (true_mode) next_state = 2'b10;
            2'b10: if (true_mode && a_state == 2'b00) next_state = 2'b00; // can only switch if idle
            2'b11: if (true_mode || true_set || true_plus) next_state = 2'b00; // silence alarm, alarm_ring state
            default: next_state = 2'b00;
        endcase
        
        //TODO add a combo logic block to control the display flow
        case (state)
            2'b00: begin
                disp_pair1 = time_hh;
                disp_pair2 = time_mm;
            end
            2'b01: begin
                disp_pair1 = sw_mm;
                disp_pair2 = sw_ss;
            end
            2'b10: begin
                disp_pair1 = alarm_hh;
                disp_pair2 = alarm_mm;
            end
            2'b11: begin
                disp_pair1 = time_hh;
                disp_pair2 = time_mm; // TODO fill in with actual alarm 
            end
            default:  begin
                disp_pair1 = time_hh;
                disp_pair2 = time_mm;
            end
        endcase
    end

    always_ff @(posedge clk, posedge fact_rst) begin
        if (fact_rst) state = 2'b00;
        else state = next_state;
    end
    
    assign fact_rst = true_mode & true_set & true_plus;
    
endmodule