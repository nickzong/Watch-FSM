module mod_counter #(
  // STEPS should be 60 for mm/ss and 24 for hh, REG_SIZE = 6 for consistency
  parameter int STEPS = 60,
  parameter int REG_SIZE = 6
) (
  input logic clk,
  input logic areset,
  input logic inc, // signal to increment count
  output logic [REG_SIZE-1:0] out = 0,
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