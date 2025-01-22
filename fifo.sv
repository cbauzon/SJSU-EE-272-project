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

module fifo (
    input clk,
    input reset,
    input push,
    input read,
    input [10:0] wdata,

    output logic [175:0] data,
    output logic ready
);

logic [4:0] fifo_cnt;
logic [15:0] [10:0] mem;
logic [3:0] wr_ptr;

always @(*) begin
    ready = (fifo_cnt == 16) ? 1 : 0;
    data = mem;     // asyn data out
end

always @(posedge clk, posedge reset) begin
    if (reset) begin
        mem <= 0;
        wr_ptr <= 0;
        fifo_cnt <= 0;
    end
    else begin
        // could potentially lose data
        if (push && !ready) begin
            mem[wr_ptr] <= wdata;
            wr_ptr <= (wr_ptr != 15) ? (wr_ptr + 1) : 0;
            fifo_cnt <= fifo_cnt + 1;
        end

        if (read && ready) begin
            fifo_cnt <= 0;
        end
    end
end

endmodule
