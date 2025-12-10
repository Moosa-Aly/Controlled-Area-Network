`timescale 1ns/1ps
module edge_detector_tb;
    logic clock;
    logic reset_n;
    logic signal_in;
    logic edge_detected;
    logic rising_edge;
    logic falling_edge;

    edge_detector dut (
        .clock(clock),
        .reset_n(reset_n),
        .signal_in(signal_in),
        .edge_detected(edge_detected),
        .rising_edge(rising_edge),
        .falling_edge(falling_edge)
    );

    initial clock = 0;
    always #5 clock = ~clock;

    initial begin
        reset_n   = 0;
        signal_in = 1;   // start high because your reset defaults signals to '1'
        #12 reset_n = 1;

        // Stay high for a while
        #20;

        // Falling edge
        signal_in = 0;
        #20;

        // Rising edge
        signal_in = 1;
        #20;

        // Another falling edge
        signal_in = 0;
        #20;

        // Another rising edge
        signal_in = 1;
        #20;

        // Finish simulation
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | signal_in=%b | edge_detected=%b | rising_edge=%b | falling_edge=%b",
                  $time, signal_in, edge_detected, rising_edge, falling_edge);
    end
endmodule
