module time_keeper (
  input logic clk,
  input logic areset,
  input logic tick_1Hz,
  
  // Button inputs signals
  input logic inc_min_pulse,
  input logic inc_hr_pulse,
  input logic pause_sec, // 1 when setting time 
  
  output logic[5:0] ss,
  output logic[5:0] mm,
  output logic[4:0] hh
);
  
  logic s_carry, m_carry, h_carry;
  
  mod_counter #(.STEPS(60), .REG_SIZE(6)) u_sec (
    .clk(clk),
    .areset(areset),
    .inc(!pause_sec && tick_1Hz),
    .out(ss),
    .carry(s_carry)
  );
  mod_counter #(.STEPS(60), .REG_SIZE(6)) u_min (
    .clk(clk),
    .areset(areset),
    .inc(s_carry || inc_min_pulse),
    .out(mm),
    .carry(m_carry)
  );
  mod_counter #(.STEPS(24), .REG_SIZE(5)) u_hr (
    .clk(clk),
    .areset(areset),
    .inc(m_carry || inc_hr_pulse),
    .out(hh),
    .carry(h_carry)
  );
  
endmodule
