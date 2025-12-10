module bit_stuff_monitor (
    input  logic clock,
    input  logic reset_n,
    input  logic enable,
    input  logic sample_point,
    
    input  logic rx_bit,
    input  logic stuffing_active,
    
    output logic stuff_error
);

    logic [2:0] consecutive_count;
    logic       last_bit;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            consecutive_count <= 3'd0;
            last_bit <= 1'b1;
            stuff_error <= 1'b0;
        end
        else if (sample_point && stuffing_active) begin
            if (rx_bit == last_bit) begin
                consecutive_count <= consecutive_count + 1'b1;
                
                if (consecutive_count == 3'd5) begin
                    stuff_error <= 1'b1;
                end
                else begin
                    stuff_error <= 1'b0;
                end
            end
            else begin
                consecutive_count <= 3'd1;
                stuff_error <= 1'b0;
            end
            
            last_bit <= rx_bit;
        end
        else begin
            stuff_error <= 1'b0;
        end
    end

endmodule