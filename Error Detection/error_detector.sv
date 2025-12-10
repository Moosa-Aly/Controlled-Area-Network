module error_detector (
    input  logic       clock,
    input  logic       reset_n,
    input  logic       enable,
    input  logic       sample_point,
    
    input  logic       tx_bit,
    input  logic       rx_bit,
    input  logic       transmitting,
    
    input  logic       in_arbitration,
    input  logic       in_ack_slot,
    input  logic       in_stuffed_field,
    input  logic       in_fixed_format_field,
    
    input  logic [14:0] calculated_crc,
    input  logic [14:0] received_crc,
    input  logic        crc_valid,
    
    input  logic        is_passive_error_flag,
    
    output logic        bit_error,
    output logic        stuff_error,
    output logic        crc_error,
    output logic        form_error,
    output logic        ack_error,
    output logic        error_detected,
    output logic        trigger_error_flag
);

    logic [2:0] consecutive_bits;
    logic       last_bit;
    logic       crc_error_pending;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            consecutive_bits <= 3'd0;
            last_bit <= 1'b1;
            bit_error <= 1'b0;
            stuff_error <= 1'b0;
            crc_error <= 1'b0;
            form_error <= 1'b0;
            ack_error <= 1'b0;
            crc_error_pending <= 1'b0;
        end
        else if (sample_point) begin
            bit_error <= 1'b0;
            stuff_error <= 1'b0;
            form_error <= 1'b0;
            ack_error <= 1'b0;
            
            if (rx_bit == last_bit) begin
                consecutive_bits <= consecutive_bits + 1'b1;
            end
            else begin
                consecutive_bits <= 3'd1;
            end
            last_bit <= rx_bit;
            
            if (transmitting && !is_passive_error_flag) begin
                if (tx_bit != rx_bit) begin
                    if (in_arbitration && tx_bit == 1'b1 && rx_bit == 1'b0) begin
                        bit_error <= 1'b0;
                    end
                    else if (in_ack_slot && tx_bit == 1'b1 && rx_bit == 1'b0) begin
                        bit_error <= 1'b0;
                    end
                    else begin
                        bit_error <= 1'b1;
                    end
                end
            end
            
            if (in_stuffed_field && consecutive_bits == 3'd5) begin
                stuff_error <= 1'b1;
            end
            
            if (in_fixed_format_field && rx_bit != 1'b1) begin
                form_error <= 1'b1;
            end
            
            if (in_ack_slot && transmitting && rx_bit == 1'b1) begin
                ack_error <= 1'b1;
            end
            
            if (crc_valid && calculated_crc != received_crc) begin
                crc_error_pending <= 1'b1;
            end
            
            if (crc_error_pending) begin
                crc_error <= 1'b1;
                crc_error_pending <= 1'b0;
            end
            else begin
                crc_error <= 1'b0;
            end
        end
    end

    assign error_detected = bit_error || stuff_error || crc_error || 
                           form_error || ack_error;
    
    assign trigger_error_flag = (bit_error || stuff_error || form_error || ack_error) ||
                               (crc_error && !crc_error_pending);

endmodule