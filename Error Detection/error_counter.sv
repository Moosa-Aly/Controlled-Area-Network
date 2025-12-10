module error_counter (
    input  logic       clock,
    input  logic       reset_n,
    input  logic       enable,
    
    input  logic       error_detected,
    input  logic       tx_success,
    input  logic       rx_success,
    input  logic       transmitting,
    
    output logic [7:0] tx_error_count,
    output logic [7:0] rx_error_count,
    output logic       error_active,
    output logic       error_passive,
    output logic       bus_off
);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            tx_error_count <= 8'd0;
            rx_error_count <= 8'd0;
        end
        else begin
            if (error_detected) begin
                if (transmitting) begin
                    if (tx_error_count < 8'd247) begin
                        tx_error_count <= tx_error_count + 8'd8;
                    end
                    else begin
                        tx_error_count <= 8'd255;
                    end
                end
                else begin
                    if (rx_error_count < 8'd247) begin
                        rx_error_count <= rx_error_count + 8'd8;
                    end
                    else begin
                        rx_error_count <= 8'd255;
                    end
                end
            end
            
            if (tx_success && transmitting) begin
                if (tx_error_count > 8'd0) begin
                    tx_error_count <= tx_error_count - 8'd1;
                end
            end
            
            if (rx_success && !transmitting) begin
                if (rx_error_count > 8'd0) begin
                    rx_error_count <= rx_error_count - 8'd1;
                end
            end
        end
    end

    always_comb begin
        if (tx_error_count >= 8'd256 || rx_error_count >= 8'd256) begin
            bus_off = 1'b1;
            error_passive = 1'b0;
            error_active = 1'b0;
        end
        else if (tx_error_count >= 8'd128 || rx_error_count >= 8'd128) begin
            bus_off = 1'b0;
            error_passive = 1'b1;
            error_active = 1'b0;
        end
        else begin
            bus_off = 1'b0;
            error_passive = 1'b0;
            error_active = 1'b1;
        end
    end

endmodule