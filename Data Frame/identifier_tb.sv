`timescale 1ns/1ps

module identifier_tb;

// ---------------------- DUT Inputs ----------------------
logic clock;
logic reset_n;
logic enable;
logic sample_point;
logic Tx_request;
logic sof_complete;
logic [10:0] identifier;

// ---------------------- DUT Outputs ---------------------
logic bit_id;
logic [3:0] bit_counter;
logic id_complete;

// ---------------------- Instantiate DUT -----------------
identifier uut (
    .clock(clock),
    .reset_n(reset_n),
    .enable(enable),
    .sample_point(sample_point),
    .Tx_request(Tx_request),
    .sof_complete(sof_complete),
    .identifier(identifier),
    .bit_id(bit_id),
    .bit_counter(bit_counter),
    .id_complete(id_complete)
);

// ---------------------- Clock Generation ----------------
initial begin
    clock = 0;
    forever #5 clock = ~clock; // 100 MHz clock
end

// ---------------------- Reset Task ----------------------
task reset_dut();
begin
    reset_n = 0;
    enable = 0;
    Tx_request = 0;
    sof_complete = 0;
    sample_point = 0;
    identifier = 11'b0;
    #20;
    reset_n = 1;
    enable = 1;
    #10;
end
endtask

// ---------------------- Sample Point Task ----------------
// Simulates bit timing in CAN — sample point pulses at bit boundaries
task send_sample_points(int num_bits);
    integer i;
    begin
        for (i = 0; i < num_bits; i++) begin
            sample_point = 1;
            #10;
            sample_point = 0;
            #30; // Adjust to simulate bit time spacing
        end
    end
endtask

// ---------------------- Test Stimulus --------------------
initial begin
    $display("---- Starting Identifier Module Simulation ----");
    $dumpfile("identifier_tb.vcd");
    $dumpvars(0, identifier_tb);

    reset_dut();

    // -------- TEST 1: Normal Transmission ------------
    $display("[%0t] TEST 1: Normal Transmission", $time);
    identifier = 11'b1010_1100_111;
    Tx_request = 1;
    sof_complete = 1;
    #10;

    // simulate sending bits one by one
    send_sample_points(11);
    #20;

    // Wait for COMPLETE
    wait (id_complete);
    $display("[%0t] ID Transmission Complete. bit_counter=%0d bit_id=%b", 
              $time, bit_counter, bit_id);
    #50;

    // -------- TEST 2: Invalid Identifier ------------
    $display("[%0t] TEST 2: Invalid ID (ID bits all 1s)", $time);
    Tx_request = 0;
    sof_complete = 0;
    #20;
    identifier = 11'b11111111111; // Invalid (id_valid = 0)
    Tx_request = 1;
    sof_complete = 1;
    #40;
    send_sample_points(11);
    #40;
    $display("[%0t] Invalid ID Test Complete. ID_complete=%b", $time, id_complete);
    #40;

    // -------- TEST 3: Disable Mid Transmission ------
    $display("[%0t] TEST 3: Disable during transmission", $time);
    reset_dut();
    identifier = 11'b0000_1110_101;
    Tx_request = 1;
    sof_complete = 1;
    #10;
    fork
        begin
            send_sample_points(5);
        end
        begin
            #50;
            enable = 0; // disable in the middle
            #20;
            enable = 1;
        end
    join
    #50;

    // -------- TEST 4: Multiple Frames ---------------
    $display("[%0t] TEST 4: Multiple consecutive frames", $time);
    reset_dut();
    repeat (3) begin
        identifier = $random;
        Tx_request = 1;
        sof_complete = 1;
        #10;
        send_sample_points(11);
        wait (id_complete);
        #20;
        Tx_request = 0;
        sof_complete = 0;
        #30;
    end

    $display("[%0t] All tests completed.", $time);
    #100;
    $finish;
end

// ---------------------- Monitoring -----------------------
always @(posedge clock) begin
    $strobe("[%0t] STATE UPDATE: bit_id=%b bit_counter=%0d id_complete=%b",
             $time, bit_id, bit_counter, id_complete);
end

endmodule
