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

module fpm(
    input clk, reset,
    input FP A,
    input FP B,
    input pushin,

    output logic pushout,
    output FP Z
);



    // input stage
    FP A_d, A_q;
    FP B_d, B_q;
    logic pushin_d, pushin_q;

    // compute stage 1
    logic [13:0] mult_out_d, mult_out_q;
    logic [5:0] add_out_d, add_out_q;
    logic xor_out_d, xor_out_q;
    logic pushin_q1;

    // compute stage 2
    logic [13:0] mult_out_q1;
    logic [6:0] add_out_d1, add_out_q1;
    logic xor_out_q1;
    logic pushin_q2;

    // normalization stage
    logic [13:0] mult_out_d1, mult_out_q2;
    logic [6:0] add_out_d2, add_out_q2;
    logic xor_out_d1, xor_out_q2;
    logic pushin_q3;


    logic [1:0] upper_mult;
    assign upper_mult = mult_out_q[11-:2];

    always_comb begin
        A_d = A;
        B_d = B;
        pushin_d = pushin;

        mult_out_d = {2'b01, A_q.m} * {2'b01, B_q.m};
        add_out_d = $signed(A_q.e - 16) + $signed(B_q.e - 16);
        xor_out_d = A_q.sign ^ B_q.sign;

        // add_out_d1 = (add_out_q + 2) + 6'd16;
        case (upper_mult)
            'b01: add_out_d1 = ($signed(add_out_q) + 1) + 16;
            'b10: add_out_d1 = ($signed(add_out_q) + 2) + 16;
            'b11: add_out_d1 = ($signed(add_out_q) + 2) + 16;
            default: add_out_d1 = ($signed(add_out_q) + 1) + 16;
        endcase

        if ($signed(add_out_q1) >= 30) begin
            add_out_d2 = 6'b011110;
            mult_out_d1 = (add_out_q1 == 'b11110 && mult_out_q1 <= 'b11000)? mult_out_q1: 'b11000;
            xor_out_d1 = xor_out_q1;
        end else if ($signed(add_out_q1) < 2) begin
            add_out_d2 = '0;
            mult_out_d1 = '0;
            xor_out_d1 = 0;
        end else begin
            add_out_d2 = add_out_q1;
            mult_out_d1 = mult_out_q1;
            xor_out_d1 = xor_out_q1;

        end



    end

    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            A_q <= 0;
            B_q <= 0;
            pushin_q <= 0;

            mult_out_q <= 0;
            add_out_q <= 0;
            xor_out_q <= 0;
            pushin_q1 <= 0;

            mult_out_q1 <= 0;
            add_out_q1 <= 0;
            xor_out_q1 <= 0;
            pushin_q2 <= 0;

            mult_out_q2 <= 0;
            add_out_q2 <= 0;
            xor_out_q2 <=0 ;
            pushin_q3 <= 0;

            // pushout <= 0;
            // Z <= 0;

        end else begin
            if (pushin) begin
                A_q <= A_d;
                B_q <= B_d;
            end
            pushin_q <= pushin_d;

            mult_out_q <= mult_out_d;
            add_out_q <= add_out_d;
            xor_out_q <= xor_out_d;
            pushin_q1 <= pushin_q;

            mult_out_q1 <= (mult_out_q[11])? mult_out_q[10-:5]: mult_out_q[9-:5];
            add_out_q1 <= add_out_d1;
            xor_out_q1 <= xor_out_q;
            pushin_q2 <= pushin_q1;

            mult_out_q2 <= mult_out_d1;
            add_out_q2 <= add_out_d2;
            xor_out_q2 <= xor_out_d1;
            pushin_q3 <= pushin_q2;

            // pushout <= pushin_q2;
            // Z <= '{xor_out_q1, add_out_q1, mult_out_q1};
        end
    end

    assign pushout = pushin_q3;
    assign Z = '{xor_out_q2, add_out_q2, mult_out_q2};


endmodule
