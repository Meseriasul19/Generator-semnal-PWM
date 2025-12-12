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
            
            if (compare1 == compare2) begin
                pwm_out <= 1'b0;
            end
            else if (compare1 == 16'd0) begin
                pwm_out <= 1'b0;
            end

            // ALIGNED MODE
            else if (aligned_mode) begin
                if (!right_aligned) begin
                    // Left Aligned: Falls at compare1
                    if (count_val == compare1) 
                        pwm_out <= 1'b0;
                    // Starts High for the next cycle (at end of period)
                    else if (count_val == period) 
                        pwm_out <= 1'b1;
                end 
                else begin
                    // Right Aligned: Rises at compare1
                    if (count_val == compare1)
                        pwm_out <= 1'b1;
                    // Resets to Low at start of cycle
                    else if (count_val == 16'd0)
                        pwm_out <= 1'b0;
                end
            end

            // UNALIGNED MODE
            else if (unaligned_mode) begin
                // Priority 1: Falling edge at compare2
                if (count_val == compare2) 
                    pwm_out <= 1'b0;
                // Priority 2: Rising edge at compare1
                else if (count_val == compare1) 
                    pwm_out <= 1'b1;
                // Priority 3: Reset at start of cycle
                else if (count_val == 16'd0) 
                    pwm_out <= 1'b0;
            end
        end
    end
end

endmodule
