`timescale 1ns/1ps

module tb_phase_error;

  // Testbench signals
  logic clock;
  logic reset_n;
  logic enable;
  logic edge_detected;
  logic falling_edge;
  logic hard_sync_request;
  logic [3:0] resync_jump_width;
  logic [1:0] current_segment;
  logic [4:0] quanta_counter;
  logic [3:0] phase_segment_2;

  // DUT outputs
  logic [3:0] phase_error;
  logic       resync_required;
  logic [3:0] resync_adjustment;
  logic       resync_direction;

  // Instantiate DUT
  phase_error dut (
    .clock(clock),
    .reset_n(reset_n),
    .enable(enable),
    .edge_detected(edge_detected),
    .falling_edge(falling_edge),
    .hard_sync_request(hard_sync_request),
    .resync_jump_width(resync_jump_width),
    .current_segment(current_segment),
    .quanta_counter(quanta_counter),
    .phase_segment_2(phase_segment_2),
    .phase_error(phase_error),
    .resync_required(resync_required),
    .resync_adjustment(resync_adjustment),
    .resync_direction(resync_direction)
  );

  // Clock generation
  always #5 clock = ~clock; // 100 MHz

  // Task to drive segments with proper quanta_counter
  task automatic run_segment(input [1:0] seg_type, input int max_quanta);
    begin
      current_segment = seg_type;
      for (int i = 1; i <= max_quanta; i++) begin
        quanta_counter = i;
        @(posedge clock);
      end
    end
  endtask

  // Stimulus
  initial begin
    // Initialize
    clock             = 0;
    reset_n           = 0;
    enable            = 0;
    edge_detected     = 0;
    falling_edge      = 0;
    hard_sync_request = 0;
    resync_jump_width = 4'd4;
    current_segment   = 2'b00;
    quanta_counter    = 5'd0;
    phase_segment_2   = 4'd8; // fixed value for late error calc

    // Reset
    $display("[%0t] Applying reset",$time);
    #20 reset_n = 1;
    enable  = 1;

    // -------------------------
    // SYNC_SEG (1 Tq)
    // -------------------------
    $display("[%0t] Running SYNC_SEG",$time);
    run_segment(2'b00, 1);

    // -------------------------
    // PROP_SEG (8 Tq) + inject early edge
    // -------------------------
    $display("[%0t] Running PROP_SEG with early edge",$time);
    fork
      begin
        run_segment(2'b01, 8);
      end
      begin
        // inject edge at quanta=3
        @(posedge clock); // quanta=1
        @(posedge clock); // quanta=2
        edge_detected = 1; falling_edge = 1;
        @(posedge clock); // quanta=3
        edge_detected = 0; falling_edge = 0;
      end
    join

    // -------------------------
    // PHASE_SEG1 (8 Tq) + inject early edge
    // -------------------------
    $display("[%0t] Running PHASE_SEG1 with early edge",$time);
    fork
      begin
        run_segment(2'b10, 8);
      end
      begin
        // inject edge at quanta=7
        repeat(6) @(posedge clock);
        edge_detected = 1; falling_edge = 1;
        @(posedge clock); // quanta=7
        edge_detected = 0; falling_edge = 0;
      end
    join

    // -------------------------
    // PHASE_SEG2 (8 Tq) + inject late edge
    // -------------------------
    $display("[%0t] Running PHASE_SEG2 with late edge",$time);
    fork
      begin
        run_segment(2'b11, 8);
      end
      begin
        // inject edge at quanta=5
        repeat(4) @(posedge clock);
        edge_detected = 1; falling_edge = 1;
        @(posedge clock); // quanta=5
        edge_detected = 0; falling_edge = 0;
      end
    join

    // -------------------------
    // End simulation
    // -------------------------
    #50;
    $finish;
  end

  // Monitor outputs
  initial begin
    $monitor("[%0t] seg=%b qc=%0d ps2=%0d | phase_error=%0d resync_adj=%0d req=%b dir=%b",
              $time, current_segment, quanta_counter, phase_segment_2,
              phase_error, resync_adjustment, resync_required, resync_direction);
  end

endmodule

