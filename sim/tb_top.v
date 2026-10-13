`timescale 1ns/1ps
// Simulation testbench. Guard timer is long (2^23 clk ~ 84 ms), so sim runs ~300 ms.
module tb_top;
    reg         clk = 0;
    reg         btn = 0;
    reg  [15:0] sw  = 0;
    wire        ena, in1, in2;
    wire [15:0] led;

    top dut (.CLK100MHZ(clk), .BTNC(btn), .SW(sw),
             .JA1(ena), .JA2(in1), .JA3(in2), .LED(led));

    always #5 clk = ~clk;   // 100 MHz

    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
        btn = 1; #100; btn = 0;

        sw[15] = 1; sw[14] = 0; sw[7:0] = 8'd64;     // forward, 25 %
        #5_000_000;
        sw[7:0] = 8'd128;                            // 50 %
        #5_000_000;
        sw[7:0] = 8'd255;                            // ~100 %
        #5_000_000;
        sw[14] = 1;                                  // reverse (guard period)
        #150_000_000;
        sw[13] = 1;                                  // brake
        #5_000_000;
        sw[13] = 0; sw[15] = 0;                      // coast
        #5_000_000;
        $finish;
    end
endmodule
