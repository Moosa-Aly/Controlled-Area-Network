module error_flag (
    input  logic clock,
    input  logic reset_n,
    input  logic enable,
    input  logic sample_point,
    input  logic error_detected,        // Trigger for error condition
    input  logic error_passive_mode,    // 0 = error active, 1 = error passive
    output logic error_flag_bit,
    output logic [3:0] bit_counter,
    output logic error_flag_complete
);

typedef enum logic [1:0] {
    IDLE              = 2'b00,
    TRANSMIT_ERR_FLAG = 2'b01,
    COMPLETE          = 2'b10
} error_flag_state_t;
    
error_flag_state_t current_state, next_state;
logic [3:0] bit_count;
logic flag_type;  // 0 = active (dominant), 1 = passive (recessive)

// State transition logic
always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        current_state <= IDLE;
    end 
    else begin
        current_state <= next_state;
    end
end

// Next state logic
always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (error_detected) begin
                next_state = TRANSMIT_ERR_FLAG;
            end
        end
        TRANSMIT_ERR_FLAG: begin
            // Transmit 6 consecutive bits (dominant for active, recessive for passive)
            if (sample_point && bit_count == 4'd5) begin
                next_state = COMPLETE;
            end
        end
        COMPLETE: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

// Output logic
always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        error_flag_bit <= 1'b1;
        bit_count <= 4'd0;
        error_flag_complete <= 1'b0;
        flag_type <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                error_flag_bit <= 1'b1;
                bit_count <= 4'd0;
                error_flag_complete <= 1'b0;
                // Capture error mode when error is detected
                if (error_detected) begin
                    flag_type <= error_passive_mode;
                end
            end
            TRANSMIT_ERR_FLAG: begin
                // ACTIVE ERROR FLAG: 6 dominant bits (0)
                // PASSIVE ERROR FLAG: 6 recessive bits (1)
                error_flag_bit <= flag_type;
                
                if (sample_point) begin
                    bit_count <= bit_count + 1'b1;
                    if (bit_count == 4'd5) begin
                        error_flag_complete <= 1'b1;
                    end
                    else begin
                        error_flag_complete <= 1'b0;
                    end
                end
                else begin
                    error_flag_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                error_flag_bit <= 1'b1;
                error_flag_complete <= 1'b1;
                bit_count <= 4'd6;
            end
            default: begin
                error_flag_bit <= 1'b1;
                bit_count <= 4'd0;
                error_flag_complete <= 1'b0;
                flag_type <= 1'b0;
            end
        endcase
    end
end

assign bit_counter = bit_count;

endmodule