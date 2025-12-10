module phase_error (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic edge_detected,
    input logic falling_edge,
    input logic hard_sync_request,
    input logic [3:0] resync_jump_width,
    input logic [1:0] current_segment,
    input logic [4:0] quanta_counter,
    input logic [4:0] bit_position,
    input logic [3:0] prop_seg,
    input logic [3:0] phase_seg1,
    input logic [3:0] phase_seg2,
    input logic [4:0] total_bit_tq,
    output logic [3:0] phase_error,
    output logic resync_required,
    output logic [3:0] resync_adjustment,
    output logic resync_direction
);

localparam [1:0] SYNC_SEG_STATE   = 2'b00,
                 PROP_SEG_STATE   = 2'b01,
                 PHASE_SEG1_STATE = 2'b10,
                 PHASE_SEG2_STATE = 2'b11;

logic [4:0] sample_point_position;
logic [4:0] edge_position;
logic [4:0] error_magnitude;

assign sample_point_position = 5'd1 + prop_seg + phase_seg1;

always_comb begin
    case (current_segment)
        SYNC_SEG_STATE: begin
            edge_position = quanta_counter;
        end
        PROP_SEG_STATE: begin
            edge_position = 5'd1 + quanta_counter;
        end
        PHASE_SEG1_STATE: begin
            edge_position = 5'd1 + prop_seg + quanta_counter;
        end
        PHASE_SEG2_STATE: begin
            edge_position = 5'd1 + prop_seg + phase_seg1 + quanta_counter;
        end
        default: edge_position = 5'd0;
    endcase
end

always_comb begin
    error_magnitude = 5'd0;
    
    case (current_segment)
        SYNC_SEG_STATE: begin
            error_magnitude = 5'd0;
        end
        
        PROP_SEG_STATE, PHASE_SEG1_STATE: begin
            error_magnitude = edge_position;
        end
        
        PHASE_SEG2_STATE: begin
            if (edge_position > sample_point_position) begin
                error_magnitude = edge_position - sample_point_position;
            end
            else begin
                error_magnitude = 5'd0;
            end
        end
        
        default: error_magnitude = 5'd0;
    endcase
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        phase_error       <= 4'b0;
        resync_required   <= 1'b0;
        resync_adjustment <= 4'b0;
        resync_direction  <= 1'b0;
    end 
    else if (hard_sync_request && enable) begin
        phase_error       <= 4'b0;
        resync_required   <= 1'b0;
        resync_adjustment <= 4'b0;
        resync_direction  <= 1'b0;
    end 
    else if (edge_detected && falling_edge && !hard_sync_request && enable) begin
        case (current_segment)
            SYNC_SEG_STATE: begin
                phase_error       <= 4'b0;
                resync_required   <= 1'b0;
                resync_adjustment <= 4'b0;
                resync_direction  <= 1'b0;
            end
            PROP_SEG_STATE, PHASE_SEG1_STATE: begin
                phase_error       <= error_magnitude[3:0];
                resync_required   <= 1'b1;
                resync_direction  <= 1'b0;
                if (error_magnitude[3:0] <= resync_jump_width) begin
                    resync_adjustment <= error_magnitude[3:0];
                end
                else begin
                    resync_adjustment <= resync_jump_width;
                end
            end
            PHASE_SEG2_STATE: begin
                phase_error       <= error_magnitude[3:0];
                resync_required   <= 1'b1;
                resync_direction  <= 1'b1;
                if (error_magnitude[3:0] <= resync_jump_width) begin
                    resync_adjustment <= error_magnitude[3:0];
                end
                else begin
                    resync_adjustment <= resync_jump_width;
                end
            end
            default: begin
                phase_error       <= 4'b0;
                resync_required   <= 1'b0;
                resync_adjustment <= 4'b0;
                resync_direction  <= 1'b0;
            end
        endcase
    end 
    else if (enable) begin
        phase_error       <= 4'b0;
        resync_required   <= 1'b0;
        resync_adjustment <= 4'b0;
        resync_direction  <= 1'b0;
    end
end
endmodule