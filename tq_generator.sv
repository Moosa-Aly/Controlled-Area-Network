module tq_generator (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic [4:0] prescaler,
    output logic tq_pulse 
);     
    logic [4:0] counter;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            counter <= 5'd0;
            tq_pulse <= 1'b0;
        end else if (enable && prescaler != 5'd0) begin
            if (counter == prescaler - 1) begin
                counter <= 5'd0;
                tq_pulse <= 1'b1;
            end else begin
                counter <= counter + 1;
                tq_pulse <= 1'b0;
            end
        end else begin
            counter <= 5'd0;
            tq_pulse <= 1'b0;
        end
    end
endmodule
