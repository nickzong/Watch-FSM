module clock (
    input logic clk,
    input logic areset,
    input logic tick_1Hz,
    input logic plus,
    input logic set,
    
    output logic s_carry,
    output logic[1:0] state = 2'b00, // cycles time (00) --> set_hr (01) --> set_min (10) --> confirm time (00)
    output logic[5:0] ss,
    output logic[5:0] mm,
    output logic[4:0] hh
);

    always_ff @(posedge set) begin
        case (state)
            2'b00: state <= 2'b01;    // time --> set_hr
            2'b01: state <= 2'b10;    // set_hr --> set_min
            2'b10: state <= 2'b00;    // set_min --> time
            default: state <= 2'b00;
        endcase
    end

    always_ff @(posedge areset) begin
        state <= 2'b00;
    end

    time_keeper u_time (
        .clk(clk), 
        .areset(areset), 
        .tick_1Hz(tick_1Hz),
        .inc_min_pulse(state == 2'b10 && plus), 
        .inc_hr_pulse(state == 2'b01 && plus), 
        .pause_sec(state != 2'b00),
        .ss(ss), .mm(mm), .hh(hh),
        .s_carry(s_carry)
    );

endmodule