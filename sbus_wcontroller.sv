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

module sbus_wcontroller (
    // external input i/f
    input logic Sclk,
    input logic Sreset,
    input logic Swack,

    // internal input i/f
    input logic start,
    input logic wrequest,
    input logic [47:0] waddr,
    input logic [175:0] wdata,
    input logic [15:0] numwords,

    // external output i/f
    output logic Swrequest,
    output logic [47:0] Swaddr,
    output logic [175:0] Swdata,

    // internal output i/f
    output logic fifo_read,
    output logic incr_store_addr,
    output logic done
);
    

    typedef enum {
        IDLE,
        REQ,
        WAIT_ACK,
        WAIT_FILL,
        DONE
    } STATES_WCNTRL;

    STATES_WCNTRL PS, NS;

    logic wrequest_d;
    logic [47:0] waddr_d, waddr_q;
    logic [175:0] wdata_d, wdata_q;
    logic fifo_read_d;
    logic incr_store_addr_d;

    logic [15:0] tx_cnt_d, tx_cnt_q;
    logic [15:0] numwords_d, numwords_q;
    // logic [15:0] store_cnt_d, store_cnt_q;


    always @(*) begin
        NS = PS;
        wrequest_d = 0;
        waddr_d = waddr_q;
        wdata_d = wdata_q;
        fifo_read_d = 0;
        incr_store_addr_d = 0;
        tx_cnt_d = tx_cnt_q;
        done = 0;
        numwords_d = numwords_q;
        // store_cnt_d = store_cnt_q;
        case (PS)
            IDLE: begin
                tx_cnt_d = 0;
                                    numwords_d = numwords;

                if (!wrequest) begin
                    NS = IDLE;
                end
                else begin
                    fifo_read_d = 1;
                    NS = REQ;
                end
            end

            REQ: begin
                wrequest_d = 1;
                waddr_d = waddr;
                wdata_d = wdata;
                if (Swack) begin
                    tx_cnt_d += 1;
                    incr_store_addr_d = (tx_cnt_d >= numwords_q) ? 0 : 1;
                    // store_cnt_d = store_cnt_q + 1;
                    NS = (tx_cnt_d >= numwords_q) ? DONE : WAIT_FILL;

                end
                else NS = WAIT_ACK;
            end

            WAIT_ACK: begin
                wrequest_d = 1;
                if (Swack) begin
                    tx_cnt_d += 1;
                    incr_store_addr_d = (tx_cnt_d >= numwords_q) ? 0 : 1;
                    // store_cnt_d = store_cnt_q + 1;
                    NS = (tx_cnt_d >= numwords_q) ? DONE : WAIT_FILL;

                end
                else NS = WAIT_ACK;
            end

            WAIT_FILL: begin
                if (!wrequest) NS = WAIT_FILL;
                else begin
                    fifo_read_d = 1;
                    NS = REQ;
                end

            end

            DONE: begin
                done = 1;
                if (!start) NS = IDLE;
                else NS = DONE;
            end


        default: NS = IDLE;
        endcase
    end

    always @(posedge Sclk, posedge Sreset) begin
        if (Sreset) begin
            PS <= IDLE;
            waddr_q <= 0;
            wdata_q <= 0;
            // store_cnt_q <= 0;
            tx_cnt_q <= 0;
            numwords_q <= 0;
        end
        else begin
            PS <= NS;
            waddr_q <= waddr_d;
            wdata_q <= wdata_d;
            // store_cnt_q <= (!reset_cnt) ? store_cnt_d : 0;
            tx_cnt_q <= tx_cnt_d;
            numwords_q <= numwords_d;
        end

    end

    assign Swrequest = wrequest_d;
    assign Swaddr = waddr_d;
    assign Swdata = wdata_d;
    assign fifo_read = fifo_read_d;
    assign incr_store_addr = incr_store_addr_d;

endmodule