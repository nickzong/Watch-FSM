module alarm_view ( // trigger ring when clock time (hh:mm:ss) == alarm time (hh:mm:00)
    input logic clk,
    input logic areset,
    input logic plus, // increments in set state
    input logic set_state, // 
    input logic s_carry, // 1 only on second rollover
    input logic[5:0] mm,
    input logic[4:0] hh

    output logic trigger_alarm,
    output logic[5:0] alarm_mm,
    output logic[4:0] alarm_hh
);

    logic armed = 0; // interal flag - if alarm is on/off
    logic[1:0] state = 2'b00; // cycles alarm_view (00) --> set_hr (01) --> set_min (10) --> confirm alarm (00)

    always_ff @(posedge set_state) begin
        if (state == 2'b00) begin
            state <= 2'b01;
            armed <= 1'b0;
        end else if (state == 2'b01) begin
            state <= 2'b10;
            armed <= 1'b0;
        end else if (state == 2'b10) begin
            state = 2'b00;
            armed = 1'b1;
        end else begin
            state = 2'b00;
        end
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

    assign trigger_alarm = s_carry && (mm == alarm_mm) && (hh == alarm_hh)
endmodule