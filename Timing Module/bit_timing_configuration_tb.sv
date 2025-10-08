`timescale 1ns/1ps

module bit_timing_configuration_tb;

    // DUT signals
    logic clock;
    logic reset_n;
    logic enable;
    logic tq_pulse;
    logic [3:0] prop_seg;
    logic [3:0] phase_seg1;
    logic [3:0] phase_seg2;

    logic [1:0] current_segment;
    logic [4:0] quanta_counter;
    logic [4:0] bit_quanta_counter;
    logic sample_point;
    logic bit_timing_end;
    logic sync_seg_active;
    logic prop_seg_active;
    logic phase_seg1_active;
    logic phase_seg2_active;
    logic [4:0] total_bit_tq;
    logic config_valid;

    // Instantiate DUT
    bit_timing_configuration dut (
        .clock(clock),
        .reset_n(reset_n),
        .enable(enable),
        .tq_pulse(tq_pulse),
        .prop_seg(prop_seg),
        .phase_seg1(phase_seg1),
        .phase_seg2(phase_seg2),
        .current_segment(current_segment),
        .quanta_counter(quanta_counter),
        .bit_quanta_counter(bit_quanta_counter),
        .sample_point(sample_point),
        .bit_timing_end(bit_timing_end),
        .sync_seg_active(sync_seg_active),
        .prop_seg_active(prop_seg_active),
        .phase_seg1_active(phase_seg1_active),
        .phase_seg2_active(phase_seg2_active),
        .total_bit_tq(total_bit_tq),
        .config_valid(config_valid)
    );

    // Clock generation (10ns period -> 100 MHz)
    always #5 clock = ~clock;

    // Task: Apply reset
    task apply_reset;
        begin
            reset_n = 0;
            enable = 0;
            tq_pulse = 0;
            #20;
            reset_n = 1;
        end
    endtask

    // Task: Generate a series of tq_pulses
    task gen_tq_pulses(input int count);
        begin
            repeat(count) begin
                tq_pulse = 1; #10; // one cycle high
                tq_pulse = 0; #10; // one cycle low
            end
        end
    endtask

    // Stimulus
    initial begin
        // Initialize
        clock = 0;
        reset_n = 1;
        enable = 0;
        tq_pulse = 0;
        prop_seg = 4'd2;
        phase_seg1 = 4'd2;
        phase_seg2 = 4'd2;

        // Apply reset
        apply_reset;

        // Case 1: Enable OFF -> nothing should progress
        $display("\n[CASE 1] Enable OFF -> no segment activity");
        gen_tq_pulses(10);

        // Case 2: Valid config, enable ON
        $display("\n[CASE 2] Enable ON, valid configuration");
        enable = 1;
        gen_tq_pulses(30); // should complete multiple segments

        // Case 3: Change timing parameters mid-operation
        $display("\n[CASE 3] Change configuration mid-run");
        prop_seg = 4'd3;
        phase_seg1 = 4'd4;
        phase_seg2 = 4'd5;
        gen_tq_pulses(50);

        // Case 4: Invalid config (too large)
        $display("\n[CASE 4] Invalid configuration (too large total_bit_tq)");
        prop_seg = 4'd8;
        phase_seg1 = 4'd8;
        phase_seg2 = 4'd8; // total = 25 -> valid
        gen_tq_pulses(20);

        prop_seg = 4'd9;   // invalid (not allowed)
        phase_seg1 = 4'd1;
        phase_seg2 = 4'd1;
        gen_tq_pulses(20);

        // Case 5: Disable mid-operation
        $display("\n[CASE 5] Disable mid-operation");
        prop_seg = 4'd2;
        phase_seg1 = 4'd2;
        phase_seg2 = 4'd2;
        enable = 1;
        gen_tq_pulses(15);
        enable = 0; // stop in middle
        gen_tq_pulses(10);

        // Case 6: Multiple cycles to observe sample_point + bit_timing_end
        $display("\n[CASE 6] Observe sample_point and bit_timing_end");
        enable = 1;
        prop_seg = 4'd3;
        phase_seg1 = 4'd2;
        phase_seg2 = 4'd4;
        gen_tq_pulses(80);

        $display("\n*** Simulation Complete ***");
        $stop;
    end

    // Monitor DUT behavior
    initial begin
        $monitor("t=%0t | seg=%0d qc=%0d bqc=%0d sp=%0b end=%0b valid=%0b | SYNC=%0b PROP=%0b PH1=%0b PH2=%0b",
                  $time, current_segment, quanta_counter, bit_quanta_counter,
                  sample_point, bit_timing_end, config_valid,
                  sync_seg_active, prop_seg_active, phase_seg1_active, phase_seg2_active);
    end

endmodule
