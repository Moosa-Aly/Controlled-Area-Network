`timescale 1ns/1ps

module sof_tb;

    // DUT inputs
    logic clock;
    logic reset_n;
    logic enable;
    logic Tx_request;
    logic bus_idle;
    logic apply_hard_sync;
    logic sample_point;

    // DUT outputs
    logic sof_bit;
    logic sof_complete;
    logic sof_transmitting;

    // Instantiate DUT
    sof uut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .Tx_request(Tx_request),
        .bus_idle(bus_idle),
        .apply_hard_sync(apply_hard_sync),
        .sample_point(sample_point),
        .sof_bit(sof_bit),
        .sof_complete(sof_complete),
        .sof_transmitting(sof_transmitting)
    );

    //------------------------------------------------------------
    // Clock Generation
    //------------------------------------------------------------
    initial begin
        clock = 0;
        forever #5 clock = ~clock; // 100 MHz clock
    end

    //------------------------------------------------------------
    // Task Definitions
    //------------------------------------------------------------

    // Reset Task
    task apply_reset();
        begin
            reset_n = 0;
            #20;
            reset_n = 1;
            $display("[%0t] RESET APPLIED ✅", $time);
        end
    endtask

    // SOF Transmission Task
    task start_sof_cycle();
        begin
            bus_idle = 1;
            Tx_request = 1;
            #20;
            apply_hard_sync = 1;
            #10;
            apply_hard_sync = 0;
            #30;
            sample_point = 1;
            #10;
            sample_point = 0;
            #30;
            Tx_request = 0;
            bus_idle = 0;
            #30;
        end
    endtask

    // Quick Tx Request pulse task
    task tx_request_pulse();
        begin
            Tx_request = 1;
            bus_idle = 1;
            #10;
            Tx_request = 0;
            #20;
        end
    endtask

    //------------------------------------------------------------
    // Main Stimulus
    //------------------------------------------------------------
    initial begin
        // Initialize
        reset_n = 0;
        enable = 0;
        Tx_request = 0;
        bus_idle = 0;
        apply_hard_sync = 0;
        sample_point = 0;

        // Apply reset and enable
        apply_reset();
        enable = 1;
        #10;

        // Test 1: Normal SOF Transmission
        $display("\n[TEST 1] Normal SOF Transmission");
        start_sof_cycle();
        check_outputs(1);

        // Test 2: Disable during transmission
        $display("\n[TEST 2] Disable during SEND_SOF");
        bus_idle = 1;
        Tx_request = 1;
        apply_hard_sync = 1;
        #10;
        apply_hard_sync = 0;
        #10;
        enable = 0; // disable mid-transmission
        #20;
        enable = 1;
        Tx_request = 0;
        bus_idle = 0;
        #40;
        check_outputs(2);

        // Test 3: Reset mid-transmission
        $display("\n[TEST 3] Reset during WAIT_SYNC");
        bus_idle = 1;
        Tx_request = 1;
        #10;
        apply_reset(); // reset while waiting
        #30;
        Tx_request = 0;
        bus_idle = 0;
        check_outputs(3);

        // Test 4: Quick Tx_request pulse (should not send SOF)
        $display("\n[TEST 4] Quick Tx_request pulse (edge case)");
        tx_request_pulse();
        check_outputs(4);

        // Test 5: Multiple consecutive SOFs
        $display("\n[TEST 5] Multiple SOF cycles");
        repeat (3) start_sof_cycle();
        check_outputs(5);

        $display("\n--- ALL TESTS COMPLETED ---");
        #50;
        $finish;
    end

    //------------------------------------------------------------
    // Output Checker
    //------------------------------------------------------------
    task check_outputs(input int test_num);
        begin
            if (sof_complete === 1'b1 && sof_bit === 1'b1)
                $display("[%0t] TEST %0d ✅ PASS: SOF completed correctly", $time, test_num);
            else
                $display("[%0t] TEST %0d ❌ FAIL: Unexpected SOF output", $time, test_num);
        end
    endtask

    //------------------------------------------------------------
    // Monitor
    //------------------------------------------------------------
    initial begin
        $display("\n------------------- SIGNAL MONITOR -------------------");
        $monitor("[%0t] | sof_bit=%b sof_complete=%b sof_transmitting=%b | Tx_request=%b bus_idle=%b apply_hard_sync=%b sample_point=%b enable=%b reset_n=%b",
                 $time, sof_bit, sof_complete, sof_transmitting,
                 Tx_request, bus_idle, apply_hard_sync, sample_point, enable, reset_n);
    end

endmodule

