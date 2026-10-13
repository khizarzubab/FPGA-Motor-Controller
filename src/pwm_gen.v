// pwm_gen.v - 8-bit PWM generator (~10 kHz from a 100 MHz clock)
// PWM freq = CLK / (PRESCALE * 256) = 100e6 / (39 * 256) = ~10.02 kHz
module pwm_gen #(
    parameter PRESCALE = 39
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] duty,     // 0 = always off, 255 = ~100% on
    output reg        pwm_out
);
    reg [5:0] pre_cnt = 0;
    reg [7:0] cnt     = 0;

    always @(posedge clk) begin
        if (rst) begin
            pre_cnt <= 0;
            cnt     <= 0;
            pwm_out <= 1'b0;
        end else begin
            if (pre_cnt == PRESCALE - 1) begin
                pre_cnt <= 0;
                cnt     <= cnt + 1'b1;
            end else begin
                pre_cnt <= pre_cnt + 1'b1;
            end
            pwm_out <= (cnt < duty);
        end
    end
endmodule
