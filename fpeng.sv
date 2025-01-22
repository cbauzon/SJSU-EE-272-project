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

typedef struct packed {
        logic sign;            // sign
        logic [4:0] e;      // exponent
        logic [4:0] m;      // mantissa
    } FP;

`include "fpm.sv"
`include "fpa.sv"
`include "sum4.sv"
`include "sum16.sv"
`include "sbus_rcontroller.sv"
`include "sbus_wcontroller.sv"
`include "registers.sv"
`include "fifo.sv"




module fpeng (
    // register i/f
    input logic Rclk,
    input logic Rreset,
    input logic Rwrite,
    input logic Rxfr,
    input logic [11:0] Raddr,
    input logic [63:0] Rwdata,
    output logic [63:0] Rrdata,
    input logic RdevselX,

    // spartan i/f
    input logic Sclk,
    input logic Sreset,
    output logic Srrequest,
    input logic Srack,
    output logic [47:0] Sraddr,
    input logic Srstrobe,
    input logic [351:0] Srdata,
    output logic Swrequest,
    input logic Swack,
    output logic [47:0] Swaddr,
    output logic [175:0] Swdata

);



    logic wdone, rdone, all_done;
    assign all_done = wdone & rdone;

    logic [47:0] fetch_addr;
    logic [47:0] store_addr;
    logic [15:0] numwords;
    logic start;

    logic [175:0] fifo_data;
    logic sbus_pushin;
    logic [351:0] sbus_rdata;
    // logic incr_fetch_addr;
    logic fifo_read;
    // logic incr_store_addr;
    logic [15:0] tx_count_q, numwords_q;
    logic [10:0][3:0]   A0, B0,
                        A1, B1,
                        A2, B2,
                        A3, B3;
    assign {A0, A1, A2, A3} = sbus_rdata[351-:176];
    assign {B0, B1, B2, B3} = sbus_rdata[175-:176];

    logic [10:0] sum16_out;
    logic sum16_pushout;
        // logic [175:0] fifo_out1;

    fifo fifo1 (
        .clk (Sclk),
        .reset (Sreset),
        .push (sum16_pushout),
        .read (fifo_read),
        .wdata (sum16_out),

        .data (fifo_data),
        .ready (fifo_ready)
    );

    registers register1 (
        // external inputs
        .Rclk (Rclk),
        .Rreset (Rreset),
        .Rwrite (Rwrite),
        .Rxfr (Rxfr),
        .Raddr (Raddr),
        .Rwdata (Rwdata),
        .RdevselX (RdevselX),

        //internal inputs
        .incr_fetch_addr (incr_fetch_addr),
        .incr_store_addr (incr_store_addr),
        .done (all_done),

        // external outputs
        .Rrdata (Rrdata),

        // internal outputs
        .fetch_addr (fetch_addr),
        .store_addr (store_addr),
        .numwords (numwords),
        .start (start)

    );


    sbus_wcontroller sbus_wcontroller1 (
        // external input i/f
        .Sclk (Sclk),
        .Sreset (Sreset),
        .Swack (Swack),

        // internal input i/f
        .wrequest (fifo_ready),
        .waddr (store_addr),
        .wdata (fifo_data),
        .numwords (numwords),

        // external output i/f
        .Swrequest (Swrequest),
        .Swaddr (Swaddr),
        .Swdata (Swdata),

        // internal output i/f
        .fifo_read (fifo_read),
        .incr_store_addr (incr_store_addr),
        .done (wdone),
        .tx_cnt_q (tx_count_q),
        .numwords_q (numwords_q)
    );



    sbus_rcontroller sbus_rcontroller1 (
        // external input i/f
        .Sclk (Sclk),
        .Sreset (Sreset),
        .Srack (Srack),
        .Srstrobe (Srstrobe),
        .Srdata (Srdata),

        // internal input i/f
        .start (),  // from registers
        .numwords (numwords),
        .rrequest (start),
        .raddr (fetch_addr),

        // external output i/f
        .Srrequest (Srrequest),
        .Sraddr (Sraddr),

        // internal output i/f
        .pushin (sbus_pushin),
        .rdata (sbus_rdata),
        .incr_fetch_addr (incr_fetch_addr),
        .done (rdone)

    );




    sum16 sum16_1 (
        .clk (Sclk),
        .reset (Sreset),
        .A0 (A0),
        .B0 (B0),
        .A1 (A1),
        .B1 (B1),
        .A2 (A2),
        .B2 (B2),
        .A3 (A3),
        .B3 (B3),
        .pushin (sbus_pushin),

        .pushout (sum16_pushout),
        .Z (sum16_out)
    );

    // logic fifo_ready;




endmodule
