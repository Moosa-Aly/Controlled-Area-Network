module crc_checker (
    input  logic        clock,
    input  logic        reset_n,
    input  logic        enable,
    
    input  logic [14:0] calculated_crc,
    input  logic [14:0] received_crc,
    input  logic        check_enable,
    
    output logic        crc_error,
    output logic        crc_valid
);

    always_ff @(posedge clock or negedge reset_n) begin
        if (!reset_n || !enable) begin
            crc_error <= 1'b0;
            crc_valid <= 1'b0;
        end
        else begin
            if (check_enable) begin
                crc_valid <= 1'b1;
                if (calculated_crc != received_crc) begin
                    crc_error <= 1'b1;
                end
                else begin
                    crc_error <= 1'b0;
                end
            end
            else begin
                crc_error <= 1'b0;
                crc_valid <= 1'b0;
            end
        end
    end

endmodule