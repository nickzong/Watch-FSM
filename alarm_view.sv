module alarm_view ( // trigger ring when clock time (hh:mm:ss) == alarm time (hh:mm:00)
    input logic clk,
    input logic areset,
    input logic plus, // increments in set state
    input logic set_state, // set button
    input logic s_carry, // 1 only on second rollover
    input logic[5:0] mm,
    input logic[5:0] hh,

    output logic trigger_alarm,
    output logic[1:0] state = 2'b00, // cycles alarm_view (00) --> set_hr (01) --> set_min (10) --> confirm alarm (00)
    output logic[5:0] alarm_mm,
    output logic[5:0] alarm_hh
);

    logic armed = 0; // interal flag - if alarm is on/off

    always_ff @(posedge set_state) begin
        case (state)
            2'b00: state <= 2'b01;    // alarm_view --> set_hr
            2'b01: state <= 2'b10;    // set_hr --> set_min
            2'b10: state <= 2'b00;    // set_min --> alarm_view
            default: state <= 2'b00;
        endcase
    end

    // alarm toggle
    always_ff @(posedge plus) begin
        if (state == 2'b00) armed <= ~armed;
    end

    always_ff @(posedge areset) begin
        state <= 2'b00;
        armed <= 0;
    end

    time_keeper u_alarm (
        .clk(clk), 
        .areset(areset), 
        .tick_1Hz(),
        .inc_min_pulse(state == 2'b10 && plus), 
        .inc_hr_pulse(state == 2'b01 && plus), 
        .pause_sec(),
        .ss(), .mm(alarm_mm), .hh(alarm_hh),
        .s_carry()
    );
    
    assign trigger_alarm = armed && s_carry && (mm == alarm_mm) && (hh == alarm_hh);

endmodule