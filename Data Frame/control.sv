module control_field (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic stuff_bit_inserted,
    input logic rtr_complete,
    input logic [3:0] dlc,
    output logic control_bit,
    output logic [2:0] bit_counter,
    output logic control_complete
);

logic [5:0] shift_register;
logic [2:0] bit_count;

typedef enum logic [1:0] {
    IDLE              = 2'b00,
    LOAD_CONTROL      = 2'b01,
    TRANSMIT_CONTROL  = 2'b10,
    COMPLETE          = 2'b11
} ctrl_state_t;
    
ctrl_state_t current_state, next_state;

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
            if (rtr_complete) begin
                next_state = LOAD_CONTROL;
            end
        end
        LOAD_CONTROL: begin
            next_state = TRANSMIT_CONTROL;
        end
        TRANSMIT_CONTROL: begin
            if (sample_point && !stuff_bit_inserted && bit_count == 3'd5) begin
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
        shift_register <= 6'b111111;
        bit_count <= 3'd0;
        control_bit <= 1'b1;
        control_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                shift_register <= 6'b111111;
                bit_count <= 3'd0;
                control_bit <= 1'b1;
                control_complete <= 1'b0;
            end
            LOAD_CONTROL: begin
                shift_register <= {1'b0, 1'b0, dlc};
                bit_count <= 3'd0;
                control_bit <= 1'b1;
                control_complete <= 1'b0;
            end 
            TRANSMIT_CONTROL: begin
                if (sample_point && !stuff_bit_inserted) begin
                    control_bit <= shift_register[5];
                    shift_register <= {shift_register[4:0], 1'b1};
                    bit_count <= bit_count + 1'b1;
                    
                    if (bit_count == 3'd5) begin
                        control_complete <= 1'b1;
                    end
                    else begin
                        control_complete <= 1'b0;
                    end
                end
                else begin
                    control_bit <= shift_register[5];
                    control_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                control_bit <= 1'b1;
                control_complete <= 1'b1;
                bit_count <= 3'd0;
            end
            default: begin
                shift_register <= 6'b111111;
                bit_count <= 3'd0;
                control_bit <= 1'b1;
                control_complete <= 1'b0;
            end
        endcase
    end
end
assign bit_counter = bit_count;
endmodule