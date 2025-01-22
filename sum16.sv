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

module sum16 (
    input logic clk, reset,
    input FP [3:0]  A0, B0,
                    A1, B1,
                    A2, B2,
                    A3, B3,
    input logic pushin,

    output logic pushout,
    output FP Z
);

    typedef struct packed {
        logic sign;            // sign
        logic [4:0] e;      // exponent
        logic [4:0] m;      // mantissa
    } FP;


    logic [3:0] pushout_sum4;
    assign pushout_sum4s = &(pushout_sum4);
    FP [3:0] Z_sum4;

    sum4 sum4_0 (
        clk, reset,
        A0, B0,
        pushin,

        pushout_sum4[0],
        Z_sum4[0]
    );

    sum4 sum4_1 (
        clk, reset,
        A1, B1,
        pushin,

        pushout_sum4[1],
        Z_sum4[1]
    );

    sum4 sum4_2 (
        clk, reset,
        A2, B2,
        pushin,

        pushout_sum4[2],
        Z_sum4[2]
    );

    sum4 sum4_3 (
        clk, reset,
        A3, B3,
        pushin,

        pushout_sum4[3],
        Z_sum4[3]
    );

    fpa fpa0 (
        clk, reset,
        pushout_sum4s,
        Z_sum4[0],
        Z_sum4[1],
        Z_sum4[2],
        Z_sum4[3],

        pushout,
        Z
    );


endmodule
