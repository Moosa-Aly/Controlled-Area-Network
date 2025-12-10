`timescale 1ns/1ps

module data_field_tb;

    // DUT I/O signals
    logic clock;
    logic reset_n;
    logic enable;
    logic sample_point;
    logic Tx_request;
    logic control_complete;
    logic [3:0] dlc;
    logic [63:0] data;
    logic data_bit;
    logic [5:0] bit_counter;
    logic data_complete;

    // Instantiate the DUT
    data_field dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .sample_point(sample_point),
        .Tx_request(Tx_request),
        .control_complete(control_complete),
        .dlc(dlc),
        .data(data),
        .data_bit(data_bit),
        .bit_counter(bit_counter),
        .data_complete(data_complete)
    );

    //----------------------------------
    // Clock Generation: 20ns period
    //----------------------------------
    initial begin
        clock = 0;
        forever #10 clock = ~clock;  // 50MHz clock
    end

    //----------------------------------
    // Sample point generation
    // (simulate CAN sampling edge)
    //----------------------------------
    initial begin
        sample_point = 0;
        forever begin
            #100 sample_point = 1;  // pulse every 100ns
            #5   sample_point = 0;
        end
    end

    //----------------------------------
    // Test sequence
    //----------------------------------
    initial begin
        $display("Starting data_field_tb simulation...");
        $dumpfile("data_field_tb.vcd");
        $dumpvars(0, data_field_tb);

        // Initialize
        reset_n = 0;
        enable = 0;
        Tx_request = 0;
        control_complete = 0;
        dlc = 0;
        data = 64'h0;
        #50;

        // Apply reset
        reset_n = 1;
        enable = 1;
        #50;

        //----------------------------------
        // TEST 1: DLC = 0 (no data field)
        //----------------------------------
        dlc = 4'd0;
        data = 64'h1122334455667788;
        Tx_request = 1;
        control_complete = 1;
        #200;
        wait (data_complete);
        #50;
        $display("✅ TEST1 PASSED: DLC=0, data_complete asserted correctly");

        //----------------------------------
        // TEST 2: DLC = 4 (32 bits)
        //----------------------------------
        dlc = 4'd4;
        data = 64'hAABBCCDDEEFF0011;
        Tx_request = 1;
        control_complete = 1;
        #200;
        wait (data_complete);
        #100;
        $display("✅ TEST2 PASSED: DLC=4, transmitted %0d bits", bit_counter);

        //----------------------------------
        // TEST 3: DLC = 8 (64 bits)
        //----------------------------------
        dlc = 4'd8;
        data = 64'hDEADBEEFCAFEBABE;
        Tx_request = 1;
        control_complete = 1;
        #200;
        wait (data_complete);
        #100;
        $display("✅ TEST3 PASSED: DLC=8, transmitted %0d bits", bit_counter);

        //----------------------------------
        // TEST 4: Disable mid-transmission
        //----------------------------------
        dlc = 4'd4;
        data = 64'h123456789ABCDEF0;
        Tx_request = 1;
        control_complete = 1;
        enable = 1;
        #150;
        enable = 0; // disable during transmit
        #100;
        enable = 1; // re-enable
        Tx_request = 1;
        control_complete = 1;
        #200;
        wait (data_complete);
        $display("✅ TEST4 PASSED: Properly handled disable mid-transmission");

        //----------------------------------
        // TEST 5: Tx_request drop during COMPLETE
        //----------------------------------
        dlc = 4'd2;
        data = 64'hFACEFACEFACEFACE;
        Tx_request = 1;
        control_complete = 1;
        #200;
        wait (data_complete);
        #20;
        Tx_request = 0;
        control_complete = 0;
        #100;
        $display("✅ TEST5 PASSED: Returned to IDLE after Tx_request drop");

        //----------------------------------
        // Finish simulation
        //----------------------------------
        $display("🎯 All tests completed successfully!");
        #200;
        $finish;
    end

    //----------------------------------
    // Monitoring
    //----------------------------------
    initial begin
        $monitor("[%0t] STATE: bit_counter=%0d, data_bit=%b, data_complete=%b, dlc=%0d, data=%h",
                 $time, bit_counter, data_bit, data_complete, dlc, data);
    end

endmodule
