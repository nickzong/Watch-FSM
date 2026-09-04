module mod_counter #(
  // STEPS should always be less than or equal to REG_SIZE
  // MIN or SEC: STEPS = 60, REG_SIZE = 6
  // HR: STEP = 24, REG_SIZE = 5
  parameter int STEPS = 60,
  parameter int REG_SIZE = 6
) (
  input logic clk,
  input logic areset,
  input logic inc, // signal to increment count
  output logic [REG_SIZE:0] out = 0,
  output logic carry // logic high when wrap around happens
); 
  
  always @(*) begin
    carry = (out == STEPS-1 && inc);
  end

  always @(posedge clk, posedge areset) begin
    if (areset) begin
      out <= 0;
    end else if (inc && out == STEPS-1) begin
      out <= 0;
    end else if (inc) begin
      out <= out + 1;
    end
  end
  
endmodule
