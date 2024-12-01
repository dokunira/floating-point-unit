`default_nettype none
`include "define.vh"

module fp32_add(
    input wire clk,          
    input wire [31:0] a,        // Input 1 (single-precision float)
    input wire [31:0] b,        // Input 2 (single-precision float)
    input wire sub,             // subtraction
    input wire [2:0] rm,        // rounding mode
    output reg [31:0] result,   // Result of the operation
    output wire nv,             // Invalid flag
    output wire of,             // Overflow flag
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
    assign stage0_b_sign = sub ? ~b[31] : b[31];
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
    wire stage0_is_subtraction;
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
    assign stage0_is_subtraction = stage0_a_sign ^ stage0_b_sign;
    assign stage0_invalid = 
        stage0_a_is_snan | stage0_b_is_snan | 
        (stage0_is_subtraction & stage0_a_is_inf & stage0_b_is_inf);
    assign stage0_result_is_nan = stage0_a_is_nan | stage0_b_is_nan | stage0_invalid;
    assign stage0_result_is_inf = 
        (~stage0_a_is_nan & ~stage0_b_is_nan & (stage0_a_is_inf ^ stage0_b_is_inf)) | 
        (~stage0_is_subtraction & stage0_a_is_inf & stage0_b_is_inf);
    assign stage0_result_is_zero =
        stage0_is_subtraction & ~stage0_a_is_inf &
        ({stage0_a_exp, stage0_a_signif} == {stage0_b_exp, stage0_b_signif});

    // Compare sizes
    wire stage0_swap_is_needed;
    wire [31:0] stage0_larger;
    wire [31:0] stage0_smaller;
    wire stage0_larger_sign;
    wire stage0_smaller_sign;
    wire stage0_larger_is_subnormal;
    wire stage0_smaller_is_subnormal;
    wire [7:0] stage0_larger_exp;
    wire [7:0] stage0_smaller_exp;
    wire [23:0] stage0_larger_signif;
    wire [23:0] stage0_smaller_signif;
    assign stage0_swap_is_needed = {stage0_a_exp, stage0_a_signif} < {stage0_b_exp, stage0_b_signif};
    assign stage0_larger = stage0_swap_is_needed ? b : a;
    assign stage0_smaller = stage0_swap_is_needed ? a : b;
    assign stage0_larger_sign = stage0_larger[31];
    assign stage0_smaller_sign = stage0_smaller[31];
    assign stage0_larger_is_subnormal = stage0_larger[30:23] == 8'b0;
    assign stage0_smaller_is_subnormal = stage0_smaller[30:23] == 8'b0;
    assign stage0_larger_exp = (stage0_larger_is_subnormal) ? 8'b1 : stage0_larger[30:23];
    assign stage0_smaller_exp = (stage0_smaller_is_subnormal) ? 8'b1 : stage0_smaller[30:23];
    assign stage0_larger_signif = {~stage0_larger_is_subnormal, stage0_larger[22:0]};
    assign stage0_smaller_signif = {~stage0_smaller_is_subnormal, stage0_smaller[22:0]};

    // Calculate the difference in exponents
    wire [7:0] stage0_exp_diff;
    assign stage0_exp_diff = stage0_larger_exp - stage0_smaller_exp;

    //// pipeline registers ////
    reg stage1_larger_sign;
    reg stage1_is_subtraction;
    reg [7:0] stage1_larger_exp;
    reg [7:0] stage1_exp_diff;
    reg [23:0] stage1_larger_signif;
    reg [23:0] stage1_smaller_signif;
    reg [2:0] stage1_rounding_mode;
    reg stage1_invalid;
    reg stage1_result_is_nan;
    reg stage1_result_is_inf;
    reg stage1_result_is_zero;
    always @(posedge clk) begin
        stage1_larger_sign <= stage0_larger_sign;
        stage1_is_subtraction <= stage0_is_subtraction;
        stage1_larger_exp <= stage0_larger_exp;
        stage1_exp_diff <= stage0_exp_diff;
        stage1_larger_signif <= stage0_larger_signif;
        stage1_smaller_signif <= stage0_smaller_signif;
        stage1_rounding_mode <= stage0_rounding_mode;
        stage1_invalid <= stage0_invalid;
        stage1_result_is_nan <= stage0_result_is_nan;
        stage1_result_is_inf <= stage0_result_is_inf;
        stage1_result_is_zero <= stage0_result_is_zero;
    end

    // Shift
    wire [26:0] stage1_adder_in1;
    wire stage1_is_large_diff;
    wire [4:0] stage1_offset;
    wire [50:0] stage1_shifted_smaller;
    wire [26:0] stage1_adder_in2;
    wire [7:0] stage1_adder_exp;
    assign stage1_adder_in1 = {stage1_larger_signif, 3'b0} >> ~stage1_is_subtraction;
    assign stage1_is_large_diff = stage1_exp_diff > 26;
    assign stage1_offset = stage1_is_large_diff ? 26 : stage1_exp_diff[4:0];
    assign stage1_shifted_smaller = {{stage1_smaller_signif, 27'b0} >> stage1_offset} >> ~stage1_is_subtraction;
    assign stage1_adder_in2 = {stage1_shifted_smaller[50:25], stage1_shifted_smaller[24:0] != 0};
    assign stage1_adder_exp = stage1_is_subtraction ? stage1_larger_exp : stage1_larger_exp + 1;
    // Since exp is less than or equal to 254, no overflow occurs.

    // Add
    wire [26:0] stage1_adder_result;
    assign stage1_adder_result = 
        stage1_is_subtraction ? stage1_adder_in1 - stage1_adder_in2 : stage1_adder_in1 + stage1_adder_in2;

    //// pipeline registers ////
    reg stage2_sign;
    reg [7:0] stage2_adder_exp;
    reg [26:0] stage2_adder_result;
    reg [2:0] stage2_rounding_mode;
    reg stage2_invalid;
    reg stage2_result_is_nan;
    reg stage2_result_is_inf;
    reg stage2_result_is_zero;
    always @(posedge clk) begin
        stage2_sign <= stage1_larger_sign;
        stage2_adder_exp <= stage1_adder_exp;
        stage2_adder_result <= stage1_adder_result;
        stage2_rounding_mode <= stage1_rounding_mode;
        stage2_invalid <= stage1_invalid;
        stage2_result_is_nan <= stage1_result_is_nan;
        stage2_result_is_inf <= stage1_result_is_inf;
        stage2_result_is_zero <= stage1_result_is_zero;
    end

    // Count leading zeros
    reg [4:0] stage2_leading_zero_count;
    always @* begin
        stage2_leading_zero_count = 0;
        while (stage2_leading_zero_count < 25 & ~stage2_adder_result[26-stage2_leading_zero_count]) begin
            stage2_leading_zero_count = stage2_leading_zero_count + 1;
        end
    end

    // Shift
    wire stage2_subnormal;
    wire [7:0] stage2_tmp_exp;
    wire [26:0] stage2_shifted_result;
    wire [23:0] stage2_tmp_signif;
    assign stage2_subnormal = (stage2_adder_exp <= stage2_leading_zero_count);
    assign stage2_tmp_exp = stage2_subnormal ? 0 : stage2_adder_exp - stage2_leading_zero_count;
    assign stage2_shifted_result = stage2_subnormal ? (stage2_adder_result << (stage2_adder_exp-1)) : (stage2_adder_result << stage2_leading_zero_count);
    assign stage2_tmp_signif = stage2_shifted_result[26:3];

    // Decide whether to add 1
    reg stage2_add_one;
    reg stage2_inexact;
    always @* begin
        if (stage2_adder_result[26]) begin
            stage2_inexact = stage2_adder_result[2] | stage2_adder_result[1] | stage2_adder_result[0];
            case(stage2_rounding_mode)
                `RM_RNE: begin
                    stage2_add_one = (stage2_adder_result[2] & (stage2_adder_result[3] | stage2_adder_result[1] | stage2_adder_result[0]));
                end
                `RM_RTZ: begin
                    stage2_add_one = 1'b0;
                end
                `RM_RDN: begin
                    stage2_add_one = (stage2_sign & (stage2_adder_result[2] | stage2_adder_result[1] | stage2_adder_result[0]));
                end
                `RM_RUP: begin
                    stage2_add_one = (~stage2_sign & (stage2_adder_result[2] | stage2_adder_result[1] | stage2_adder_result[0]));
                end
                `RM_RMM: begin
                    stage2_add_one = stage2_adder_result[2];
                end
                default: begin
                    stage2_add_one = (stage2_adder_result[2] & (stage2_adder_result[3] | stage2_adder_result[1] | stage2_adder_result[0]));
                end
            endcase
        end else begin
            stage2_inexact = stage2_adder_result[1] | stage2_adder_result[0];
            case(stage2_rounding_mode)
                `RM_RNE: begin
                    stage2_add_one = (stage2_adder_result[1] & (stage2_adder_result[2] | stage2_adder_result[0]));
                end
                `RM_RTZ: begin
                    stage2_add_one = 1'b0;
                end
                `RM_RDN: begin
                    stage2_add_one = (stage2_sign & (stage2_adder_result[1] | stage2_adder_result[0]));
                end
                `RM_RUP: begin
                    stage2_add_one = (~stage2_sign & (stage2_adder_result[1] | stage2_adder_result[0]));
                end
                `RM_RMM: begin
                    stage2_add_one = stage2_adder_result[1];
                end
                default: begin
                    stage2_add_one = (stage2_adder_result[1] & (stage2_adder_result[2] | stage2_adder_result[0]));
                end
            endcase
        end
    end

    //// pipeline registers ////
    reg stage3_sign;
    reg [7:0] stage3_tmp_exp;
    reg [23:0] stage3_tmp_signif;
    reg stage3_add_one;
    reg [2:0] stage3_rounding_mode;
    reg stage3_subnormal;
    reg stage3_invalid;
    reg stage3_inexact;
    reg stage3_result_is_nan;
    reg stage3_result_is_inf;
    reg stage3_result_is_zero;
    always @(posedge clk) begin
        stage3_sign <= stage2_sign;
        stage3_tmp_exp <= stage2_tmp_exp;
        stage3_tmp_signif <= stage2_tmp_signif;
        stage3_add_one <= stage2_add_one;
        stage3_rounding_mode <= stage2_rounding_mode;
        stage3_subnormal <= stage2_subnormal;
        stage3_invalid <= stage2_invalid;
        stage3_inexact <= stage2_inexact;
        stage3_result_is_nan <= stage2_result_is_nan;
        stage3_result_is_inf <= stage2_result_is_inf;
        stage3_result_is_zero <= stage2_result_is_zero;
    end

    // Round
    wire [24:0] stage3_rounded_signif;
    wire [7:0] stage3_result_exp;
    wire [22:0] stage3_result_signif;
    assign stage3_rounded_signif = stage3_tmp_signif + stage3_add_one;
    assign stage3_result_exp = 
        stage3_subnormal ? {7'b0, stage3_rounded_signif[23]} : stage3_tmp_exp + stage3_rounded_signif[24];
    assign stage3_result_signif = stage3_rounded_signif[24] ? stage3_rounded_signif[23:1] : stage3_rounded_signif[22:0];

    // Handle exceptions
    assign nv = stage3_invalid;
    assign of = ~stage3_result_is_inf & ~stage3_result_is_nan & (stage3_result_exp == 8'hff);
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
            if (stage3_rounding_mode == `RM_RDN) begin
                result = {1'b1, 31'b0};
            end else begin
                result = 32'b0;
            end
        end else begin
            result = {stage3_sign, stage3_result_exp, stage3_result_signif};
        end
    end

endmodule

`default_nettype wire