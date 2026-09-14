module blink_signal (
    input logic clk,
    output logic blink_en = 0
);

    always_ff @(posedge clk, negedge clk) begin
        blink_en <= ~blink_en;
    end
endmodule