`default_nettype none
`include "define.vh"

/* test bench */
`timescale 1ns/1ps

module test_fp32_add;
    parameter STEP = 10;
    reg clk;
    reg [31:0] a, b;
    reg sub;
    reg [2:0] rm;
    wire [31:0] result;
    wire nv, of, nx;

    fp32_add fp32_add0 (
        .clk(clk), 
        .a(a),
        .b(b),
        .sub(sub),
        .rm(rm),
        .result(result),
        .nv(nv),
        .of(of),
        .nx(nx)
    );

    integer fd_w = 0;
    initial begin
        clk <= 0;
        fd_w = $fopen("test_fp32_add_result.txt","w");
        forever #(STEP/2) clk <= ~clk;
    end
    
    initial begin
        $dumpfile("test_fp32_add.vcd");
        $dumpvars(0, test_fp32_add);
        #(STEP/2+1)
        $fdisplay(fd_w, "\n---------- Addition No carry G=0 S=0 ----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hee, 23'b00000000000000000000000};
        sub <= 0;
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
        $fdisplay(fd_w, "\n---------- Addition No carry G=0 S=1 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'he0, 23'b00000000000000000000001};
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
        $fdisplay(fd_w, "\n---------- Addition No carry long sticky G=0 S=1 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'h10, 23'b00000000000000000000001};
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
        $fdisplay(fd_w, "\n---------- Addition No carry LSB=0 G=1 S=0 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hee, 23'b00000000000000000000010};
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
        $fdisplay(fd_w, "\n---------- Addition No carry LSB=0 G=1 S=1 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hed, 23'b00000000000000000000101};
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
        $fdisplay(fd_w, "\n---------- Addition No carry LSB=1 G=1 S=0 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hed, 23'b00000000000000000001100};
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
        $fdisplay(fd_w, "\n---------- Addition carry LSB=0 G=0 S=0 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hf0, 23'b00000000000000000000000};
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
        $fdisplay(fd_w, "\n---------- Addition round carry LSB=1 G=1 S=0 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hef, 23'b11111111111111111111111};
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
        $fdisplay(fd_w, "\n---------- Addition carry LSB=0 G=1 R=0 S=0 -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hf0, 23'b00000000000000000000001};
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
        $fdisplay(fd_w, "\n---------- Addition carry LSB=1 G=1 R=0 S=0 -----------");
        a <= {1'b1, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b1, 8'hf0, 23'b00000000000000000000011};
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
        $fdisplay(fd_w, "\n---------- Addition subnormal -----------");
        a <= {1'b0, 8'h00, 23'b00000000000000000001111};
        b <= {1'b0, 8'h00, 23'b00000000000000000000001};
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
        $fdisplay(fd_w, "\n---------- Subtraction No bit loss -----------");
        a <= {1'b0, 8'hee, 23'b00000000000000000000100};
        b <= {1'b1, 8'hf0, 23'b11110000000000000001111};
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
        $fdisplay(fd_w, "\n---------- Subtraction 1 bit loss -----------");
        a <= {1'b1, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b0, 8'hee, 23'b00000000000000000000000};
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
        $fdisplay(fd_w, "\n---------- Subtraction multi bit loss -----------");
        a <= {1'b0, 8'hf0, 23'b00000000000000000000000};
        b <= {1'b1, 8'hef, 23'b11111111111111111111100};
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
        $fdisplay(fd_w, "\n---------- Subtraction multi bit loss to subnormal -----------");
        a <= {1'b0, 8'h02, 23'b00000000000000000000000};
        b <= {1'b1, 8'h01, 23'b11111111111111111111111};
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
        $fdisplay(fd_w, "\n---------- overflow -----------");
        a <= {1'b0, 8'hfe, 23'b00000000000000000000000};
        b <= {1'b0, 8'hfe, 23'b00000000000000000000000};
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
        $fdisplay(fd_w, "\n---------- infinity - max normal -----------");
        a <= {1'b0, 8'hff, 23'b00000000000000000000000};
        b <= {1'b1, 8'hfe, 23'b11111111111111111111111};
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
        $fdisplay(fd_w, "\n---------- infinity - infinity -----------");
        a <= {1'b0, 8'hff, 23'b00000000000000000000000};
        b <= {1'b1, 8'hff, 23'b00000000000000000000000};
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
        $fdisplay(fd_w, "\n---------- qnan -----------");
        a <= {1'b0, 8'hff, 23'b10000000000000000000000};
        b <= {1'b1, 8'hff, 23'b00000000000000000000000};
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
        $fdisplay(fd_w, "\n---------- snan -----------");
        a <= {1'b0, 8'hff, 23'b01000000000000000000000};
        b <= {1'b1, 8'hf0, 23'b00000000000000000000000};
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
            $fdisplay(fd_w, "    a:%b", fp32_add0.a);
            $fdisplay(fd_w, "    b:%b", fp32_add0.b);
            $fdisplay(fd_w, "    larger_sign:%b", fp32_add0.stage0_larger_sign);
            $fdisplay(fd_w, "    is_subtraction:%b", fp32_add0.stage0_is_subtraction);
            $fdisplay(fd_w, "    larger_exp:%b", fp32_add0.stage0_larger_exp);
            $fdisplay(fd_w, "    exp_diff:%b", fp32_add0.stage0_exp_diff);
            $fdisplay(fd_w, "    larger_signif:%b", fp32_add0.stage0_larger_signif);
            $fdisplay(fd_w, "    smaller_sifnif:%b", fp32_add0.stage0_smaller_signif);
            $fdisplay(fd_w, "    rouding_mode:%b", fp32_add0.stage0_rounding_mode);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_add0.stage0_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_add0.stage0_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_add0.stage0_result_is_zero);

            $fdisplay(fd_w, "  stage1:");
            $fdisplay(fd_w, "    sign:%b",  fp32_add0.stage1_larger_sign);
            $fdisplay(fd_w, "    adder_exp:%b", fp32_add0.stage1_adder_exp);
            $fdisplay(fd_w, "    adder_in1:%b", fp32_add0.stage1_adder_in1);
            $fdisplay(fd_w, "    adder_in2:%b", fp32_add0.stage1_adder_in2);
            $fdisplay(fd_w, "    is_subtraction:%b", fp32_add0.stage1_is_subtraction);
            $fdisplay(fd_w, "    adder_result:%b", fp32_add0.stage1_adder_result);
            $fdisplay(fd_w, "    rouding_mode:%b", fp32_add0.stage1_rounding_mode);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_add0.stage1_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_add0.stage1_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_add0.stage1_result_is_zero);

            $fdisplay(fd_w, "  stage2:");
            $fdisplay(fd_w, "    leading_zero_count:%b", fp32_add0.stage2_leading_zero_count);
            $fdisplay(fd_w, "    sign:%b",  fp32_add0.stage2_sign);
            $fdisplay(fd_w, "    tmp_exp:%b", fp32_add0.stage2_tmp_exp);
            $fdisplay(fd_w, "    tmp_signif:%b", fp32_add0.stage2_tmp_signif);
            $fdisplay(fd_w, "    rounding_mode:%b", fp32_add0.stage2_rounding_mode);
            $fdisplay(fd_w, "    add_one:%b", fp32_add0.stage2_add_one); 

            $fdisplay(fd_w, "  stage3:");
            $fdisplay(fd_w, "    tmp_exp:%b", fp32_add0.stage3_tmp_exp);
            $fdisplay(fd_w, "    tmp_signif:%b", fp32_add0.stage3_tmp_signif);
            $fdisplay(fd_w, "    add_one:%b", fp32_add0.stage3_add_one);
            $fdisplay(fd_w, "    rounding_mode:%b", fp32_add0.stage3_rounding_mode);
            $fdisplay(fd_w, "    result_is_nan:%b", fp32_add0.stage3_result_is_nan);
            $fdisplay(fd_w, "    result_is_inf:%b", fp32_add0.stage3_result_is_inf);
            $fdisplay(fd_w, "    result_is_zero:%b", fp32_add0.stage3_result_is_zero);
            $fdisplay(fd_w, "    rounded_signif:%b", fp32_add0.stage3_rounded_signif); 
            $fdisplay(fd_w, "    result_exp:%b", fp32_add0.stage3_result_exp); 
            $fdisplay(fd_w, "    result_signif:%b", fp32_add0.stage3_result_signif); 
            $fdisplay(fd_w, "    nv:%b", fp32_add0.nv); 
            $fdisplay(fd_w, "    of:%b", fp32_add0.of); 
            $fdisplay(fd_w, "    nx:%b", fp32_add0.nx);
            $fdisplay(fd_w, "    result:%b", fp32_add0.result);
        end
    end

    initial #(STEP*1000) $finish;
endmodule

`default_nettype wire