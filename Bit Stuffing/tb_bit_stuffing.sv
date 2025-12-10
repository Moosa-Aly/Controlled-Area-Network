`timescale 1ns/1ps

module tb_bit_stuffing;

    // -----------------------------
    // DUT signals
    // -----------------------------
    logic clock;
    logic reset_n;
    logic enable;
    logic sample_point;

    logic sof_transmitting;
    logic sof_bit;

    logic id_complete;
    logic bit_id;

    logic rtr_complete;
    logic rtr_bit;

    logic control_complete;
    logic control_bit;

    logic data_complete;
    logic data_bit;

    logic crc_complete;
    logic crc_bit;
    logic [3:0] crc_bit_counter;

    logic eof_complete;

    logic stuffed_bit;
    logic stuff_bit_inserted;
    logic [2:0] consecutive_count;
    logic stuffing_active;

    // -----------------------------
    // DUT instantiation
    // -----------------------------
    bit_stuffing dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .sample_point(sample_point),
        .sof_transmitting(sof_transmitting),
        .sof_bit(sof_bit),
        .id_complete(id_complete),
        .bit_id(bit_id),
        .rtr_complete(rtr_complete),
        .rtr_bit(rtr_bit),
        .control_complete(control_complete),
        .control_bit(control_bit),
        .data_complete(data_complete),
        .data_bit(data_bit),
        .crc_complete(crc_complete),
        .crc_bit(crc_bit),
        .crc_bit_counter(crc_bit_counter),
        .eof_complete(eof_complete),
        .stuffed_bit(stuffed_bit),
        .stuff_bit_inserted(stuff_bit_inserted),
        .consecutive_count(consecutive_count),
        .stuffing_active(stuffing_active)
    );

    // -----------------------------
    // Clock
    // -----------------------------
    initial clock = 0;
    always #5 clock = ~clock; // 100 MHz

    // -----------------------------
    // Tasks
    // -----------------------------

    task apply_reset();
        begin
            reset_n = 0;
            enable  = 0;
            sof_transmitting = 0;
            id_complete     = 1;
            rtr_complete    = 1;
            control_complete = 1;
            data_complete   = 1;
            crc_complete    = 1;
            eof_complete    = 0;
            sample_point = 0;
            crc_bit_counter = 0;

            #50;
            reset_n = 1;
            enable  = 1;
            #20;
        end
    endtask

    task tick();
        begin
            sample_point = 1;
            #10;
            sample_point = 0;
            #10;
        end
    endtask

    task send_bit(input string seg, input logic b);
        begin
            case (seg)
                "SOF": begin
                    sof_transmitting = 1;
                    sof_bit = b;
                end

                "ID": begin
                    sof_transmitting = 0;
                    id_complete = 0;
                    bit_id = b;
                end

                "RTR": begin
                    id_complete = 1;
                    rtr_complete = 0;
                    rtr_bit = b;
                end

                "CONTROL": begin
                    rtr_complete = 1;
                    control_complete = 0;
                    control_bit = b;
                end

                "DATA": begin
                    control_complete = 1;
                    data_complete = 0;
                    data_bit = b;
                end

                "CRC": begin
                    data_complete = 1;
                    crc_complete = 0;
                    crc_bit = b;
                end
            endcase

            tick();
        end
    endtask

    // Automatic CRC section counter
    task send_crc_bit(input logic b);
        begin
            crc_bit = b;
            tick();
            crc_bit_counter++;
        end
    endtask

    // -----------------------------
    // Checking: assertion for correct stuffing
    // -----------------------------
    logic last_bit;
    int cc = 1;

    always @(posedge clock) begin
        if (reset_n && stuffing_active && sample_point && !stuff_bit_inserted) begin
            if (stuffed_bit == last_bit)
                cc++;
            else
                cc = 1;

            if (cc > 5)
                $error("ERROR: More than 5 consecutive bits detected, stuffing failed!");

            last_bit = stuffed_bit;
        end
    end

    // -----------------------------
    // Test sequence
    // -----------------------------
    initial begin
        $display("\n======== BIT STUFFING TEST STARTED ========\n");
        apply_reset();

        // -----------------------------
        // TEST 1: SOF & stuffing check
        // -----------------------------
        $display("TEST 1: SOF bit pattern with stuffing");
        send_bit("SOF", 1);
        send_bit("SOF", 1);
        send_bit("SOF", 1);
        send_bit("SOF", 1);
        send_bit("SOF", 1);
        send_bit("SOF", 1); // Should insert 0 here

        // -----------------------------
        // TEST 2: ID field random pattern
        // -----------------------------
        $display("TEST 2: ID random bits");
        repeat (10) send_bit("ID", $urandom_range(0,1));

        id_complete = 1;

        // -----------------------------
        // TEST 3: DATA with a forced 6-same sequence
        // -----------------------------
        $display("TEST 3: Data bits with forced 0 stuffing");
        repeat (5) send_bit("DATA", 0);
        send_bit("DATA", 0); // Should stuff

        data_complete = 1;

        // -----------------------------
        // TEST 4: CRC bits
        // -----------------------------
        $display("TEST 4: CRC section");
        crc_bit_counter = 0;
        repeat (15) send_crc_bit($urandom_range(0,1));

        crc_complete = 1;

        // -----------------------------
        // TEST 5: EOF
        // -----------------------------
        $display("TEST 5: EOF");
        eof_complete = 1;
        tick();

        $display("\n======== TEST COMPLETED =========\n");
        #50 $finish;
    end

    // Dump VCD for Questa waveform
    initial begin
        $dumpfile("bit_stuffing_tb.vcd");
        $dumpvars(0, tb_bit_stuffing);
    end

endmodule
