// motor_ctrl.v - L298N control logic
//  - synchronizes the asynchronous switch inputs
//  - protects the H-bridge: on a direction change the motor is stopped
//    for ~84 ms (2^23 clocks) before the new direction is applied
//  - modes: enable=0 -> coast, brake=1 -> fast brake, else run with PWM
module motor_ctrl (
    input  wire       clk,
    input  wire       rst,
    input  wire       enable_i,
    input  wire       dir_i,
    input  wire       brake_i,
    input  wire       pwm_i,
    output reg        ena,      // -> L298N ENA (PWM)
    output reg        in1,      // -> L298N IN1
    output reg        in2       // -> L298N IN2
);
    // 2-FF synchronizers
    reg [1:0] en_s = 0, dir_s = 0, brk_s = 0;
    always @(posedge clk) begin
        en_s  <= {en_s[0],  enable_i};
        dir_s <= {dir_s[0], dir_i};
        brk_s <= {brk_s[0], brake_i};
    end
    wire en  = en_s[1];
    wire dir = dir_s[1];
    wire brk = brk_s[1];

    // direction-change guard
    reg        dir_applied = 0;
    reg [22:0] guard_cnt   = 0;
    wire       guarding    = (guard_cnt != 0);

    always @(posedge clk) begin
        if (rst) begin
            dir_applied <= dir;
            guard_cnt   <= 0;
        end else if (guarding) begin
            guard_cnt <= guard_cnt - 1'b1;
            if (guard_cnt == 1) dir_applied <= dir;
        end else if (dir != dir_applied) begin
            guard_cnt <= {23{1'b1}};
        end
    end

    always @(posedge clk) begin
        if (rst || !en) begin            // coast / stopped
            ena <= 1'b0; in1 <= 1'b0; in2 <= 1'b0;
        end else if (brk) begin          // fast brake: both inputs equal, ENA high
            ena <= 1'b1; in1 <= 1'b1; in2 <= 1'b1;
        end else if (guarding) begin     // direction change in progress
            ena <= 1'b0; in1 <= 1'b0; in2 <= 1'b0;
        end else begin                   // run
            ena <= pwm_i;
            in1 <= dir_applied;
            in2 <= ~dir_applied;
        end
    end
endmodule
