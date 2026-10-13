// top.v - Nexys A7-100T + L298N + JGB37-520 DC motor
//  SW[7:0]  : speed (PWM duty, 0..255)
//  SW[15]   : enable  (1 = run, 0 = coast)
//  SW[14]   : direction (0 = forward, 1 = reverse)
//  SW[13]   : brake
//  BTNC     : reset
//  JA1 = ENA (PWM), JA2 = IN1, JA3 = IN2
module top (
    input  wire        CLK100MHZ,
    input  wire        BTNC,
    input  wire [15:0] SW,
    output wire        JA1,      // ENA
    output wire        JA2,      // IN1
    output wire        JA3,      // IN2
    output wire [15:0] LED
);
    wire rst = BTNC;
    wire pwm;
    wire ena, in1, in2;

    pwm_gen #(.PRESCALE(39)) u_pwm (
        .clk(CLK100MHZ), .rst(rst), .duty(SW[7:0]), .pwm_out(pwm)
    );

    motor_ctrl u_ctrl (
        .clk(CLK100MHZ), .rst(rst),
        .enable_i(SW[15]), .dir_i(SW[14]), .brake_i(SW[13]),
        .pwm_i(pwm),
        .ena(ena), .in1(in1), .in2(in2)
    );

    assign JA1 = ena;
    assign JA2 = in1;
    assign JA3 = in2;

    // LEDs: mirror switches + show driver outputs
    assign LED[7:0]   = SW[7:0];
    assign LED[12:8]  = 5'b0;
    assign LED[13]    = ena;
    assign LED[14]    = in1;
    assign LED[15]    = in2;
endmodule
