// After recieving trigger_alarm signal, output a buzzer signal continuously until any buttons are pressed to disarm the alarm
module alarm_ring (
    input logic trigger_alarm,
    input logic button_input, // blanket signal for all three buttons

    output logic buzz = 0
);

    always_ff @(posedge trigger_alarm, posedge button_input) begin
        if (!button_input) buzz = 1;
        else  buzz = 0;
    end
endmodule