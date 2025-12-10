module retransmission_controller (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        enable,
    
    input  logic        tx_message_valid,
    input  logic        error_detected,
    input  logic        bus_idle,
    
    input  logic [10:0] original_identifier,
    input  logic [3:0]  original_dlc,
    input  logic [63:0] original_data,
    input  logic        original_frame_type,
    
    output logic        retransmit_request,
    output logic [10:0] retransmit_identifier,
    output logic [3:0]  retransmit_dlc,
    output logic [63:0] retransmit_data,
    output logic        retransmit_frame_type,
    output logic [3:0]  retransmit_count
);

    typedef enum logic [1:0] {
        IDLE            = 2'b00,
        PENDING_RETX    = 2'b01,
        WAIT_BUS_IDLE   = 2'b10,
        RETRANSMITTING  = 2'b11
    } retx_state_t;
    
    retx_state_t current_state, next_state;
    
    logic [10:0] stored_identifier;
    logic [3:0]  stored_dlc;
    logic [63:0] stored_data;
    logic        stored_frame_type;
    logic [3:0]  retry_count;

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
                if (error_detected) begin
                    next_state = PENDING_RETX;
                end
            end
            
            PENDING_RETX: begin
                next_state = WAIT_BUS_IDLE;
            end
            
            WAIT_BUS_IDLE: begin
                if (bus_idle) begin
                    next_state = RETRANSMITTING;
                end
            end
            
            RETRANSMITTING: begin
                if (tx_message_valid) begin
                    next_state = IDLE;
                end
                else if (error_detected) begin
                    next_state = PENDING_RETX;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            stored_identifier <= 11'h0;
            stored_dlc <= 4'h0;
            stored_data <= 64'h0;
            stored_frame_type <= 1'b0;
            retry_count <= 4'd0;
            retransmit_request <= 1'b0;
        end 
        else begin
            case (current_state)
                IDLE: begin
                    if (error_detected) begin
                        stored_identifier <= original_identifier;
                        stored_dlc <= original_dlc;
                        stored_data <= original_data;
                        stored_frame_type <= original_frame_type;
                    end
                    else if (tx_message_valid) begin
                        retry_count <= 4'd0;
                    end
                    retransmit_request <= 1'b0;
                end
                
                PENDING_RETX: begin
                    retry_count <= retry_count + 1'b1;
                    retransmit_request <= 1'b0;
                end
                
                WAIT_BUS_IDLE: begin
                    retransmit_request <= 1'b0;
                end
                
                RETRANSMITTING: begin
                    retransmit_request <= 1'b1;
                end
                
                default: begin
                    retransmit_request <= 1'b0;
                end
            endcase
        end
    end

    assign retransmit_identifier = stored_identifier;
    assign retransmit_dlc = stored_dlc;
    assign retransmit_data = stored_data;
    assign retransmit_frame_type = stored_frame_type;
    assign retransmit_count = retry_count;

endmodule