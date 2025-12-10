module interframe_spacing (
    input  logic       clock,
    input  logic       reset_n,
    input  logic       enable,
    input  logic       sample_point,
    
    input  logic       frame_complete,
    input  logic       was_transmitter,
    input  logic       is_error_passive,
    input  logic       dominant_detected,
    
    output logic       ifs_bit,
    output logic [3:0] bit_counter,
    output logic       ifs_complete,
    output logic       bus_idle
);

    logic [3:0] bit_count;
    
    typedef enum logic [2:0] {
        IDLE            = 3'b000,
        INTERMISSION    = 3'b001,
        SUSPEND_TX      = 3'b010,
        BUS_IDLE        = 3'b011,
        COMPLETE        = 3'b100
    } ifs_state_t;
    
    ifs_state_t current_state, next_state;
    
    logic need_suspend;
    assign need_suspend = was_transmitter && is_error_passive;

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
                if (frame_complete) begin
                    next_state = INTERMISSION;
                end
            end
            
            INTERMISSION: begin
                if (dominant_detected) begin
                    next_state = COMPLETE;
                end
                else if (sample_point && bit_count == 4'd2) begin
                    if (need_suspend) begin
                        next_state = SUSPEND_TX;
                    end
                    else begin
                        next_state = BUS_IDLE;
                    end
                end
            end
            
            SUSPEND_TX: begin
                if (dominant_detected) begin
                    next_state = COMPLETE;
                end
                else if (sample_point && bit_count == 4'd7) begin
                    next_state = BUS_IDLE;
                end
            end
            
            BUS_IDLE: begin
                if (dominant_detected) begin
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
            ifs_bit <= 1'b1;
            bit_count <= 4'd0;
            ifs_complete <= 1'b0;
            bus_idle <= 1'b0;
        end 
        else begin
            case (current_state)
                IDLE: begin
                    ifs_bit <= 1'b1;
                    bit_count <= 4'd0;
                    ifs_complete <= 1'b0;
                    bus_idle <= 1'b0;
                end
                
                INTERMISSION: begin
                    if (sample_point) begin
                        ifs_bit <= 1'b1;
                        bit_count <= bit_count + 1'b1;
                        ifs_complete <= 1'b0;
                        bus_idle <= 1'b0;
                    end
                end
                
                SUSPEND_TX: begin
                    if (sample_point) begin
                        ifs_bit <= 1'b1;
                        bit_count <= bit_count + 1'b1;
                        ifs_complete <= 1'b0;
                        bus_idle <= 1'b0;
                    end
                end
                
                BUS_IDLE: begin
                    ifs_bit <= 1'b1;
                    ifs_complete <= 1'b0;
                    bus_idle <= 1'b1;
                    bit_count <= 4'd0;
                end
                
                COMPLETE: begin
                    ifs_bit <= 1'b1;
                    ifs_complete <= 1'b1;
                    bus_idle <= 1'b0;
                    bit_count <= 4'd0;
                end
                
                default: begin
                    ifs_bit <= 1'b1;
                    bit_count <= 4'd0;
                    ifs_complete <= 1'b0;
                    bus_idle <= 1'b0;
                end
            endcase
        end
    end

    assign bit_counter = bit_count;

endmodule