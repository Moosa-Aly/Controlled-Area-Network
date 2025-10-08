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
    input logic [3:0] phase_segment_2,
    output logic [3:0] phase_error,
    output logic resync_required,
    output logic [3:0] resync_adjustment,
    output logic resync_direction
);

localparam [1:0] SYNC_SEG_STATE   = 2'b00,
                 PROP_SEG_STATE   = 2'b01,
                 PHASE_SEG1_STATE = 2'b10,
                 PHASE_SEG2_STATE = 2'b11;

logic [4:0] late_error;

always_comb begin
    if (phase_segment_2 >= quanta_counter[3:0])
        late_error = phase_segment_2 - quanta_counter[3:0];
    else
        late_error = quanta_counter[3:0] - phase_segment_2;
end

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        phase_error       <= 4'b0;
        resync_required   <= 1'b0;
        resync_adjustment <= 4'b0;
        resync_direction  <= 1'b0;
    end else if (hard_sync_request && enable) begin
        phase_error       <= 4'b0;
        resync_required   <= 1'b0;
        resync_adjustment <= 4'b0;
        resync_direction  <= 1'b0;
    end else if (edge_detected && falling_edge && !hard_sync_request && enable) begin
        case (current_segment)
            SYNC_SEG_STATE: begin
                phase_error       <= 4'b0;
                resync_required   <= 1'b0;
                resync_adjustment <= 4'b0;
                resync_direction  <= 1'b0;
            end

            PROP_SEG_STATE, PHASE_SEG1_STATE: begin
                phase_error       <= quanta_counter[3:0];
                resync_adjustment <= (quanta_counter <= resync_jump_width) ? quanta_counter[3:0] : resync_jump_width;
                resync_direction  <= 1'b0;
                resync_required   <= 1'b1;
            end

            PHASE_SEG2_STATE: begin
                phase_error       <= late_error[3:0];
                resync_adjustment <= (late_error <= resync_jump_width) ? late_error[3:0] : resync_jump_width;
                resync_direction  <= 1'b1;
                resync_required   <= 1'b1;
            end

            default: begin
                phase_error       <= 4'b0;
                resync_required   <= 1'b0;
                resync_adjustment <= 4'b0;
                resync_direction  <= 1'b0;
            end
        endcase
        end else begin
            phase_error       <= 4'b0;
            resync_required   <= 1'b0;
            resync_adjustment <= 4'b0;
            resync_direction  <= 1'b0;
        end
    end
endmodule
