module crc_field (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic sample_point,
    input logic stuff_bit_inserted,
    input logic sof_transmitting,
    input logic sof_bit,
    input logic id_complete,
    input  logic bit_id,
    input  logic rtr_complete,
    input  logic rtr_bit,
    input  logic control_complete,
    input  logic control_bit,
    input  logic data_complete,
    input  logic data_bit,
    input  logic frame_type_out,
    output logic crc_bit,
    output logic [3:0] bit_counter,
    output logic crc_complete
);

logic [14:0] crc_register;
logic [14:0] crc_sequence;
logic [3:0] bit_count;
logic crcnxt;
logic nxtbit;
    
typedef enum logic [2:0] {
    IDLE           = 3'b000,
    CALC_CRC       = 3'b001,
    TRANSMIT_CRC   = 3'b010,
    TRANSMIT_DELIM = 3'b011,
    COMPLETE       = 3'b100
} crc_state_t;
    
crc_state_t current_state, next_state;
    
localparam [14:0] CRC_POLYNOMIAL = 15'h4599;

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
            if (sof_transmitting) begin
                next_state = CALC_CRC;
            end
        end
        CALC_CRC: begin
            if (data_complete) begin
                next_state = TRANSMIT_CRC;
            end
        end 
        TRANSMIT_CRC: begin
            if (sample_point && !stuff_bit_inserted && bit_count == 4'd14) begin
                next_state = TRANSMIT_DELIM;
            end
        end    
        TRANSMIT_DELIM: begin
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

always_comb begin
    if (sof_transmitting) begin
        nxtbit = sof_bit;
    end
    else if (!id_complete) begin
        nxtbit = bit_id;
    end
    else if (!rtr_complete) begin
        nxtbit = rtr_bit;
    end
    else if (!control_complete) begin
        nxtbit = control_bit;
    end
    else if (!data_complete && frame_type_out == 1'b0) begin
        nxtbit = data_bit;
    end
    else begin
        nxtbit = 1'b0;
    end
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        crc_register <= 15'h0;
        crc_sequence <= 15'h0;
    end
    else begin
        case (current_state)
            IDLE: begin
                crc_register <= 15'h0;
                crc_sequence <= 15'h0;
            end
                
            CALC_CRC: begin
                if (sample_point && !stuff_bit_inserted) begin
                    crcnxt = nxtbit ^ crc_register[14];
                        
                    crc_register[14:1] <= crc_register[13:0];
                    crc_register[0] <= 1'b0;
                        
                    if (crcnxt) begin
                        crc_register <= crc_register ^ CRC_POLYNOMIAL;
                    end
                end
                    
                if (data_complete) begin
                    crc_sequence <= crc_register;
                end
            end
                
            TRANSMIT_CRC: begin
            end
                
            TRANSMIT_DELIM: begin
            end
                
            COMPLETE: begin
            end
                
            default: begin
                crc_register <= 15'h0;
                crc_sequence <= 15'h0;
            end
        endcase
    end
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        crc_bit <= 1'b1;
        bit_count <= 4'd0;
        crc_complete <= 1'b0;
    end 
    else begin
        case (current_state)
            IDLE: begin
                crc_bit <= 1'b1;
                bit_count <= 4'd0;
                crc_complete <= 1'b0;
            end
            CALC_CRC: begin
                crc_bit <= 1'b1;
                bit_count <= 4'd0;
                crc_complete <= 1'b0;
            end
            TRANSMIT_CRC: begin
                if (sample_point && !stuff_bit_inserted) begin
                    crc_bit <= crc_sequence[14 - bit_count];
                    bit_count <= bit_count + 1'b1;
                    crc_complete <= 1'b0;
                end
                else begin
                    crc_bit <= crc_sequence[14 - bit_count];
                    crc_complete <= 1'b0;
                end
            end
            TRANSMIT_DELIM: begin
                crc_bit <= 1'b1;
                if (sample_point) begin
                    crc_complete <= 1'b1;
                    bit_count <= 4'd15;
                end
                else begin
                    crc_complete <= 1'b0;
                end
            end
            COMPLETE: begin
                crc_bit <= 1'b1;
                crc_complete <= 1'b1;
                bit_count <= 4'd0;
            end
            default: begin
                crc_bit <= 1'b1;
                bit_count <= 4'd0;
                crc_complete <= 1'b0;
            end
        endcase
    end
end
assign bit_counter = bit_count;

endmodule