module eof (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic ack_complete,
    output logic eof_bit,
    output logic [2:0] bit_counter,
    output logic eof_complete
);

typedef enum logic [1:0] {
    IDLE         = 2'b00,
    TRANSMIT_EOF = 2'b01,
    COMPLETE     = 2'b10
} eof_state_t;
    
eof_state_t current_state, next_state;
logic [2:0] bit_count;

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
            if (ack_complete) begin
                next_state = TRANSMIT_EOF;
            end
        end
        TRANSMIT_EOF: begin
            if (sample_point && bit_count == 3'd6) begin
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
        eof_bit <= 1'b1;
        bit_count <= 3'd0;
        eof_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                eof_bit <= 1'b1;
                bit_count <= 3'd0;
                eof_complete <= 1'b0;
            end
            TRANSMIT_EOF: begin
                eof_bit <= 1'b1;
                if (sample_point) begin
                    bit_count <= bit_count + 1'b1;
                    if (bit_count == 3'd6) begin
                        eof_complete <= 1'b1;
                    end
                    else begin
                        eof_complete <= 1'b0;
                    end
                end
                else begin
                    eof_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                eof_bit <= 1'b1;
                eof_complete <= 1'b1;
                bit_count <= 3'd7;
            end
            default: begin
                eof_bit <= 1'b1;
                bit_count <= 3'd0;
                eof_complete <= 1'b0;
            end
        endcase
    end
end
assign bit_counter = bit_count;

endmodule
