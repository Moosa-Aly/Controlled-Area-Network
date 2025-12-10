`timescale 1ns/1ps

module hard_sync_tb;

    // DUT signals
    logic clock;
    logic reset_n;
    logic enable;
    logic signal_in;
    logic falling_edge;
    logic bus_idle;
    logic hard_sync_request;

    // Instantiate DUT
    hard_sync dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .signal_in(signal_in),
        .falling_edge(falling_edge),
        .bus_idle(bus_idle),
        .hard_sync_request(hard_sync_request)
    );

    // Clock generation
    initial clock = 0;
    always #5 clock = ~clock;   // 100 MHz clock (10 ns period)

    // Stimulus
    initial begin
        // Initial values
        reset_n = 0;
        enable = 0;
        signal_in = 1;
        falling_edge = 0;

        // Apply reset
        #20 reset_n = 1;
        enable = 1;

        // Case 1: Keep bus idle for >11 cycles
        repeat (12) begin
            @(posedge clock);
            signal_in = 1;   // recessive
            falling_edge = 0;
        end

        // Now bus_idle should be 1
        $display("Time %0t: Bus Idle = %0b", $time, bus_idle);

        // Case 2: Falling edge while bus is idle
        @(posedge clock);
        signal_in = 0;       // dominant
        falling_edge = 1;    // simulate edge detector pulse
        @(posedge clock);
        falling_edge = 0;

        $display("Time %0t: Hard Sync Request = %0b", $time, hard_sync_request);

        // Case 3: Noise (dominant before 11 cycles)
        repeat (5) begin
            @(posedge clock);
            signal_in = 1;
        end
        @(posedge clock);
        signal_in = 0;       // force dominant early
        falling_edge = 1;
        @(posedge clock);
        falling_edge = 0;

        $display("Time %0t: Bus Idle = %0b, Hard Sync Request = %0b",
                  $time, bus_idle, hard_sync_request);

        // Finish simulation
        #50;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("T=%0t | signal_in=%b, bus_idle=%b, hard_sync_request=%b",
                 $time, signal_in, bus_idle, hard_sync_request);
    end

endmodule
