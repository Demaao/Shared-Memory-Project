`timescale 1ns/1ps


module addr_splitter #(
    parameter integer ADDR_WIDTH        = 32,   // width of global address
    parameter integer NUM_MODULES       = 8,    // number of banks (must be power of 2)
    parameter integer LOCAL_ADDR_WIDTH  = 10,   // address width inside each bank
    // Set MOD_ID_BITS = log2(NUM_MODULES) manually (e.g., 8 -> 3, 16 -> 4)
    parameter integer MOD_ID_BITS       = 3
)(
    input  wire [ADDR_WIDTH-1:0]              gaddr_in,   // global address
    input  wire [2:0]                         hash_sel,   // 0=identity, 1=reverse module_id, 2=rotate-left module_id
    output wire [MOD_ID_BITS-1:0]             module_id,  // selected bank
    output wire [LOCAL_ADDR_WIDTH-1:0]        local_addr  // address inside the bank
);

    // Optional sanity check (simulation-time only)
    initial begin
        if ((1 << MOD_ID_BITS) != NUM_MODULES) begin
            $display("WARNING(addr_splitter): MOD_ID_BITS (%0d) does not match NUM_MODULES=%0d (expect 2^MOD_ID_BITS).",
                     MOD_ID_BITS, NUM_MODULES);
        end
    end

    // Slice indices for module_id field within the global address
    localparam integer MOD_LSB = LOCAL_ADDR_WIDTH;
    localparam integer MOD_MSB = LOCAL_ADDR_WIDTH + MOD_ID_BITS - 1;

    // Extract original fields from the global address
    wire [MOD_ID_BITS-1:0]      mod_orig = gaddr_in[MOD_MSB:MOD_LSB];
    wire [LOCAL_ADDR_WIDTH-1:0] loc_orig = gaddr_in[LOCAL_ADDR_WIDTH-1:0];

    // Reverse bits (for module_id)
    function [MOD_ID_BITS-1:0] bit_reverse;
        input [MOD_ID_BITS-1:0] x;
        integer i;
        begin
            for (i = 0; i < MOD_ID_BITS; i = i + 1)
                bit_reverse[i] = x[MOD_ID_BITS-1-i];
        end
    endfunction

    // Rotate-left by 1 (for module_id)
    function [MOD_ID_BITS-1:0] rotate_left1;
        input [MOD_ID_BITS-1:0] x;
        begin
            if (MOD_ID_BITS > 1)
                rotate_left1 = {x[MOD_ID_BITS-2:0], x[MOD_ID_BITS-1]};
            else
                rotate_left1 = x; // width=1 edge case
        end
    endfunction

    // Choose transformed module_id based on hash_sel
    wire [MOD_ID_BITS-1:0] mod_transformed =
        (hash_sel == 3'd0) ? mod_orig :
        (hash_sel == 3'd1) ? bit_reverse(mod_orig) :
        (hash_sel == 3'd2) ? rotate_left1(mod_orig) :
                             mod_orig; // default

    // Outputs
    assign module_id  = mod_transformed;
    assign local_addr = loc_orig;

endmodule
