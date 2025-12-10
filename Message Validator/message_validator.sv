module message_validator (
    input  logic       clock,
    input  logic       reset_n,
    input  logic       enable,
    input  logic       sample_point,
    
    input  logic       is_transmitter,
    input  logic       is_receiver,
    
    input  logic       eof_in_progress,
    input  logic [2:0] eof_bit_count,
    
    input  logic       error_detected,
    
    output logic       tx_message_valid,
    output logic       rx_message_valid,
    output logic       message_complete
);

    logic tx_validation_point;
    logic rx_validation_point;
    logic error_occurred;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            error_occurred <= 1'b0;
            tx_message_valid <= 1'b0;
            rx_message_valid <= 1'b0;
        end
        else begin
            if (error_detected) begin
                error_occurred <= 1'b1;
            end
            
            if (sample_point && eof_in_progress) begin
                if (eof_bit_count == 3'd6 && !error_occurred) begin
                    rx_validation_point = 1'b1;
                    if (is_receiver) begin
                        rx_message_valid <= 1'b1;
                    end
                end
                
                if (eof_bit_count == 3'd7 && !error_occurred) begin
                    tx_validation_point = 1'b1;
                    if (is_transmitter) begin
                        tx_message_valid <= 1'b1;
                    end
                end
            end
            
            if (message_complete) begin
                error_occurred <= 1'b0;
                tx_message_valid <= 1'b0;
                rx_message_valid <= 1'b0;
            end
        end
    end

    assign message_complete = (eof_bit_count == 3'd7) && sample_point;

endmodule