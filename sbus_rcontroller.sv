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

module sbus_rcontroller (
    // external input i/f
    input logic Sclk,
    input logic Sreset,
    input logic Srack,
    input logic Srstrobe,
    input logic [351:0] Srdata,

    // internal input i/f
    input logic start,  // from registers
    input logic [15:0] numwords,
    input logic rrequest,
    input logic [47:0] raddr,

    // external output i/f
    output logic Srrequest,
    output logic [47:0] Sraddr,

    // internal output i/f
    output logic pushin,
    output logic [351:0] rdata,
    output logic incr_fetch_addr,
    output logic done


);

    typedef enum {
        IDLE,
        REQ,
        WAIT_STROBE,
        FETCH
    } STATES_RCNTRL;

    STATES_RCNTRL NS, PS;

    logic rrequest_d;
    logic [47:0] raddr_d, raddr_q;
    logic pushin_d;
    logic [351:0] rdata_d, rdata_q;
    logic incr_fetch_addr_d;
    logic [15:0] rx_cnt_d, rx_cnt_q;
    logic [15:0] numwords_d, numwords_q;

    assign Srrequest = rrequest_d;
    assign Sraddr = raddr_d;
    assign pushin = pushin_d;
    assign rdata = rdata_d;
    assign incr_fetch_addr = incr_fetch_addr_d;

    assign done = (rx_cnt_q >= numwords_q);

    always @(*) begin
        rrequest_d = 0;
        raddr_d = raddr_q;
        pushin_d = 0;
        rdata_d = rdata_q;
        incr_fetch_addr_d = 0;
        rx_cnt_d = rx_cnt_q;
        numwords_d = numwords_q;

        case (PS)
            IDLE: begin
                rx_cnt_d = 0;
                if (rrequest) begin
                    numwords_d = numwords;
                    NS = REQ;
                end
                else NS = IDLE;
            end

            REQ: begin
                rrequest_d = 1;
                raddr_d = raddr;
                if (!Srack) NS = REQ;
                else NS = WAIT_STROBE;
            end

            WAIT_STROBE: begin
                if (!Srstrobe) NS = WAIT_STROBE;
                else begin
                    pushin_d = 1;
                    rdata_d = Srdata;
                    rx_cnt_d += 1;
                    NS = FETCH;
                end
            end

            FETCH: begin
                if (Srstrobe) begin
                    pushin_d = 1;
                    rdata_d = Srdata;
                    rx_cnt_d += 1;
                    NS = FETCH;
                end
                else begin
                    incr_fetch_addr_d = (rx_cnt_q >= numwords_q) ? 0 : 1;
                    NS = (rx_cnt_q >= numwords_q) ? IDLE : REQ;
                end

            end

        default: NS = IDLE;
        endcase
    end

    always @(posedge Sclk, posedge Sreset) begin
        if (Sreset) begin
            PS <= IDLE;
            raddr_q <= 0;
            rdata_q <= 0;
            rx_cnt_q <= 0;
            numwords_q <= 0;
        end
        else begin
            PS <= NS;
            raddr_q <= raddr_d;
            rdata_q <= rdata_d;
            rx_cnt_q <= rx_cnt_d;
            numwords_q <= numwords_d;
        end
    end

endmodule
