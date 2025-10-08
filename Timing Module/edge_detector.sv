module edge_detector (
    input  logic clock,
    input  logic reset_n,
    input  logic signal_in,
    output logic edge_detected,
    output logic rising_edge,
    output logic falling_edge
);
logic signal_sync, signal_prev;
always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        signal_sync     <= 1'b1;
        signal_prev     <= 1'b1;
        edge_detected   <= 1'b0;
        rising_edge     <= 1'b0;
        falling_edge    <= 1'b0;
    end
    else begin
        signal_sync     <= signal_in;
        signal_prev     <= signal_sync;
        edge_detected   <= (signal_sync != signal_prev);
        rising_edge     <= (!signal_prev && signal_sync);
        falling_edge    <= (signal_prev && !signal_sync);
    end
end
endmodule

