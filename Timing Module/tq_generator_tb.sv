`timescale 1ns/1ps

module tq_generator_tb;
    logic clock;
    logic reset_n;
    logic enable;
    logic [4:0] prescaler;
    logic tq_pulse;

    tq_generator dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .prescaler(prescaler),
        .tq_pulse(tq_pulse)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    initial begin
        
        reset_n   = 0;
        enable    = 0;
        prescaler = 5'd0;

        #12 reset_n = 1;

        #5 enable    = 1;
        prescaler = 5'd5;

        #100;

        $finish;
    end

endmodule
