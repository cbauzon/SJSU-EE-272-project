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

module registers (
    // external inputs
    input logic Rclk,
    input logic Rreset,
    input logic Rwrite,
    input logic Rxfr,
    input logic [11:0] Raddr,
    input logic [63:0] Rwdata,
    input logic RdevselX,

    //internal inputs
    input logic incr_fetch_addr,
    input logic incr_store_addr,
    input logic done,

    // external outputs
    output logic [63:0] Rrdata,

    // internal outputs
    output logic [47:0] fetch_addr,
    output logic [47:0] store_addr,
    output logic [15:0] numwords,
    output logic start

);

    typedef struct packed {
        logic [63:4] reserved;
        logic [3:1] fpriority;
        logic start;
    } Econtrol;

    typedef struct packed {
        logic [63:48] reserved;
        logic [47:0] fstartingaddr;
    } Efetchaddr;

    typedef struct packed {
        logic [63:16] reserved;
        logic [15:0] numwords;
    } Efetchlen;

    typedef struct packed {
        logic [63:48] reserved;
        logic [47:0] sstartingaddr;
    } Estoreaddr;

    typedef enum logic {
        IDLE,
        XFR
    } STATES;

    STATES PS, NS;

    logic [(2**12)-1:0][7:0] mem;
    Econtrol control_reg;
    Efetchaddr fetchaddr_reg;
    Efetchlen fetchlen_reg;
    Estoreaddr storeaddr_reg;


    
    always @(*) begin

        control_reg = mem[0+:8];

        fetchaddr_reg = mem[8+:8];

        fetchlen_reg = mem[16+:8];

        storeaddr_reg = mem[24+:8];

        fetch_addr = fetchaddr_reg.fstartingaddr;
        store_addr = storeaddr_reg.sstartingaddr;
        numwords = fetchlen_reg.numwords;
        start = control_reg.start;


        if (incr_fetch_addr) fetchaddr_reg.fstartingaddr += 16;    // only increment after a set of 16 bursts of 352 bits of data
        if (incr_store_addr) storeaddr_reg.sstartingaddr += 1;      // only increment after storing a set of 176 bits of data
        if (done) control_reg.start = 0;

        
    end

   // ------ FSM ------ //
    logic [63:0] rdata_d, rdata_q;
    assign Rrdata = rdata_d;

    // FSM combinatorial logic
    always @(*) begin
        NS = PS;
        rdata_d = rdata_q;
        case (PS)

            IDLE: begin
                if (RdevselX) NS = XFR;
                else NS = IDLE;

            end

            XFR: begin
                if (Rxfr) begin
                    if (Rwrite) begin
                        mem[Raddr+:8] = Rwdata;
                    end
                    else begin
                        rdata_d = mem[Raddr+:8];
                    end
                    NS = IDLE;
                end
                else NS = XFR;
            end

            default: NS = IDLE;
        endcase
    end

    // FSM sequential logic
    always @(posedge Rclk, posedge Rreset) begin
        if (Rreset) begin
            PS <= IDLE;
            rdata_q <= 0;
            mem <= 0;
        end
        else begin
            PS <= NS;
            rdata_q <= rdata_d;
        end

    end





endmodule
w