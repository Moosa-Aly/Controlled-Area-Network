module can_synchronization_controller (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic bus_idle,
    input logic hard_sync_request,
    input logic [3:0] phase_error,
    input logic resync_required,
    input logic [3:0] resync_adjustment,
    input logic resync_direction,
    input logic [1:0] current_segment,
    input logic bit_timing_end,
    input logic sample_point,
    input logic falling_edge,
    output logic apply_hard_sync,
    output logic apply_resync,
    output logic [3:0] sync_adjustment,
    output logic sync_direction,
    output logic sync_active,
    output logic sync_error,
    output logic [1:0] sync_type
);

localparam [1:0] SYNC_SEG_STATE = 2'b00,
                 PROP_SEG_STATE = 2'b01,
                 PHASE_SEG1_STATE = 2'b10,
                 PHASE_SEG2_STATE = 2'b11;

localparam [1:0] NO_SYNC   = 2'b00,
                 HARD_SYNC = 2'b01,
                 RESYNC    = 2'b10;
                     
logic sync_applied_this_bit;
logic hard_sync_valid;
logic resync_valid;

assign hard_sync_valid = hard_sync_request && bus_idle && falling_edge && enable;

always_comb begin
    resync_valid = 1'b0;
    
    if (resync_required && falling_edge && !hard_sync_request && 
        !sync_applied_this_bit && enable) begin
        case (current_segment)
            PROP_SEG_STATE, PHASE_SEG1_STATE, PHASE_SEG2_STATE: begin
                resync_valid = 1'b1;
            end
            SYNC_SEG_STATE: begin
                resync_valid = 1'b0;
            end
            default: resync_valid = 1'b0;
        endcase
    end
end

always_comb begin
    apply_hard_sync = 1'b0;
    apply_resync = 1'b0;
    sync_adjustment = 4'b0;
    sync_direction = 1'b0;
    sync_type = NO_SYNC;
    sync_error = 1'b0;
    if (hard_sync_valid) begin
        apply_hard_sync = 1'b1;
        sync_type = HARD_SYNC;
        sync_adjustment = 4'b0;
    end 
    else if (resync_valid) begin
        apply_resync = 1'b1;
        sync_type = RESYNC;
        sync_adjustment = resync_adjustment;
        sync_direction = resync_direction;
    end 
    else if (resync_required && sync_applied_this_bit) begin
        sync_error = 1'b1;
    end
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        sync_applied_this_bit <= 1'b0;
        sync_active <= 1'b0;  
    end 
    else if (!enable) begin
        sync_applied_this_bit <= 1'b0;
        sync_active <= 1'b0;  
    end 
    else begin
        if (bit_timing_end) begin
            sync_applied_this_bit <= 1'b0;
            sync_active <= 1'b0;
        end
        if (apply_hard_sync || apply_resync) begin
            sync_applied_this_bit <= 1'b1;
            sync_active <= 1'b1;
        end
    end
end

endmodule