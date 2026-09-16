module stopwatch (
    input logic clk,
    input logic areset, // plus button acts as areset in this mode
    input logic tick, // assumed to be a 1Hz signal
    input logic set, // handles start/stop 

    output logic[5:0] ss,
    output logic[5:0] mm
);

    logic running = 0;
    logic clear_timer = 0; // decided once per areset press, sampled BEFORE running clears
    logic areset_prev = 0; // so a held/multi-cycle areset only latches once, on its rising edge

    always_ff @(posedge clk, posedge areset) begin
        if (areset) begin
            if (!areset_prev) begin
                clear_timer <= !running;
                running     <= 1'b0;
            end
            areset_prev <= 1'b1;
        end else begin
            areset_prev <= 1'b0;
            if (set) begin
                clear_timer <= 1'b0;
                running     <= ~running;
            end
        end
    end

    time_keeper u_timer (
        .clk(clk), 
        .areset(clear_timer), 
        .tick_1Hz(tick),
        .inc_min_pulse(), 
        .inc_hr_pulse(), 
        .pause_sec(!running),
        .ss(ss), .mm(mm), .hh(),
        .s_carry()
    );
endmodule