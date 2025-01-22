/*
MIT License

Copyright (c) 2025 CJ Bauzon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

`timescale 1ns / 1ps

module fpa(
    // inputs
    input clk, reset,
    input pushin,
    input FP A,
    input FP B,
    input FP C,
    input FP D,

    // outputs
    output logic pushout,
    output FP Z
);


    // stage 1: input
    logic   pushin_d, pushin_q;
    FP      A_d, B_d, C_d, D_d,
            A_q, B_q, C_q, D_q;

    // stage 2: find biggest exponent
    logic               pushin_q1;
    FP                  A_q1, B_q1, C_q1, D_q1;
    logic signed [5:0]  largest_exponent_d1, largest_exponent_q1;

    // stage 3: shift and 2's comp
    logic               pushin_q2;
    logic signed [5:0]  largest_exponent_q2;
    FP                  A_q2, B_q2, C_q2, D_q2;
    logic [12:0]        Am_d2, Bm_d2, Cm_d2, Dm_d2,
                        Am_q2, Bm_q2, Cm_q2, Dm_q2;

    // stage 4: add and 2's comp
    logic               pushin_q3;
    logic signed [5:0]  largest_exponent_q3;
    logic               Zs_d3, Zs_q3;
    logic [12:0]        Zm_d3, Zm_q3;
    logic [13:0]        add_intermediate_d3;

    // stage 5: find leftmost 1 and normalize
    logic               pushin_q4;
    logic signed [5:0]  largest_exponent_d4, largest_exponent_q4;
    logic               Zs_q4;
    logic [4:0]         Zm_d4, Zm_q4;
    logic [3:0]         lm1_d4;

    // stage 6: output
    logic       pushin_q5;
    logic       Zs_d5, Zs_q5;
    logic [4:0] Ze_d5, Ze_q5;
    logic [4:0] Zm_d5, Zm_q5;
    logic add_overflow_d5;



    always @(*) begin
        // stage 1
        pushin_d = pushin;
        A_d = A;
        B_d = B;
        C_d = C;
        D_d = D;

        // stage 2
        if (A_q.e >= B_q.e && A_q.e >= C_q.e && A_q.e >= D_q.e) largest_exponent_d1 = (A_q.e - 15);
        else if (B_q.e >= A_q.e && B_q.e >= C_q.e && B_q.e >= D_q.e) largest_exponent_d1 = (B_q.e - 15);
        else if (C_q.e >= A_q.e && C_q.e >= B_q.e && C_q.e >= D_q.e) largest_exponent_d1 = (C_q.e - 15);
        else largest_exponent_d1 = (D_q.e - 15);

        // stage 3
        // check if inputs are 0
        Am_d2 = (A_q1)?({4'b0001, A_q1.m, 4'b0000}):(0);
        Bm_d2 = (B_q1)?({4'b0001, B_q1.m, 4'b0000}):(0);
        Cm_d2 = (C_q1)?({4'b0001, C_q1.m, 4'b0000}):(0);
        Dm_d2 = (D_q1)?({4'b0001, D_q1.m, 4'b0000}):(0);
        // shift
        Am_d2 = Am_d2 >> (largest_exponent_q1 - $signed(A_q1.e - 15));
        Bm_d2 = Bm_d2 >> (largest_exponent_q1 - $signed(B_q1.e - 15));
        Cm_d2 = Cm_d2 >> (largest_exponent_q1 - $signed(C_q1.e - 15));
        Dm_d2 = Dm_d2 >> (largest_exponent_q1 - $signed(D_q1.e - 15));
        // 2's comp
        Am_d2 = (A_q1.sign)?(~Am_d2 + 1):Am_d2;
        Bm_d2 = (B_q1.sign)?(~Bm_d2 + 1):Bm_d2;
        Cm_d2 = (C_q1.sign)?(~Cm_d2 + 1):Cm_d2;
        Dm_d2 = (D_q1.sign)?(~Dm_d2 + 1):Dm_d2;

        // stage 4
        // add
        add_intermediate_d3 = Am_q2 + Bm_q2 + Cm_q2 + Dm_q2;
        Zs_d3 = (add_intermediate_d3[12]);
        // 2's comp
        add_intermediate_d3 = (add_intermediate_d3[12])?(~add_intermediate_d3+1):add_intermediate_d3;
        Zm_d3 = add_intermediate_d3;


        // stage 5
        // find leftmost 1
        casez (Zm_q3)
            13'b1_????_????_????: lm1_d4 = 12;
            13'b0_1???_????_????: lm1_d4 = 11;
            13'b0_01??_????_????: lm1_d4 = 10;
            13'b0_001?_????_????: lm1_d4 = 9;
            13'b0_0001_????_????: lm1_d4 = 8;
            13'b0_0000_1???_????: lm1_d4 = 7;
            13'b0_0000_01??_????: lm1_d4 = 6;
            13'b0_0000_001?_????: lm1_d4 = 5;
            13'b0_0000_0001_????: lm1_d4 = 4;
            13'b0_0000_0000_1???: lm1_d4 = 3;
            13'b0_0000_0000_01??: lm1_d4 = 2;
            13'b0_0000_0000_001?: lm1_d4 = 1;
            13'b0_0000_0000_0001: lm1_d4 = 0;
            default: lm1_d4 = 13;
        endcase
        // normalize
        if (lm1_d4 < 9) largest_exponent_d4 = (largest_exponent_q3) - (9 - lm1_d4);
        else if (lm1_d4 > 9 && lm1_d4 <= 12) largest_exponent_d4 = (largest_exponent_q3) + (lm1_d4 - 9) ;
        else if (lm1_d4 == 9) largest_exponent_d4 = (largest_exponent_q3);
        else largest_exponent_d4 = -15;
        // get correct bits for mantissa
        if (lm1_d4 <= 4 && lm1_d4 >= 1) begin
            Zm_d4 = Zm_q3 << (5-lm1_d4);
        end else if (lm1_d4 == 0) begin
            Zm_d4 = 0;
        end else
            Zm_d4 = Zm_q3[lm1_d4-1-:5];

        // stage 6
        add_overflow_d5 = $signed(largest_exponent_q4)+15 > 30;
        if ($signed(largest_exponent_q4)+15 >= 30) begin
            Zs_d5 = Zs_q4;
            Ze_d5 = 5'b11110;
            Zm_d5 = (Zm_q4 <= 24 && !add_overflow_d5)?(Zm_q4):(5'd24);
        end
        else if ($signed(largest_exponent_q4)+15 >= 2) begin
            Zs_d5 = Zs_q4;
            Ze_d5 = $signed(largest_exponent_q4)+15;
            Zm_d5 = Zm_q4;
        end
        else begin
            Zs_d5 = 0;
            Ze_d5 = 0;
            Zm_d5 = 0;
        end


    end

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            pushin_q <= 0;
            A_q <= 0;
            B_q <= 0;
            C_q <= 0;
            D_q <= 0;

            pushin_q1 <= 0;
            A_q1 <= 0;
            B_q1 <= 0;
            C_q1 <= 0;
            D_q1 <= 0;
            largest_exponent_q1 <= 0;

            pushin_q2 <= 0;
            largest_exponent_q2 <= 0;
            A_q2 <= 0;
            B_q2 <= 0;
            C_q2 <= 0;
            D_q2 <= 0;
            Am_q2 <= 0;
            Bm_q2 <= 0;
            Cm_q2 <= 0;
            Dm_q2 <= 0;

            pushin_q3 <= 0;
            largest_exponent_q3 <= 0;
            Zs_q3 <= 0;
            Zm_q3 <= 0;

            pushin_q4 <= 0;
            largest_exponent_q4 <= 0;
            Zs_q4 <= 0;
            Zm_q4 <= 0;

            pushin_q5 <= 0;
            Zs_q5 <= 0;
            Ze_q5 <= 0;
            Zm_q5 <= 0;
        end
        else begin
            pushin_q <= pushin_d;
            if (pushin) begin
                A_q <= A_d;
                B_q <= B_d;
                C_q <= C_d;
                D_q <= D_d;
            end

            pushin_q1 <= pushin_q;
            A_q1 <= A_q;
            B_q1 <= B_q;
            C_q1 <= C_q;
            D_q1 <= D_q;
            largest_exponent_q1 <= largest_exponent_d1;

            pushin_q2 <= pushin_q1;
            largest_exponent_q2 <= largest_exponent_q1;
            A_q2 <= A_q1;
            B_q2 <= B_q1;
            C_q2 <= C_q1;
            D_q2 <= D_q1;
            Am_q2 <= Am_d2;
            Bm_q2 <= Bm_d2;
            Cm_q2 <= Cm_d2;
            Dm_q2 <= Dm_d2;

            pushin_q3 <= pushin_q2;
            largest_exponent_q3 <= largest_exponent_q2;
            Zs_q3 <= Zs_d3;
            Zm_q3 <= Zm_d3;


            pushin_q4 <= pushin_q3;
            largest_exponent_q4 <= largest_exponent_d4;
            Zs_q4 <= Zs_q3;
            Zm_q4 <= Zm_d4;


            pushin_q5 <= pushin_q4;
            Zs_q5 <= Zs_d5;
            Ze_q5 <= Ze_d5;
            Zm_q5 <= Zm_d5;
        end
    end

    assign Z = '{Zs_q5, Ze_q5, Zm_q5};
    assign pushout = pushin_q5;

endmodule
