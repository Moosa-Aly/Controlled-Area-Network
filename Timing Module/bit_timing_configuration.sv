module bit_timing_configuration (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic tq_pulse,
    input logic apply_hard_sync,
    input logic apply_resync,
    input logic [3:0] sync_adjustment,
    input logic sync_direction,
    input logic [3:0] prop_seg,
    input logic [3:0] phase_seg1,
    input logic [3:0] phase_seg2,
    output logic [1:0] current_segment,
    output logic [4:0] quanta_counter,
    output logic [4:0] bit_quanta_counter,
    output logic [4:0] bit_position,
    output logic sample_point,
    output logic bit_timing_end,
    output logic sync_seg_active,
    output logic prop_seg_active,
    output logic phase_seg1_active,
    output logic phase_seg2_active,
    output logic [4:0] total_bit_tq,
    output logic config_valid
);

localparam [1:0] SYNC_SEG_STATE   = 2'b00,
                 PROP_SEG_STATE   = 2'b01,
                 PHASE_SEG1_STATE = 2'b10,
                 PHASE_SEG2_STATE = 2'b11;

logic [1:0] segment_state;
logic [3:0] segment_length;
logic [3:0] adjusted_segment_length;
logic segment_done;
logic resync_applied;

assign total_bit_tq = 5'd1 + prop_seg + phase_seg1 + phase_seg2;

assign config_valid = (total_bit_tq >= 8) && (total_bit_tq <= 25) && 
                      (prop_seg >= 1) && (prop_seg <= 8) && 
                      (phase_seg1 >= 1) && (phase_seg1 <= 8) && 
                      (phase_seg2 >= 1) && (phase_seg2 <= 8);

always_comb begin
    case (segment_state)
        SYNC_SEG_STATE:   segment_length = 4'd1;
        PROP_SEG_STATE:   segment_length = prop_seg;
        PHASE_SEG1_STATE: segment_length = phase_seg1;
        PHASE_SEG2_STATE: segment_length = phase_seg2;
        default: segment_length = 4'd1;
    endcase

    adjusted_segment_length = segment_length;
    
    if (apply_resync && !resync_applied) begin
        if (sync_direction == 1'b0) begin
            if (segment_state == PHASE_SEG1_STATE) begin
                adjusted_segment_length = segment_length + sync_adjustment;
            end
        end
        else begin
            if (segment_state == PHASE_SEG2_STATE) begin
                if (segment_length > sync_adjustment) begin
                    adjusted_segment_length = segment_length - sync_adjustment;
                end
                else begin
                    adjusted_segment_length = 4'd1;
                end
            end
        end
    end
end

assign segment_done = (quanta_counter == adjusted_segment_length - 1);

assign bit_position = bit_quanta_counter;

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n) begin
        segment_state <= SYNC_SEG_STATE;
        quanta_counter <= 5'd0;
        bit_quanta_counter <= 5'd0;
        sample_point <= 1'b0;
        bit_timing_end <= 1'b0;
        sync_seg_active <= 1'b0;
        prop_seg_active <= 1'b0;
        phase_seg1_active <= 1'b0;
        phase_seg2_active <= 1'b0;
        resync_applied <= 1'b0;
    end 
    else if (apply_hard_sync && enable) begin
        segment_state <= SYNC_SEG_STATE;
        quanta_counter <= 5'd0;
        bit_quanta_counter <= 5'd0;
        sample_point <= 1'b0;
        bit_timing_end <= 1'b0;
        sync_seg_active <= 1'b1;
        prop_seg_active <= 1'b0;
        phase_seg1_active <= 1'b0;
        phase_seg2_active <= 1'b0;
        resync_applied <= 1'b0;
    end
    else if (!enable || !config_valid) begin
        segment_state <= SYNC_SEG_STATE;
        quanta_counter <= 5'd0;
        bit_quanta_counter <= 5'd0;
        sample_point <= 1'b0;
        bit_timing_end <= 1'b0;
        sync_seg_active <= 1'b0;
        prop_seg_active <= 1'b0;
        phase_seg1_active <= 1'b0;
        phase_seg2_active <= 1'b0;
        resync_applied <= 1'b0;
    end 
    else if (tq_pulse) begin
        sample_point <= 1'b0;
        bit_timing_end <= 1'b0;
        if (apply_resync && !resync_applied) begin
            resync_applied <= 1'b1;
        end
        if (segment_done) begin
            case (segment_state)
                SYNC_SEG_STATE: begin
                    segment_state <= PROP_SEG_STATE;
                    quanta_counter <= 5'd0;
                    bit_quanta_counter <= bit_quanta_counter + 1'b1;
                    sync_seg_active <= 1'b0;
                    prop_seg_active <= 1'b1;
                end
                PROP_SEG_STATE: begin
                    segment_state <= PHASE_SEG1_STATE;
                    quanta_counter <= 5'd0;
                    bit_quanta_counter <= bit_quanta_counter + 1'b1;
                    prop_seg_active <= 1'b0;
                    phase_seg1_active <= 1'b1;
                end
                PHASE_SEG1_STATE: begin
                    segment_state <= PHASE_SEG2_STATE;
                    quanta_counter <= 5'd0;
                    bit_quanta_counter <= bit_quanta_counter + 1'b1;
                    phase_seg1_active <= 1'b0;
                    phase_seg2_active <= 1'b1;
                    sample_point <= 1'b1;
                end
                PHASE_SEG2_STATE: begin
                    segment_state <= SYNC_SEG_STATE;
                    quanta_counter <= 5'd0;
                    bit_quanta_counter <= 5'd0;
                    phase_seg2_active <= 1'b0;
                    sync_seg_active <= 1'b1;
                    bit_timing_end <= 1'b1;
                    resync_applied <= 1'b0;
                end
                default: begin
                    segment_state <= SYNC_SEG_STATE;
                    quanta_counter <= 5'd0;
                end
            endcase
        end 
        else begin
            quanta_counter <= quanta_counter + 1'b1;
            bit_quanta_counter <= bit_quanta_counter + 1'b1;
        end
    end
end

assign current_segment = segment_state;

endmodule