module rtr (
    input  logic clock,
    input  logic reset_n,
    input  logic enable,
    input  logic sample_point,
    input  logic stuff_bit_inserted,
    input  logic id_complete,
    input  logic frame_type_in,
    output logic rtr_bit,
    output logic rtr_complete,
    output logic frame_type_out
);

typedef enum logic [1:0] {
    IDLE        = 2'b00,
    TRANSMIT    = 2'b01,
    COMPLETE    = 2'b10
} rtr_state_t;
    
rtr_state_t current_state, next_state;
logic       frame_type_reg;

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
            if (id_complete) begin
                next_state = TRANSMIT;
            end
        end
        TRANSMIT: begin
            if (sample_point && !stuff_bit_inserted) begin
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
        rtr_bit <= 1'b1;
        rtr_complete <= 1'b0;
        frame_type_reg <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                rtr_bit <= 1'b1;
                rtr_complete <= 1'b0;
                frame_type_reg <= frame_type_in;
            end
            TRANSMIT: begin
                rtr_bit <= frame_type_reg;
                rtr_complete <= 1'b0;
            end 
            COMPLETE: begin
                rtr_bit <= 1'b1;
                rtr_complete <= 1'b1;
            end
            default: begin
                rtr_bit <= 1'b1;
                rtr_complete <= 1'b0;
                frame_type_reg <= 1'b0;
            end
        endcase
    end
end

assign frame_type_out = frame_type_reg;
endmodule