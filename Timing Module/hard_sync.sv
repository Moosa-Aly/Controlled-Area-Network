module hard_sync (
    input  logic clock,
    input  logic reset_n,
    input  logic enable,
    input  logic signal_in,
    input  logic falling_edge,
    output logic bus_idle,
    output logic hard_sync_request
);

logic [3:0] counter;

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        counter <= 4'b0;
        bus_idle <= 1'b0;
        hard_sync_request <= 1'b0;
    end
    else if (!enable) begin
        counter <= 4'b0;
        bus_idle <= 1'b0;
        hard_sync_request <= 1'b0;
    end
    else begin
        hard_sync_request <= 1'b0;
        if (signal_in == 1'b1) begin
            if (counter < 4'd11) begin
                counter <= counter + 1'b1;
            end
            if (counter >= 4'd10) begin
                bus_idle <= 1'b1;
            end
        end
        else begin
            counter <= 4'd0;
            bus_idle <= 1'b0;
        end
        if (falling_edge && bus_idle) begin
            hard_sync_request <= 1'b1;
        end
    end
end
endmodule