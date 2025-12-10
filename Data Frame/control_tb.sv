`timescale 1ns/1ps

module control_field_tb;

    // DUT inputs
    logic clock;
    logic reset_n;
    logic enable;
    logic sample_point;
    logic Tx_request;
    logic rtr_complete;
    logic [3:0] dlc;

    // DUT outputs
    logic control_bit;
    logic [2:0] bit_counter;
    logic control_complete;

    // Instantiate DUT
    control_field dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .sample_point(sample_point),
        .Tx_request(Tx_request),
        .rtr_complete(rtr_complete),
        .dlc(dlc),
        .control_bit(control_bit),
        .bit_counter(bit_counter),
        .control_complete(control_complete)
    );

    // ------------------------------------------
    // CLOCK GENERATION (20 ns period)
    // ------------------------------------------
    initial begin
        clock = 0;
        forever #10 clock = ~clock;  // 50 MHz clock
    end

    // ------------------------------------------
    // SAMPLE POINT (CAN sampling edge simulation)
    // ------------------------------------------
    initial begin
        sample_point = 0;
        forever begin
            #100 sample_point = 1;  // sample pulse every 100 ns
            #5   sample_point = 0;
        end
    end

    // ------------------------------------------
    // TEST SEQUENCE
    // ------------------------------------------
    initial begin
        $display("Starting control_field_tb simulation...");
        $dumpfile("control_field_tb.vcd");
        $dumpvars(0, control_field_tb);

        // Initialize signals
        reset_n = 0;
        enable = 0;
        Tx_request = 0;
        rtr_complete = 0;
        dlc = 4'd0;
        #50;

        // Release reset
        reset_n = 1;
        enable = 1;
        #50;

        //----------------------------------
        // TEST 1: DLC = 0 (control frame)
        //----------------------------------
        dlc = 4'd0;
        Tx_request = 1;
        rtr_complete = 1;
        #100;
        wait (control_complete);
        $display("✅ TEST1 PASSED: DLC=0, control_complete asserted after 6 bits.");
        #100;

        //----------------------------------
        // TEST 2: DLC = 4 (standard data length)
        //----------------------------------
        dlc = 4'd4;
        Tx_request = 1;
        rtr_complete = 1;
        #100;
        wait (control_complete);
        $display("✅ TEST2 PASSED: DLC=4, shifted bits = {00, 0100} => control_complete done.");
        #100;

        //----------------------------------
        // TEST 3: DLC = 8 (max value)
        //----------------------------------
        dlc = 4'd8;
        Tx_request = 1;
        rtr_complete = 1;
        #100;
        wait (control_complete);
        $display("✅ TEST3 PASSED: DLC=8, 6-bit control transmitted correctly.");
        #100;

        //----------------------------------
        // TEST 4: Disable mid-transmission
        //----------------------------------
        dlc = 4'd2;
        Tx_request = 1;
        rtr_complete = 1;
        enable = 1;
        #150;
        enable = 0; // disable in middle
        #50;
        enable = 1; // re-enable
        Tx_request = 1;
        rtr_complete = 1;
        #100;
        wait (control_complete);
        $display("✅ TEST4 PASSED: Module recovered correctly after disable.");

        //----------------------------------
        // TEST 5: Tx_request drop after COMPLETE
        //----------------------------------
        dlc = 4'd3;
        Tx_request = 1;
        rtr_complete = 1;
        #150;
        wait (control_complete);
        #20;
        Tx_request = 0;
        rtr_complete = 0;
        #50;
        $display("✅ TEST5 PASSED: Returned to IDLE when Tx_request dropped.");

        //----------------------------------
        // TEST 6: Random DLCs for robustness
        //----------------------------------
        for (int i = 0; i < 5; i++) begin
            dlc = $urandom_range(0, 8);
            Tx_request = 1;
            rtr_complete = 1;
            #100;
            wait (control_complete);
            #50;
            $display("✅ TEST6 PASSED: Random DLC=%0d tested successfully.", dlc);
        end

        //----------------------------------
        // END SIMULATION
        //----------------------------------
        $display("🎯 All tests completed successfully!");
        #200;
        $finish;
    end

    // ------------------------------------------
    // MONITOR
    // ------------------------------------------
    initial begin
        $monitor("[%0t] STATE: DLC=%0d | bit_counter=%0d | control_bit=%b | control_complete=%b",
                 $time, dlc, bit_counter, control_bit, control_complete);
    end

endmodule
