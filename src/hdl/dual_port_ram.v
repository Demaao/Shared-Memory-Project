`timescale 1ns/1ps

// Dual Port RAM 
// Two writes to the same address in the same cycle: Port A wins
// Two reads to the same address: always allowed 



module dual_port_ram #(
    parameter LOCAL_ADDR_WIDTH = 10,   
    parameter DATA_WIDTH       = 32
)(
    input  wire                           clk,

    // Port A (forward path from the BN)
    input  wire                           we_a,       // 1 = write
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_a,     // address inside this module
    input  wire [DATA_WIDTH-1:0]          wdata_a,    // data to write
    output reg  [DATA_WIDTH-1:0]          rdata_a,    // registered read data

    // Port B (backward path to the core)
    input  wire                           we_b,      
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_b,
    input  wire [DATA_WIDTH-1:0]          wdata_b,
    output reg  [DATA_WIDTH-1:0]          rdata_b
);

    // Memory array: depth x DATA_WIDTH
    reg [DATA_WIDTH-1:0] mem [0:(1<<LOCAL_ADDR_WIDTH)-1];

    
    // Writes
    // Both ports may write in the same clock cycle if they target different addresses
    // On same address,Port A wins (Port B is masked)
   
    always @(posedge clk) begin
        if (we_a)
            mem[addr_a] <= wdata_a;

        // Port B writes only if there is no same address collision with Port A
        if (we_b && !(we_a && (addr_b == addr_a)))
            mem[addr_b] <= wdata_b;
    end

    
    // Reads 
    // If a write happens in the same cycle to the read address, forward the NEW data.
   
    always @(posedge clk) begin
        // Default registered reads from memory
        rdata_a <= mem[addr_a];
        rdata_b <= mem[addr_b];

        // Self-port forwarding (WRITE-FIRST)
        if (we_a)
         rdata_a <= wdata_a;  // Port A sees its new data
        if (we_b) 
        rdata_b <= wdata_b;  // Port B sees its new data

        // Cross-port forwarding on same-address read during other port's write
        if (we_a && (addr_a == addr_b))
         rdata_b <= wdata_a; // B reads while A writes same addr
        if (we_b && (addr_b == addr_a))
         rdata_a <= wdata_b; // A reads while B writes same addr

        // If both ports write to same address : Port A wins
        if (we_a && we_b && (addr_a == addr_b)) begin
            rdata_a <= wdata_a;
            rdata_b <= wdata_a;
        end
    end

endmodule
