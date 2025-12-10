module bit_stuffing (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic sof_transmitting,
    input logic sof_bit,
    input logic id_complete,
    input logic bit_id,
    input logic rtr_complete,
    input logic rtr_bit,
    input logic control_complete,
    input logic control_bit,
    input logic data_complete,
    input logic data_bit,
    input logic crc_complete,
    input logic crc_bit,
    input logic [3:0] crc_bit_counter,
    input logic ack_complete,
    input logic ack_bit,
    input logic eof_complete,
    input logic eof_bit,
    output logic stuffed_bit,
    output logic stuff_bit_inserted,
    output logic [2:0] consecutive_count,
    output logic stuffing_active
);

typedef enum logic [1:0] {
    IDLE,
    STUFFING,
    NO_STUFF
} state_t;

state_t current_state, next_state;

logic [2:0] bit_counter;
logic       current_bit;
logic       previous_bit;
logic       insert_stuff;
logic       stuff_bit_value;

logic in_crc_delimiter;
assign in_crc_delimiter = (crc_bit_counter == 4'd15) && (!crc_complete);

always_comb begin
    if (sof_transmitting) begin
        current_bit = sof_bit;
    end
    else if (!id_complete) begin
        current_bit = bit_id;
    end
    else if (!rtr_complete) begin
        current_bit = rtr_bit;
    end
    else if (!control_complete) begin
        current_bit = control_bit;
    end
    else if (!data_complete) begin
        current_bit = data_bit;
    end
    else if (!crc_complete && crc_bit_counter < 4'd15) begin
        current_bit = crc_bit;
    end
    else if (in_crc_delimiter) begin
        current_bit = 1'b1;
    end
    else if (!ack_complete) begin
        current_bit = ack_bit;
    end
    else if (!eof_complete) begin
        current_bit = eof_bit;
    end
    else begin
        current_bit = 1'b1;
    end
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

always_comb begin
    next_state = current_state;
    case (current_state)
        IDLE: begin
            if (sof_transmitting)
                next_state = STUFFING;
        end
        STUFFING: begin
            if (in_crc_delimiter)
                next_state = NO_STUFF;
        end
        NO_STUFF: begin
            if (eof_complete)
                next_state = IDLE;
        end
        default: next_state = IDLE;
    endcase
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        bit_counter        <= 3'd1;
        previous_bit       <= 1'b1;
        insert_stuff       <= 1'b0;
        stuff_bit_value    <= 1'b0;
        stuffed_bit        <= 1'b1;
        stuff_bit_inserted <= 1'b0;
    end
    else begin
        case (current_state)
            IDLE: begin
                bit_counter        <= 3'd1;
                previous_bit       <= 1'b1;
                insert_stuff       <= 1'b0;
                stuff_bit_value    <= 1'b0;
                stuffed_bit        <= 1'b1;
                stuff_bit_inserted <= 1'b0;
            end
            STUFFING: begin
                if (sample_point) begin
                    if (in_crc_delimiter) begin
                        stuffed_bit <= 1'b1;
                        stuff_bit_inserted <= 1'b0;
                        bit_counter <= 3'd1;
                        previous_bit <= 1'b1;
                        insert_stuff <= 1'b0;
                    end
                    else if (insert_stuff) begin
                        stuffed_bit <= stuff_bit_value;
                        stuff_bit_inserted <= 1'b1;
                        bit_counter <= 3'd1;
                        previous_bit <= stuff_bit_value;
                        insert_stuff <= 1'b0;
                    end
                    else begin
                        stuffed_bit <= current_bit;
                        stuff_bit_inserted <= 1'b0;
                        if (current_bit == previous_bit) begin
                            bit_counter <= bit_counter + 1'b1;
                            if (bit_counter == 3'd4) begin
                                insert_stuff    <= 1'b1;
                                stuff_bit_value <= ~current_bit;
                            end
                        end
                        else begin
                            bit_counter <= 3'd1;
                        end

                        previous_bit <= current_bit;
                    end
                end
                else begin
                    stuff_bit_inserted <= 1'b0;
                end
            end
            NO_STUFF: begin
                if (sample_point) begin
                    stuffed_bit        <= current_bit;
                    stuff_bit_inserted <= 1'b0;
                    bit_counter  <= 3'd1;
                    previous_bit <= current_bit;
                    insert_stuff <= 1'b0;
                end
                else begin
                    stuff_bit_inserted <= 1'b0;
                end
            end
            default: begin
                bit_counter        <= 3'd1;
                previous_bit       <= 1'b1;
                insert_stuff       <= 1'b0;
                stuff_bit_value    <= 1'b0;
                stuffed_bit        <= 1'b1;
                stuff_bit_inserted <= 1'b0;
            end
        endcase
    end
end
assign consecutive_count = bit_counter;
assign stuffing_active   = (current_state == STUFFING);

endmodule