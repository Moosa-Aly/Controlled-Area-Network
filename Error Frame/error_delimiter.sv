module error_delimiter (
    input  logic clock,
    input  logic reset_n,
    input  logic enable,
    input  logic sample_point,
    input  logic error_flag_complete,
    input  logic bus_recessive,         // Monitors bus for recessive bit
    output logic error_delim_bit,
    output logic [3:0] bit_counter,
    output logic error_delim_complete
);

typedef enum logic [1:0] {
    IDLE              = 2'b00,
    WAIT_RECESSIVE    = 2'b01,
    TRANSMIT_DELIM    = 2'b10,
    COMPLETE          = 2'b11
} error_delim_state_t;
    
error_delim_state_t current_state, next_state;
logic [3:0] bit_count;

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
            if (error_flag_complete) begin
                next_state = WAIT_RECESSIVE;
            end
        end
        WAIT_RECESSIVE: begin
            // Wait until bus becomes recessive (monitors for recessive bit)
            if (sample_point && bus_recessive) begin
                next_state = TRANSMIT_DELIM;
            end
        end
        TRANSMIT_DELIM: begin
            // Transmit 7 more recessive bits after detecting first recessive
            // Total = 8 recessive bits (1 detected + 7 transmitted)
            if (sample_point && bit_count == 4'd7) begin
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
        error_delim_bit <= 1'b1;
        bit_count <= 4'd0;
        error_delim_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                error_delim_bit <= 1'b1;
                bit_count <= 4'd0;
                error_delim_complete <= 1'b0;
            end
            WAIT_RECESSIVE: begin
                // Send recessive bits and monitor bus
                error_delim_bit <= 1'b1;
                error_delim_complete <= 1'b0;
                if (sample_point && bus_recessive) begin
                    bit_count <= 4'd1;  // First recessive bit detected
                end
            end
            TRANSMIT_DELIM: begin
                // All delimiter bits are recessive (1)
                error_delim_bit <= 1'b1;
                
                if (sample_point) begin
                    bit_count <= bit_count + 1'b1;
                    if (bit_count == 4'd7) begin
                        error_delim_complete <= 1'b1;
                    end
                    else begin
                        error_delim_complete <= 1'b0;
                    end
                end
                else begin
                    error_delim_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                error_delim_bit <= 1'b1;
                error_delim_complete <= 1'b1;
                bit_count <= 4'd8;
            end
            default: begin
                error_delim_bit <= 1'b1;
                bit_count <= 4'd0;
                error_delim_complete <= 1'b0;
            end
        endcase
    end
end

assign bit_counter = bit_count;

endmodule