// Connects to tb_core_req_loader (clk, rst, core_req_flat, core_req_vld, core_req_retry)
`timescale 1ns/1ps
`include "config.vh"
`include "types.vh"

module top (
    input  wire clk,
    input  wire rst,
    input  wire [`N_CORES*`CORE_REQ_W-1:0] core_req_flat, // Flattened request bus from TB
    input  wire [`N_CORES-1:0]             core_req_vld,  // Valid per core
    output reg  [`N_CORES-1:0]             core_req_retry // Retry back to TB
);

    localparam integer TOT_W = `CORE_REQ_W;

    // ---------------- Flattened field buses ----------------
    // Each bus is concatenation of all cores' fields, core 0 in LSB segment.
    wire [`N_CORES-1:0]                 req_rw_bus;        // 1 bit per core
    wire [`N_CORES*`ADDR_WIDTH-1:0]     req_addr_bus;      // ADDR_WIDTH per core
    wire [`N_CORES*`PRI_BITS-1:0]       req_pri_bus;       // PRI_BITS per core

    // Extract fields from the packed request for each core
    genvar f;
    generate
        for (f = 0; f < `N_CORES; f = f + 1) begin : EXTRACT
            wire [TOT_W-1:0] req_vec_f = core_req_flat[(f+1)*TOT_W-1 : f*TOT_W];

            assign req_rw_bus[f] = `CORE_REQ_RW(req_vec_f);

            assign req_addr_bus[(f+1)*`ADDR_WIDTH-1 : f*`ADDR_WIDTH]
                               = `CORE_REQ_ADDR(req_vec_f);

            assign req_pri_bus[(f+1)*`PRI_BITS-1 : f*`PRI_BITS]
                              = `CORE_REQ_PRIORITY(req_vec_f);
        end
    endgenerate

    // ---------------- Simple "hash" (placeholder) ----------------
    // Use LSBs of global address as module_id; low bits as local_addr.
    wire [`N_CORES*`MOD_ID_BITS-1:0]      module_id_bus;     // MOD_ID_BITS per core
    wire [`N_CORES*`LOCAL_ADDR_BITS-1:0]  local_addr_bus;    // LOCAL_ADDR_BITS per core

    genvar h;
    generate
        for (h = 0; h < `N_CORES; h = h + 1) begin : HASH
            wire [`ADDR_WIDTH-1:0] addr_h =
                req_addr_bus[(h+1)*`ADDR_WIDTH-1 : h*`ADDR_WIDTH];

            assign module_id_bus [(h+1)*`MOD_ID_BITS-1    : h*`MOD_ID_BITS]
                                 = addr_h[`MOD_ID_BITS-1:0];

            assign local_addr_bus[(h+1)*`LOCAL_ADDR_BITS-1: h*`LOCAL_ADDR_BITS]
                                 = addr_h[`LOCAL_ADDR_BITS-1:0];
        end
    endgenerate

    // ---------------- Helper: dynamic slice (Verilog-2001 safe) ----------------
    // Returns MOD_ID slice for core index i from flattened module_id_bus.
    function [`MOD_ID_BITS-1:0] get_mid_at;
        input [`N_CORES*`MOD_ID_BITS-1:0] bus;
        input integer i;
        reg   [`N_CORES*`MOD_ID_BITS-1:0] tmp;
    begin
        // Right-shift by i*MOD_ID_BITS, then take the low MOD_ID_BITS
        tmp       = bus >> (i*`MOD_ID_BITS);
        get_mid_at = tmp[`MOD_ID_BITS-1:0];
    end
    endfunction

    // ---------------- Simple per-module arbiter (demo instead of BN) ----------------
    // For each memory module, accept at most one requester per cycle: the first (lowest index) wins.
    // All other cores that target the same module get retry=1.
    integer c, m, winner;
    reg [`N_CORES-1:0] retry_next;

    always @(*) begin
        retry_next = {`N_CORES{1'b0}};

        for (m = 0; m < `N_MODULES; m = m + 1) begin
            winner = -1;

            for (c = 0; c < `N_CORES; c = c + 1) begin
                if (core_req_vld[c] &&
                    (get_mid_at(module_id_bus, c) == m[`MOD_ID_BITS-1:0])) begin
                    if (winner == -1)
                        winner = c;           // first requester wins (fixed priority)
                    else
                        retry_next[c] = 1'b1; // others must retry
                end
            end
        end
    end

    // ---------------- Register the retry output ----------------
    always @(posedge clk or posedge rst) begin
        if (rst)
            core_req_retry <= {`N_CORES{1'b0}};
        else
            core_req_retry <= retry_next;
    end

endmodule
