// Debouncing module to finter noise from mode, set, and plus button inputs
module debouncer #(
    parameter int THRESHOLD = 200
) (
    input logic clk,
    input logic raw, // noisy input
    
    output logic clean = 0 // filtered 
);

    logic[$clog2(THRESHOLD)-1:0] count = 0;

    always_ff @(posedge clk) begin
        if (raw == clean) begin // no bounce occurs
            count <= 0;
        end
        else if (count == THRESHOLD) begin // long enough hold, not noisy anymore
            clean <= raw;
            count <= 0;
        end else begin
            count <= count + 1;
        end
    end
endmodule