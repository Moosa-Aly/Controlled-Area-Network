module ack_field (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic sof_complete,
    input logic id_complete,
    input logic rtr_complete,
    input logic control_complete,
    input logic data_complete,
    input logic crc_complete,
    output logic ack_bit,
    output logic [1:0] bit_counter,
    output logic ack_complete,
    output logic frame_valid
);

typedef enum logic [1:0] {
    IDLE               = 2'b00,
    TRANSMIT_ACK_SLOT  = 2'b01,
    TRANSMIT_ACK_DELIM = 2'b10,
    COMPLETE           = 2'b11
} ack_state_t;
    
ack_state_t current_state, next_state;
logic [1:0] bit_count;
logic all_fields_valid;

always_comb begin
    all_fields_valid = sof_complete && 
                       id_complete && 
                       rtr_complete && 
                       control_complete && 
                       data_complete && 
                       crc_complete;
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        current_state <= IDLE;
    end 
    else begin
        current_state <= next_state;
    end
end

always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (all_fields_valid) begin
                next_state = TRANSMIT_ACK_SLOT;
            end
        end
        TRANSMIT_ACK_SLOT: begin
            if (sample_point) begin
                next_state = TRANSMIT_ACK_DELIM;
            end
        end
        TRANSMIT_ACK_DELIM: begin
            if (sample_point) begin
                next_state = COMPLETE;
            end
        end
        COMPLETE: begin
            next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        ack_bit <= 1'b1;
        bit_count <= 2'd0;
        ack_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                ack_bit <= 1'b1;
                bit_count <= 2'd0;
                ack_complete <= 1'b0;
            end
            TRANSMIT_ACK_SLOT: begin
                ack_bit <= 1'b1;
                ack_complete <= 1'b0;
                if (sample_point) begin
                    bit_count <= 2'd1;
                end
            end
            TRANSMIT_ACK_DELIM: begin
                ack_bit <= 1'b1;
                if (sample_point) begin
                    bit_count <= 2'd2;
                    ack_complete <= 1'b1;
                end
                else begin
                    ack_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                ack_bit <= 1'b1;
                ack_complete <= 1'b1;
                bit_count <= 2'd0;
            end
            default: begin
                ack_bit <= 1'b1;
                bit_count <= 2'd0;
                ack_complete <= 1'b0;
            end
        endcase
    end
end
assign bit_counter = bit_count;
assign frame_valid = all_fields_valid;
endmodule
