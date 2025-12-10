`timescale 1ns/1ps
module rtr_tb;

// -------------------- DUT Inputs --------------------
logic clock;
logic reset_n;
logic enable;
logic sample_point;
logic Tx_request;
logic id_complete;

// -------------------- DUT Outputs --------------------
logic rtr_bit;
logic rtr_complete;

// -------------------- Instantiate DUT --------------------
rtr dut (
    .clock(clock),
    .reset_n(reset_n),
    .enable(enable),
    .sample_point(sample_point),
    .Tx_request(Tx_request),
    .id_complete(id_complete),
    .rtr_bit(rtr_bit),
    .rtr_complete(rtr_complete)
);

// -------------------- Clock Generation --------------------
initial clock = 0;
always #5 clock = ~clock; // 100MHz clock (10ns period)

// -------------------- VCD Dump for Questa/ModelSim --------------------
initial begin
    $dumpfile("rtr_tb.vcd");
    $dumpvars(0, rtr_tb);
end

// -------------------- Monitor --------------------
initial begin
    $display("Time\tclk\trst\ten\tTx_req\tid_comp\tsample\t| rtr_bit\trtr_complete\tstate");
    $monitor("%0t\t%b\t%b\t%b\t%b\t%b\t%b\t| %b\t\t%b\t\t%s",
             $time, clock, reset_n, enable, Tx_request, id_complete, sample_point,
             rtr_bit, rtr_complete, state_name(dut.current_state));
end

// -------------------- Sample Point Generator --------------------
initial begin
    sample_point = 0;
    forever begin
        #17 sample_point = 1;
        #3  sample_point = 0;
    end
end

// -------------------- Test Stimulus --------------------
initial begin
    // Initialize
    reset_n = 0;
    enable = 0;
    Tx_request = 0;
    id_complete = 0;
    #20;

    // Release reset
    reset_n = 1;
    enable = 1;
    #20;

    // Test Case 1: Normal transmission
    $display("\n=== Test Case 1: Normal RTR Transmission ===");
    Tx_request = 1;
    id_complete = 1;
    #60;

    // Let sample_point trigger transmission
    #100;
    id_complete = 0;
    Tx_request = 0;
    #40;

    // Test Case 2: Disable during transmission
    $display("\n=== Test Case 2: Disable mid-transmission ===");
    Tx_request = 1;
    id_complete = 1;
    #40;
    enable = 0;  // disable DUT mid-transmission
    #40;
    enable = 1;  // re-enable
    Tx_request = 0;
    id_complete = 0;
    #40;

    // Test Case 3: Reset during active transmission
    $display("\n=== Test Case 3: Reset mid-transmission ===");
    Tx_request = 1;
    id_complete = 1;
    #30;
    reset_n = 0; // reset asserted
    #20;
    reset_n = 1; // release reset
    #50;

    $display("\n=== All test cases completed ===");
    #100;
    $finish;
end

// -------------------- State Name Function --------------------
function string state_name(input logic [1:0] state);
    case (state)
        2'b00: state_name = "IDLE";
        2'b01: state_name = "TRANSMIT";
        2'b11: state_name = "COMPLETE";
        default: state_name = "UNKNOWN";
    endcase
endfunction

endmodule