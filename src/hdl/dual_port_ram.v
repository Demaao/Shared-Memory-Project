`timescale 1ns/1ps
//
// Dual-Port RAM - for the shared-memory Butterfly network
//
module dual_port_ram #(
    parameter LOCAL_ADDR_WIDTH = 10,   // 2^10 = 1024 words inside one module
    parameter DATA_WIDTH       = 32
)(
    input  wire                           clk,

    // Port A  (forward path from the BN) 
    input  wire                           we_a,       // 1 = write
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_a,     // address inside this module
    input  wire [DATA_WIDTH-1:0]          wdata_a,    // data to write
    output reg  [DATA_WIDTH-1:0]          rdata_a,    // data read 

    // Port B  (backward path to the core) 
    input  wire                           we_b,       
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_b,
    input  wire [DATA_WIDTH-1:0]          wdata_b,
    output reg  [DATA_WIDTH-1:0]          rdata_b
);

    // Memory array: 1024 words × 32-bit
    reg [DATA_WIDTH-1:0] mem [0:(1<<LOCAL_ADDR_WIDTH)-1];

    
    //Write
    // Both ports can write in the same clock if they target different addresses
    always @(posedge clk) begin
        if (we_a) mem[addr_a] <= wdata_a;
        if (we_b) mem[addr_b] <= wdata_b;
    end

    // Read 
    // Data comes out one clock after the address is presented
    always @(posedge clk) begin
        rdata_a <= mem[addr_a];
        rdata_b <= mem[addr_b];
    end
endmodule
