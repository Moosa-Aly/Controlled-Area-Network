module overload_frame (
    input  logic       clock,
    input  logic       reset_n,
    input  logic       enable,
    input  logic       sample_point,
    
    input  logic       overload_condition_1,
    input  logic       overload_condition_2,
    input  logic [1:0] overload_count,
    
    output logic       overload_flag_bit,
    output logic [3:0] bit_counter,
    output logic       overload_frame_complete
);

    logic [3:0] bit_count;
    
    typedef enum logic [2:0] {
        IDLE              = 3'b000,
        TRANSMIT_FLAG     = 3'b001,
        WAIT_SUPERPOSITION= 3'b010,
        TRANSMIT_DELIM    = 3'b011,
        COMPLETE          = 3'b100
    } overload_state_t;
    
    overload_state_t current_state, next_state;
    
    logic overload_trigger;
    assign overload_trigger = (overload_condition_1 || overload_condition_2) && 
                             (overload_count < 2'd2);

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
                if (overload_trigger) begin
                    next_state = TRANSMIT_FLAG;
                end
            end
            
            TRANSMIT_FLAG: begin
                if (sample_point && bit_count == 4'd5) begin
                    next_state = WAIT_SUPERPOSITION;
                end
            end
            
            WAIT_SUPERPOSITION: begin
                if (sample_point && bit_count == 4'd11) begin
                    next_state = TRANSMIT_DELIM;
                end
            end
            
            TRANSMIT_DELIM: begin
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

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            overload_flag_bit <= 1'b1;
            bit_count <= 4'd0;
            overload_frame_complete <= 1'b0;
        end 
        else begin
            case (current_state)
                IDLE: begin
                    overload_flag_bit <= 1'b1;
                    bit_count <= 4'd0;
                    overload_frame_complete <= 1'b0;
                end
                
                TRANSMIT_FLAG: begin
                    if (sample_point) begin
                        overload_flag_bit <= 1'b0;
                        bit_count <= bit_count + 1'b1;
                        overload_frame_complete <= 1'b0;
                    end
                end
                
                WAIT_SUPERPOSITION: begin
                    if (sample_point) begin
                        overload_flag_bit <= 1'b1;
                        bit_count <= bit_count + 1'b1;
                        overload_frame_complete <= 1'b0;
                    end
                end
                
                TRANSMIT_DELIM: begin
                    if (sample_point) begin
                        overload_flag_bit <= 1'b1;
                        bit_count <= bit_count + 1'b1;
                        
                        if (bit_count == 4'd7) begin
                            overload_frame_complete <= 1'b1;
                        end
                    end
                end
                
                COMPLETE: begin
                    overload_flag_bit <= 1'b1;
                    overload_frame_complete <= 1'b1;
                    bit_count <= 4'd8;
                end
                
                default: begin
                    overload_flag_bit <= 1'b1;
                    bit_count <= 4'd0;
                    overload_frame_complete <= 1'b0;
                end
            endcase
        end
    end

    assign bit_counter = bit_count;

endmodule