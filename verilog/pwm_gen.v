module pwm_gen (
    // peripheral clock signals
    input clk,
    input rst_n,
    // PWM signal register configuration
    input pwm_en,
    input [15:0] period,
    input [7:0] functions,
    input [15:0] compare1,
    input [15:0] compare2,
    input [15:0] count_val,
    // top facing signals
    output reg pwm_out
);

wire aligned_mode   = (functions[1] == 1'b0);
wire right_aligned  = (functions[0] == 1'b1);
wire unaligned_mode = (functions[1] == 1'b1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        pwm_out <= 1'b0;
    end 
    else begin

        if (!pwm_en) begin
            pwm_out <= pwm_out;
        end 
        else begin

            // ALIGNED MODE
            if (aligned_mode) begin

                // New cycle starts when count reaches 0
                if (count_val == 16'd0) begin
                    pwm_out <= right_aligned ? 1'b0 : 1'b1;
                end

                // Toggle when reaching compare1
                if (count_val == compare1) begin
                    pwm_out <= ~pwm_out;
                end
            end

            // UNALIGNED MODE
            else if (unaligned_mode) begin
                // Always start cycle at 0
                if (count_val == 16'd0) begin
                    pwm_out <= 1'b0;
                end

                // Rising edge at compare1
                if (count_val == compare1) begin
                    pwm_out <= 1'b1;
                end

                // Falling edge at compare2
                if (count_val == compare2) begin
                    pwm_out <= 1'b0;
                end
            end
        end
    end
end

endmodule
