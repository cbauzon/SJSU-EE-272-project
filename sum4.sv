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

module sum4 (
    input logic clk, reset,
    input FP [3:0] A, B,
    input logic pushin,

    output logic pushout,
    output FP Z
);

    typedef struct packed {
        logic sign;            // sign
        logic [4:0] e;      // exponent
        logic [4:0] m;      // mantissa
    } FP;


    FP [3:0] Z_fpm;
    logic [3:0] pushout_fpm;
    assign pushout_fpms = &(pushout_fpm);

    fpm fpm0 (
        clk, reset,
        A[0], B[0],
        pushin,

        pushout_fpm[0],
        Z_fpm[0]
    );

    fpm fpm1 (
        clk, reset,
        A[1], B[1],
        pushin,

        pushout_fpm[1],
        Z_fpm[1]
    );

    fpm fpm2 (
        clk, reset,
        A[2], B[2],
        pushin,

        pushout_fpm[2],
        Z_fpm[2]
    );

    fpm fpm3 (
        clk, reset,
        A[3], B[3],
        pushin,

        pushout_fpm[3],
        Z_fpm[3]
    );

    fpa fpa0 (
        clk, reset,
        pushout_fpms,
        Z_fpm[0],
        Z_fpm[1],
        Z_fpm[2],
        Z_fpm[3],

        pushout,
        Z
    );

endmodule
