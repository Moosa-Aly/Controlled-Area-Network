module identifier (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic stuff_bit_inserted,
    input logic sof_complete,
    input logic [10:0] identifier,
    output logic bit_id,
    output logic [3:0] id_counter,
    output logic id_complete
);

logic [10:0] id_shift_register;
logic [3:0] bit_count;
logic id_valid;
    
typedef enum logic [1:0] {
    IDLE         = 2'b00,
    LOAD_ID      = 2'b01,
    TRANSMIT_ID  = 2'b10,
    COMPLETE     = 2'b11
} id_state_t;
    
id_state_t current_state, next_state;

assign id_valid = (identifier[10:4] != 7'b1111111);

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
            if (sof_complete && id_valid) begin
                next_state = LOAD_ID;
            end
        end
        LOAD_ID: begin
            next_state = TRANSMIT_ID;
        end
        TRANSMIT_ID: begin
            if (sample_point && !stuff_bit_inserted && bit_count == 4'd10) begin
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
        id_shift_register <= 11'b11111111111;
        bit_count <= 4'd0;
        bit_id <= 1'b1;
        id_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                id_shift_register <= 11'b11111111111;
                bit_count <= 4'd0;
                bit_id <= 1'b1;
                id_complete <= 1'b0;
            end
            LOAD_ID: begin
                id_shift_register <= identifier;
                bit_count <= 4'd0;
                bit_id <= identifier[10];
                id_complete <= 1'b0;
            end   
            TRANSMIT_ID: begin
                if (sample_point && !stuff_bit_inserted) begin
                    bit_id <= id_shift_register[10];
                    id_shift_register <= {id_shift_register[9:0], 1'b1};
                    bit_count <= bit_count + 1'b1;
                    if (bit_count == 4'd10) begin
                        id_complete <= 1'b1;
                    end
                    else begin
                        id_complete <= 1'b0;
                    end
                end
                else begin
                    bit_id <= id_shift_register[10];
                    id_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                bit_id <= 1'b1;
                id_complete <= 1'b1;
                bit_count <= 4'd10;
            end
            default: begin
                id_shift_register <= 11'b11111111111;
                bit_count <= 4'd0;
                bit_id <= 1'b1;
                id_complete <= 1'b0;
            end
        endcase
    end
end
assign id_counter = bit_count;
endmodule