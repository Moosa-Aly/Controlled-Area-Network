module sof (
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic Tx_request,
    input logic bus_idle,
    input logic apply_hard_sync,
    input logic sample_point,
    output logic sof_bit,
    output logic sof_complete,
    output logic sof_transmitting
);
  
typedef enum logic [1:0] {
    IDLE       = 2'b00,
    SYNC_WAIT  = 2'b01,
    SEND_SOF   = 2'b10,
    COMPLETE   = 2'b11
} sof_state_t;
    
sof_state_t current_state, next_state;

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
            if (Tx_request && bus_idle) begin
                next_state = SYNC_WAIT;
            end
        end
        SYNC_WAIT: begin
            if (apply_hard_sync) begin
                next_state = SEND_SOF;
            end
        end
        SEND_SOF: begin
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

always_ff @(posedge clock or negedge reset_n) begin
    if (!reset_n || !enable) begin
        sof_bit <= 1'b1;
        sof_complete <= 1'b0;
        sof_transmitting <= 1'b0;
    end
    else begin
        case (current_state)
            IDLE: begin
                sof_bit <= 1'b1;
                sof_complete <= 1'b0;
                sof_transmitting <= 1'b0;
            end
            SYNC_WAIT: begin
                sof_bit <= 1'b1;
                sof_complete <= 1'b0;
                sof_transmitting <= 1'b0;
            end
            SEND_SOF: begin
                sof_bit <= 1'b0;
                sof_complete <= 1'b0;
                sof_transmitting <= 1'b1;
            end
            COMPLETE: begin
                sof_bit <= 1'b1;
                sof_complete <= 1'b1;
                sof_transmitting <= 1'b0;
            end
            default: begin
                sof_bit <= 1'b1;
                sof_complete <= 1'b0;
                sof_transmitting <= 1'b0;
            end
        endcase
    end
end
endmodule