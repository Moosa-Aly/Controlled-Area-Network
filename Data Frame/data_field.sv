module data_field (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic stuff_bit_inserted,
    input logic control_complete,
    input logic frame_type_out,
    input logic [3:0] dlc,
    input logic [63:0] data,
    output logic data_bit,
    output logic [6:0] bit_counter,
    output logic data_complete
);

logic [63:0] shift_register;
logic [6:0]  bit_count;
logic [6:0]  total_bits;

typedef enum logic [1:0] {
    IDLE          = 2'b00,
    LOAD_DATA     = 2'b01,
    TRANSMIT_DATA = 2'b10,
    COMPLETE      = 2'b11
} data_state_t;
    
data_state_t current_state, next_state;

assign total_bits = (dlc <= 4'd8) ? (dlc * 7'd8) : 7'd64;

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
            if (control_complete) begin
                if (frame_type_out == 1'b1) begin
                    next_state = COMPLETE;
                end
                else begin
                    next_state = LOAD_DATA;
                end
            end
        end  
        LOAD_DATA: begin
            next_state = (total_bits == 7'd0) ? COMPLETE : TRANSMIT_DATA;
        end
        TRANSMIT_DATA: begin
            if (sample_point && !stuff_bit_inserted && bit_count == (total_bits - 1)) begin
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
        shift_register <= 64'h0;
        bit_count <= 7'd0;
        data_bit <= 1'b1;
        data_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                shift_register <= 64'h0;
                bit_count <= 7'd0;
                data_bit <= 1'b1;
                data_complete <= 1'b0;
            end
            LOAD_DATA: begin
                shift_register <= data;
                bit_count <= 7'd0;
                data_bit <= data[63];
                data_complete <= 1'b0;
            end 
            TRANSMIT_DATA: begin
                if (sample_point && !stuff_bit_inserted) begin
                    data_bit <= shift_register[63];
                    shift_register <= {shift_register[62:0], 1'b0};
                    bit_count <= bit_count + 1'b1;
                    
                    if (bit_count == (total_bits - 1)) begin
                        data_complete <= 1'b1;
                    end
                    else begin
                        data_complete <= 1'b0;
                    end
                end
                else begin
                    data_bit <= shift_register[63];
                    data_complete <= 1'b0;
                end
            end  
            COMPLETE: begin
                data_bit <= 1'b1;
                data_complete <= 1'b1;
                if (frame_type_out == 1'b1) begin
                    bit_count <= 7'd0;
                end
                else begin
                    bit_count <= total_bits;
                end
            end
            default: begin
                shift_register <= 64'h0;
                bit_count <= 7'd0;
                data_bit <= 1'b1;
                data_complete <= 1'b0;
            end
        endcase
    end
end
assign bit_counter = bit_count;
endmodule