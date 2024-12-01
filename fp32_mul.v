`default_nettype none
`include "define.vh"

module fp32_mul(
    input wire clk,          
    input wire [31:0] a,        // Input 1 (single-precision float)
    input wire [31:0] b,        // Input 2 (single-precision float)
    input wire [2:0] rm,        // rounding mode
    output reg [31:0] result,   // Result of the operation
    output wire nv,             // Invalid flag
    output wire of,             // Overflow flag
    output wire uf,             // Underflow flag
    output wire nx              // Inexact flag
);

    // Disassemble
    wire stage0_a_sign;
    wire stage0_b_sign;
    wire [7:0] stage0_a_exp;
    wire [7:0] stage0_b_exp;
    wire [22:0] stage0_a_signif;
    wire [22:0] stage0_b_signif;
    wire [2:0] stage0_rounding_mode;
    assign stage0_a_sign = a[31];
    assign stage0_b_sign = b[31];
    assign stage0_a_exp = a[30:23];
    assign stage0_b_exp = b[30:23];
    assign stage0_a_signif = a[22:0];
    assign stage0_b_signif = b[22:0];
    assign stage0_rounding_mode = rm;

    // Handle special caces
    wire stage0_a_is_nan;
    wire stage0_b_is_nan;
    wire stage0_a_is_inf;
    wire stage0_b_is_inf;
    wire stage0_a_is_snan;
    wire stage0_b_is_snan;
    wire stage0_a_is_zero;
    wire stage0_b_is_zero;
    wire stage0_invalid;
    wire stage0_result_is_nan;
    wire stage0_result_is_inf;
    wire stage0_result_is_zero;
    assign stage0_a_is_nan = (stage0_a_exp == 8'hff) & (stage0_a_signif != 23'b0);
    assign stage0_b_is_nan = (stage0_b_exp == 8'hff) & (stage0_b_signif != 23'b0);
    assign stage0_a_is_inf = (stage0_a_exp == 8'hff) & (stage0_a_signif == 23'b0);
    assign stage0_b_is_inf = (stage0_b_exp == 8'hff) & (stage0_b_signif == 23'b0);
    assign stage0_a_is_snan = (stage0_a_exp == 8'hff) & ~stage0_a_signif[22] & (stage0_a_signif[21:0] != 22'b0);
    assign stage0_b_is_snan = (stage0_b_exp == 8'hff) & ~stage0_b_signif[22] & (stage0_b_signif[21:0] != 22'b0);
    assign stage0_a_is_zero = (stage0_a_exp == 8'b0) & (stage0_a_signif == 23'b0);
    assign stage0_b_is_zero = (stage0_b_exp == 8'b0) & (stage0_b_signif == 23'b0);
    assign stage0_invalid = 
        stage0_a_is_snan | stage0_b_is_snan |
        (stage0_a_is_inf & stage0_b_is_zero) | (stage0_a_is_zero & stage0_b_is_inf);
    assign stage0_result_is_nan = stage0_a_is_nan | stage0_b_is_nan | stage0_invalid;
    assign stage0_result_is_inf = ~stage0_result_is_nan & (stage0_a_is_inf | stage0_b_is_inf);
    assign stage0_result_is_zero = ~stage0_result_is_nan & (stage0_a_is_zero | stage0_b_is_zero);

    // Determine the sign
    wire stage0_sign;
    assign stage0_sign = stage0_a_sign ^ stage0_b_sign;

    // Handle subnormal
    wire stage0_a_is_subnormal;
    wire stage0_b_is_subnormal;
    wire [23:0] stage0_mul_in1_signif;
    wire [23:0] stage0_mul_in2_signif;
    assign stage0_a_is_subnormal = (stage0_a_exp == 8'b0);
    assign stage0_b_is_subnormal = (stage0_b_exp == 8'b0);
    assign stage0_mul_in1_signif = {~stage0_a_is_subnormal, stage0_a_signif};
    assign stage0_mul_in2_signif = {~stage0_b_is_subnormal, stage0_b_signif};

    // Multiply
    wire [47:0] stage0_mul_tmp;
    assign stage0_mul_tmp = stage0_mul_in1_signif * stage0_mul_in2_signif;

    // Count leading zeros
    reg [4:0] stage0_a_leading_zero_count;
    always @* begin
        stage0_a_leading_zero_count = 0;
        while (stage0_a_leading_zero_count < 22 & ~stage0_a_signif[22-stage0_a_leading_zero_count]) begin
            stage0_a_leading_zero_count = stage0_a_leading_zero_count + 1;
        end
    end
    reg [4:0] stage0_b_leading_zero_count;
    always @* begin
        stage0_b_leading_zero_count = 0;
        while (stage0_b_leading_zero_count < 22 & ~stage0_b_signif[22-stage0_b_leading_zero_count]) begin
            stage0_b_leading_zero_count = stage0_b_leading_zero_count + 1;
        end
    end

    // Calculate the exponents
    wire [9:0] stage0_mul_in1_exp;
    wire [9:0] stage0_mul_in2_exp;
    wire [9:0] stage0_mul_exp;
    assign stage0_mul_in1_exp = (stage0_a_is_subnormal) ? -{5'b0, stage0_a_leading_zero_count} : {2'b0, stage0_a_exp};
    assign stage0_mul_in2_exp = (stage0_b_is_subnormal) ? -{5'b0, stage0_b_leading_zero_count} : {2'b0, stage0_b_exp};
    assign stage0_mul_exp = $signed(stage0_mul_in1_exp) + $signed(stage0_mul_in2_exp) - 127;
    
    wire [9:0] stage0_a_left_shift;
    wire [9:0] stage0_b_left_shift;
    assign stage0_a_left_shift = (stage0_a_is_subnormal) ? stage0_a_leading_zero_count + 1 : 0;
    assign stage0_b_left_shift = (stage0_b_is_subnormal) ? stage0_b_leading_zero_count + 1 : 0;
    

    //// pipeline registers ////
    reg stage1_sign;
    reg [9:0] stage1_a_left_shift;
    reg [9:0] stage1_b_left_shift;
    reg [9:0] stage1_mul_exp;
    reg [47:0] stage1_mul_tmp;
    reg [2:0] stage1_rounding_mode;
    reg stage1_invalid;
    reg stage1_result_is_nan;
    reg stage1_result_is_inf;
    reg stage1_result_is_zero;
    always @(posedge clk) begin
        stage1_sign <= stage0_sign;
        stage1_a_left_shift <= stage0_a_left_shift;
        stage1_b_left_shift <= stage0_b_left_shift;
        stage1_mul_exp <= stage0_mul_exp;
        stage1_mul_tmp <= stage0_mul_tmp;
        stage1_rounding_mode <= stage0_rounding_mode;
        stage1_invalid <= stage0_invalid;
        stage1_result_is_nan <= stage0_result_is_nan;
        stage1_result_is_inf <= stage0_result_is_inf;
        stage1_result_is_zero <= stage0_result_is_zero;
    end

    // Calculate shift amount
    wire [9:0] stage1_exp_right_shift;
    wire [9:0] stage1_tmp_right_shift_amount;
    wire [5:0] stage1_right_shift_amount;
    assign stage1_exp_right_shift = ($signed(stage1_mul_exp) <= 0) ? 1 - stage1_mul_exp : 0;
    assign stage1_tmp_right_shift_amount = 23 - stage1_a_left_shift - stage1_b_left_shift + stage1_exp_right_shift;
    assign stage1_right_shift_amount = (stage1_tmp_right_shift_amount > 49) ? 49 : stage1_tmp_right_shift_amount;

    // Multiplay

    //// pipeline registers ////
    reg stage2_sign;
    reg [9:0] stage2_mul_exp;
    reg [47:0] stage2_mul_result;
    reg [5:0] stage2_right_shift_amount;
    reg [2:0] stage2_rounding_mode;
    reg stage2_invalid;
    reg stage2_result_is_nan;
    reg stage2_result_is_inf;
    reg stage2_result_is_zero;
    always @(posedge clk) begin
        stage2_sign <= stage1_sign;
        stage2_mul_exp <= stage1_mul_exp;
        stage2_mul_result <= stage1_mul_tmp;
        stage2_right_shift_amount <= stage1_right_shift_amount;
        stage2_rounding_mode <= stage1_rounding_mode;
        stage2_invalid <= stage1_invalid;
        stage2_result_is_nan <= stage1_result_is_nan;
        stage2_result_is_inf <= stage1_result_is_inf;
        stage2_result_is_zero <= stage1_result_is_zero;
    end

    // Shift
    wire [73:0] stage2_shifted_result;
    wire [26:0] stage2_tmp_signif;
    assign stage2_shifted_result = ({stage2_mul_result, 49'b0} >> stage2_right_shift_amount);
    assign stage2_tmp_signif = {stage2_shifted_result[73:48], (stage2_shifted_result[47:0] != 0)};
    // round bit, sticky bit

    // Decide whether to add 1
    reg stage2_add_one;
    reg stage2_inexact;
    always @* begin
        if (stage2_tmp_signif[26]) begin
            stage2_inexact = stage2_tmp_signif[2] | stage2_tmp_signif[1] | stage2_tmp_signif[0];
            case(stage2_rounding_mode)
                `RM_RNE: begin
                    stage2_add_one = (stage2_tmp_signif[2] & (stage2_tmp_signif[3] | stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
                `RM_RTZ: begin
                    stage2_add_one = 1'b0;
                end
                `RM_RDN: begin
                    stage2_add_one = (stage2_sign & (stage2_tmp_signif[2] | stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
                `RM_RUP: begin
                    stage2_add_one = (~stage2_sign & (stage2_tmp_signif[2] | stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
                `RM_RMM: begin
                    stage2_add_one = stage2_tmp_signif[2];
                end
                default: begin
                    stage2_add_one = (stage2_tmp_signif[2] & (stage2_tmp_signif[3] | stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
            endcase
        end else begin
            stage2_inexact = stage2_tmp_signif[1] | stage2_tmp_signif[0];
            case(stage2_rounding_mode)
                `RM_RNE: begin
                    stage2_add_one = (stage2_tmp_signif[1] & (stage2_tmp_signif[2] | stage2_tmp_signif[0]));
                end
                `RM_RTZ: begin
                    stage2_add_one = 1'b0;
                end
                `RM_RDN: begin
                    stage2_add_one = (stage2_sign & (stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
                `RM_RUP: begin
                    stage2_add_one = (~stage2_sign & (stage2_tmp_signif[1] | stage2_tmp_signif[0]));
                end
                `RM_RMM: begin
                    stage2_add_one = stage2_tmp_signif[1];
                end
                default: begin
                    stage2_add_one = (stage2_tmp_signif[1] & (stage2_tmp_signif[2] | stage2_tmp_signif[0]));
                end
            endcase
        end
    end

    //// pipeline registers ////
    reg stage3_sign;
    reg [9:0] stage3_tmp_exp;
    reg [24:0] stage3_tmp_signif;
    reg stage3_add_one;
    reg [2:0] stage3_rounding_mode;
    reg stage3_invalid;
    reg stage3_inexact;
    reg stage3_result_is_nan;
    reg stage3_result_is_inf;
    reg stage3_result_is_zero;
    always @(posedge clk) begin
        stage3_sign <= stage2_sign;
        stage3_tmp_exp <= stage2_mul_exp;
        stage3_tmp_signif <= stage2_tmp_signif[26:2];
        stage3_add_one <= stage2_add_one;
        stage3_rounding_mode <= stage2_rounding_mode;
        stage3_invalid <= stage2_invalid;
        stage3_inexact <= stage2_inexact;
        stage3_result_is_nan <= stage2_result_is_nan;
        stage3_result_is_inf <= stage2_result_is_inf;
        stage3_result_is_zero <= stage2_result_is_zero;
    end

    // Round
    wire [24:0] stage3_rounded_signif;
    wire [9:0] stage3_tmp2_exp;
    wire [22:0] stage3_result_signif;
    assign stage3_rounded_signif = stage3_tmp_signif + stage3_add_one;
    assign stage3_tmp2_exp = stage3_tmp_exp + stage3_rounded_signif[24];
    assign stage3_result_signif = stage3_rounded_signif[24] ? stage3_rounded_signif[23:1] : stage3_rounded_signif[22:0];

    wire [7:0] stage3_result_exp;
    assign stage3_result_exp = 
        ($signed(stage3_tmp2_exp) <= 0) ? {7'b0, stage3_rounded_signif[23]} :
        ($signed(stage3_tmp2_exp) >= 255) ? 8'hff : stage3_tmp2_exp;

    // Handle exceptions
    assign nv = stage3_invalid;
    assign of = ~stage3_result_is_inf & ~stage3_result_is_nan & (stage3_result_exp == 8'hff);
    assign uf = (stage3_result_exp == 0) & stage3_inexact;
    assign nx = ~stage3_result_is_nan & (stage3_inexact | of);
    always @* begin
        if (stage3_result_is_nan) begin
            result = 32'h7fc00000;
        end else if (stage3_result_is_inf) begin
            result = {stage3_sign, 8'hff, 23'b0};
        end else if (of) begin
            case(stage3_rounding_mode)
                `RM_RNE: begin
                    result = {stage3_sign, 8'hff, 23'b0};
                end
                `RM_RTZ: begin
                    result = {stage3_sign, 8'hfe, {23{1'b1}}};
                end
                `RM_RDN: begin
                    if (stage3_sign) begin
                        result = {1'b1, 8'hff, 23'b0};
                    end else begin
                        result = {1'b0, 8'hfe, {23{1'b1}}};
                    end
                end
                `RM_RUP: begin
                    if (stage3_sign) begin
                        result = {1'b1, 8'hfe, {23{1'b1}}};
                    end else begin
                        result = {1'b0, 8'hff, 23'b0};
                    end
                end
                `RM_RMM: begin
                    result = {stage3_sign, 8'hff, 23'b0};
                end
                default: begin
                    result = {stage3_sign, 8'hff, 23'b0};
                end
            endcase
        end else if (stage3_result_is_zero) begin
            result = {stage3_sign, 31'b0};
        end else begin
            result = {stage3_sign, stage3_result_exp, stage3_result_signif};
        end
    end

endmodule

`default_nettype wire