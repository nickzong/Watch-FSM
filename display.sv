module display (
    input logic clk,
    input logic[5:0] top_pair,
    input logic[5:0] bottom_pair,
    // 7seg disp: [a b c d e f g]
    // tens/ones: [6 5 4 3 2 1 0]
    output logic[6:0] top_tens_7sd,
    output logic[6:0] top_ones_7sd,
    output logic[6:0] bottom_tens_7sd,
    output logic[6:0] bottom_ones_7sd
);

    localparam logic[6:0] ZERO  = 7'b1111110;
    localparam logic[6:0] ONE   = 7'b0110000;
    localparam logic[6:0] TWO   = 7'b1101101;
    localparam logic[6:0] THREE = 7'b1111001;
    localparam logic[6:0] FOUR  = 7'b0110011;
    localparam logic[6:0] FIVE  = 7'b1011011;
    localparam logic[6:0] SIX   = 7'b1011111;
    localparam logic[6:0] SEVEN = 7'b1110000;
    localparam logic[6:0] EIGHT = 7'b1111111;
    localparam logic[6:0] NINE  = 7'b1110011;

    always_ff @(posedge clk) begin
        case (top_pair)
            6'd0: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = ZERO;
            end
            6'd1: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = ONE;
            end
            6'd2: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = TWO;
            end
            6'd3: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = THREE;
            end
            6'd4: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = FOUR;
            end
            6'd5: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = FIVE;
            end
            6'd6: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = SIX;
            end
            6'd7: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = SEVEN;
            end
            6'd8: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = EIGHT;
            end
            6'd9: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = NINE;
            end
            
            6'd10: begin
                top_tens_7sd = ONE;
                top_ones_7sd = ZERO;
            end
            6'd11: begin
                top_tens_7sd = ONE;
                top_ones_7sd = ONE;
            end
            6'd12: begin
                top_tens_7sd = ONE;
                top_ones_7sd = TWO;
            end
            6'd13: begin
                top_tens_7sd = ONE;
                top_ones_7sd = THREE;
            end
            6'd14: begin
                top_tens_7sd = ONE;
                top_ones_7sd = FOUR;
            end
            6'd15: begin
                top_tens_7sd = ONE;
                top_ones_7sd = FIVE;
            end
            6'd16: begin
                top_tens_7sd = ONE;
                top_ones_7sd = SIX;
            end
            6'd17: begin
                top_tens_7sd = ONE;
                top_ones_7sd = SEVEN;
            end
            6'd18: begin
                top_tens_7sd = ONE;
                top_ones_7sd = EIGHT;
            end
            6'd19: begin
                top_tens_7sd = ONE;
                top_ones_7sd = NINE;
            end

            6'd20: begin
                top_tens_7sd = TWO;
                top_ones_7sd = ZERO;
            end
            6'd21: begin
                top_tens_7sd = TWO;
                top_ones_7sd = ONE;
            end
            6'd22: begin
                top_tens_7sd = TWO;
                top_ones_7sd = TWO;
            end
            6'd23: begin
                top_tens_7sd = TWO;
                top_ones_7sd = THREE;
            end
            6'd24: begin
                top_tens_7sd = TWO;
                top_ones_7sd = FOUR;
            end
            6'd25: begin
                top_tens_7sd = TWO;
                top_ones_7sd = FIVE;
            end
            6'd26: begin
                top_tens_7sd = TWO;
                top_ones_7sd = SIX;
            end
            6'd27: begin
                top_tens_7sd = TWO;
                top_ones_7sd = SEVEN;
            end
            6'd28: begin
                top_tens_7sd = TWO;
                top_ones_7sd = EIGHT;
            end
            6'd29: begin
                top_tens_7sd = TWO;
                top_ones_7sd = NINE;
            end

            6'd30: begin
                top_tens_7sd = THREE;
                top_ones_7sd = ZERO;
            end
            6'd31: begin
                top_tens_7sd = THREE;
                top_ones_7sd = ONE;
            end
            6'd32: begin
                top_tens_7sd = THREE;
                top_ones_7sd = TWO;
            end
            6'd33: begin
                top_tens_7sd = THREE;
                top_ones_7sd = THREE;
            end
            6'd34: begin
                top_tens_7sd = THREE;
                top_ones_7sd = FOUR;
            end
            6'd35: begin
                top_tens_7sd = THREE;
                top_ones_7sd = FIVE;
            end
            6'd36: begin
                top_tens_7sd = THREE;
                top_ones_7sd = SIX;
            end
            6'd37: begin
                top_tens_7sd = THREE;
                top_ones_7sd = SEVEN;
            end
            6'd38: begin
                top_tens_7sd = THREE;
                top_ones_7sd = EIGHT;
            end
            6'd39: begin
                top_tens_7sd = THREE;
                top_ones_7sd = NINE;
            end

            6'd40: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = ZERO;
            end
            6'd41: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = ONE;
            end
            6'd24: begin
                top_tens_7sd = ZFOUR
                top_ones_7sd = TWO;
            end
            6'd43: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = THREE;
            end
            6'd44: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = FOUR;
            end
            6'd45: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = FIVE;
            end
            6'd46: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = SIX;
            end
            6'd47: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = SEVEN;
            end
            6'd48: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = EIGHT;
            end
            6'd49: begin
                top_tens_7sd = FOUR;
                top_ones_7sd = NINE;
            end

            6'd50: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = ZERO;
            end
            6'd51: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = ONE;
            end
            6'd52: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = TWO;
            end
            6'd53: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = THREE;
            end
            6'd54: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = FOUR;
            end
            6'd55: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = FIVE;
            end
            6'd56: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = SIX;
            end
            6'd57: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = SEVEN;
            end
            6'd58: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = EIGHT;
            end
            6'd59: begin
                top_tens_7sd = FIVE;
                top_ones_7sd = NINE;
            end

            6'b111111: begin // blink state
                top_tens_7sd = 7'b0000000;
                top_ones_7sd = 7'b0000000;
            end
            default: begin
                top_tens_7sd = ZERO;
                top_ones_7sd = ZERO;
            end
        endcase

        case (bottom_pair)
            6'd0: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = ZERO;
            end
            6'd1: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = ONE;
            end
            6'd2: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = TWO;
            end
            6'd3: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = THREE;
            end
            6'd4: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = FOUR;
            end
            6'd5: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = FIVE;
            end
            6'd6: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = SIX;
            end
            6'd7: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = SEVEN;
            end
            6'd8: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = EIGHT;
            end
            6'd9: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = NINE;
            end
            
            6'd10: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = ZERO;
            end
            6'd11: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = ONE;
            end
            6'd12: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = TWO;
            end
            6'd13: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = THREE;
            end
            6'd14: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = FOUR;
            end
            6'd15: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = FIVE;
            end
            6'd16: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = SIX;
            end
            6'd17: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = SEVEN;
            end
            6'd18: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = EIGHT;
            end
            6'd19: begin
                bottom_tens_7sd = ONE;
                bottom_ones_7sd = NINE;
            end

            6'd20: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = ZERO;
            end
            6'd21: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = ONE;
            end
            6'd22: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = TWO;
            end
            6'd23: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = THREE;
            end
            6'd24: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = FOUR;
            end
            6'd25: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = FIVE;
            end
            6'd26: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = SIX;
            end
            6'd27: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = SEVEN;
            end
            6'd28: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = EIGHT;
            end
            6'd29: begin
                bottom_tens_7sd = TWO;
                bottom_ones_7sd = NINE;
            end

            6'd30: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = ZERO;
            end
            6'd31: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = ONE;
            end
            6'd32: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = TWO;
            end
            6'd33: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = THREE;
            end
            6'd34: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = FOUR;
            end
            6'd35: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = FIVE;
            end
            6'd36: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = SIX;
            end
            6'd37: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = SEVEN;
            end
            6'd38: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = EIGHT;
            end
            6'd39: begin
                bottom_tens_7sd = THREE;
                bottom_ones_7sd = NINE;
            end

            6'd40: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = ZERO;
            end
            6'd41: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = ONE;
            end
            6'd24: begin
                bottom_tens_7sd = ZFOUR
                bottom_ones_7sd = TWO;
            end
            6'd43: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = THREE;
            end
            6'd44: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = FOUR;
            end
            6'd45: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = FIVE;
            end
            6'd46: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = SIX;
            end
            6'd47: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = SEVEN;
            end
            6'd48: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = EIGHT;
            end
            6'd49: begin
                bottom_tens_7sd = FOUR;
                bottom_ones_7sd = NINE;
            end

            6'd50: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = ZERO;
            end
            6'd51: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = ONE;
            end
            6'd52: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = TWO;
            end
            6'd53: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = THREE;
            end
            6'd54: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = FOUR;
            end
            6'd55: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = FIVE;
            end
            6'd56: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = SIX;
            end
            6'd57: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = SEVEN;
            end
            6'd58: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = EIGHT;
            end
            6'd59: begin
                bottom_tens_7sd = FIVE;
                bottom_ones_7sd = NINE;
            end

            6'b111111: begin // blink state
                bottom_tens_7sd = 7'b0000000;
                bottom_ones_7sd = 7'b0000000;
            end
            default: begin
                bottom_tens_7sd = ZERO;
                bottom_ones_7sd = ZERO;
            end
        endcase
    end

endmodule