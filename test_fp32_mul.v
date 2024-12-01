`default_nettype none
`include "define.vh"

/* test bench */
`timescale 1ns/1ps

module test_fp32_mul;
    parameter STEP = 10;
    reg clk;
    reg [31:0] a, b;
    reg [2:0] rm;
    wire [31:0] result;
    wire nv, of, uf, nx;

    fp32_mul fp32_mul0 (
        .clk(clk), 
        .a(a),
        .b(b),
        .rm(rm),
        .result(result),
        .nv(nv),
        .of(of),
        .uf(uf),
        .nx(nx)
    );

    integer fd_w = 0;
    initial begin
        clk <= 0;
        fd_w = $fopen("test_fp32_mul_result.txt","w");
        forever #(STEP/2) clk <= ~clk;
    end
    
    initial begin
        $dumpfile("test_fp32_mul.vcd");
        $dumpvars(0, test_fp32_mul);
        #(STEP/2+1)
        $fdisplay(fd_w, "\n---------- 10*10 G=0 S=0 ----------");
        a <= {1'b0, 8'b10000010, 23'b01000000000000000000000};
        b <= {1'b0, 8'b10000010, 23'b01000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- normal*normal=subnormal G=0 S=0 ----------");
        a <= {1'b0, 8'b01000000, 23'b00000000000000000000000};
        b <= {1'b0, 8'b00111110, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- normal*subnormal=subnormal G=0 S=0 ----------");
        a <= {1'b0, 8'b10000000, 23'b00000000000000000000000};
        b <= {1'b0, 8'b00000000, 23'b00100000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- normal*subnormal=normal G=0 S=0 ----------");
        a <= {1'b0, 8'b11000000, 23'b00000000000000000000000};
        b <= {1'b0, 8'b00000000, 23'b00100000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- normal*normal=infinity(overflow) G=0 S=0 ----------");
        a <= {1'b0, 8'b11111000, 23'b11111111111111111100000};
        b <= {1'b0, 8'b11111000, 23'b11111111111111100000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- infinity*zero=nan G=0 S=0 ----------");
        a <= {1'b0, 8'b11111111, 23'b00000000000000000000000};
        b <= {1'b0, 8'b00000000, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- infinity*normal=infinity G=0 S=0 ----------");
        a <= {1'b0, 8'b11111111, 23'b00000000000000000000000};
        b <= {1'b0, 8'b10000000, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- qnan*normal=qnan G=0 S=0 ----------");
        a <= {1'b0, 8'b11111111, 23'b10000000000000000000000};
        b <= {1'b0, 8'b10000000, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- snan*normal=snan G=0 S=0 ----------");
        a <= {1'b0, 8'b11111111, 23'b01000000000000000000000};
        b <= {1'b0, 8'b10000000, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        $fdisplay(fd_w, "\n---------- normal*normal=zero(underflow) G=0 S=0 ----------");
        a <= {1'b0, 8'b00000010, 23'b01000000000000000000000};
        b <= {1'b0, 8'b00000001, 23'b00000000000000000000000};
        rm <= `RM_RNE;
        #(STEP)
        rm <= `RM_RTZ;
        #(STEP)
        rm <= `RM_RDN;
        #(STEP)
        rm <= `RM_RUP;
        #(STEP)
        rm <= `RM_RMM;
        #(STEP)
        #(STEP*3)
        $finish;
    end

    initial begin
        #(STEP/2-1)
        forever begin
            #STEP
            $fdisplay(fd_w, "\ntime:", $realtime);
            $fdisplay(fd_w, "  stage0:");
            $fdisplay(fd_w, "    a:%b", fp32_mul0.a);
            $fdisplay(fd_w, "    b:%b", fp32_mul0.b);
            $fdisplay(fd_w, "    mul_in1_exp:%b", fp32_mul0.stage0_mul_in1_exp);
            $fdisplay(fd_w, "    mul_in2_exp:%b", fp32_mul0.stage0_mul_in2_exp);
            $fdisplay(fd_w, "    rouding_mode:%b", fp32_mul0.stage0_rounding_mode);
            $fdisplay(fd_w, "    invalid:%b", fp32_mul0.stage0_invalid);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_mul0.stage0_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_mul0.stage0_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_mul0.stage0_result_is_zero);

            $fdisplay(fd_w, "  stage1:");
            $fdisplay(fd_w, "    sign:%b",  fp32_mul0.stage1_sign);
            $fdisplay(fd_w, "    mul_exp:%b", fp32_mul0.stage1_mul_exp);
            $fdisplay(fd_w, "    a_left_shift:%b", fp32_mul0.stage1_a_left_shift);
            $fdisplay(fd_w, "    b_left_shift:%b", fp32_mul0.stage1_b_left_shift);
            $fdisplay(fd_w, "    exp_right_shift:%b", fp32_mul0.stage1_exp_right_shift);
            $fdisplay(fd_w, "    right_shift_amount:%b", fp32_mul0.stage1_right_shift_amount);
            $fdisplay(fd_w, "    rouding_mode:%b", fp32_mul0.stage1_rounding_mode);
            $fdisplay(fd_w, "    invalid:%b", fp32_mul0.stage1_invalid);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_mul0.stage1_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_mul0.stage1_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_mul0.stage1_result_is_zero);

            $fdisplay(fd_w, "  stage2:");
            $fdisplay(fd_w, "    sign:%b",  fp32_mul0.stage2_sign);
            $fdisplay(fd_w, "    mul_result:%b",  fp32_mul0.stage2_mul_result);
            $fdisplay(fd_w, "    tmp_signif:%b", fp32_mul0.stage2_tmp_signif);
            $fdisplay(fd_w, "    rounding_mode:%b", fp32_mul0.stage2_rounding_mode);
            $fdisplay(fd_w, "    add_one:%b", fp32_mul0.stage2_add_one);
            $fdisplay(fd_w, "    inexact:%b", fp32_mul0.stage2_inexact);

            $fdisplay(fd_w, "  stage3:");
            $fdisplay(fd_w, "    tmp_exp:%b", fp32_mul0.stage3_tmp_exp);
            $fdisplay(fd_w, "    tmp_signif:%b", fp32_mul0.stage3_tmp_signif);
            $fdisplay(fd_w, "    add_one:%b", fp32_mul0.stage3_add_one);
            $fdisplay(fd_w, "    rounding_mode:%b", fp32_mul0.stage3_rounding_mode);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_mul0.stage3_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_mul0.stage3_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_mul0.stage3_result_is_zero);
            $fdisplay(fd_w, "    rounded_signif:%b", fp32_mul0.stage3_rounded_signif); 
            $fdisplay(fd_w, "    result_signif:%b", fp32_mul0.stage3_result_signif); 
            $fdisplay(fd_w, "    tmp2_exp:%b", fp32_mul0.stage3_tmp2_exp); 
            $fdisplay(fd_w, "    result_exp:%b", fp32_mul0.stage3_result_exp); 
            $fdisplay(fd_w, "    nv:%b", fp32_mul0.nv); 
            $fdisplay(fd_w, "    of:%b", fp32_mul0.of); 
            $fdisplay(fd_w, "    uf:%b", fp32_mul0.uf);
            $fdisplay(fd_w, "    nx:%b", fp32_mul0.nx);
            $fdisplay(fd_w, "    result:%b", fp32_mul0.result);
        end
    end

    initial #(STEP*1000) $finish;
endmodule

`default_nettype wire