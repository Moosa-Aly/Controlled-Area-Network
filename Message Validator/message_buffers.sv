module message_buffer (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        enable,
    
    input  logic        rx_message_valid,
    input  logic [10:0] received_identifier,
    input  logic [3:0]  received_dlc,
    input  logic [63:0] received_data,
    input  logic        received_frame_type,
    
    output logic        buffer_full,
    output logic        new_message_available,
    output logic [10:0] buffered_identifier,
    output logic [3:0]  buffered_dlc,
    output logic [63:0] buffered_data,
    output logic        buffered_frame_type
);

    logic message_stored;

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            buffered_identifier <= 11'h0;
            buffered_dlc <= 4'h0;
            buffered_data <= 64'h0;
            buffered_frame_type <= 1'b0;
            message_stored <= 1'b0;
            new_message_available <= 1'b0;
        end
        else begin
            if (rx_message_valid && !message_stored) begin
                buffered_identifier <= received_identifier;
                buffered_dlc <= received_dlc;
                buffered_data <= received_data;
                buffered_frame_type <= received_frame_type;
                message_stored <= 1'b1;
                new_message_available <= 1'b1;
            end
            else begin
                new_message_available <= 1'b0;
            end
        end
    end

    assign buffer_full = message_stored;

endmodule