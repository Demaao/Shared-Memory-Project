`timescale 1ns/1ps
//
// Dual-Port RAM - מתאים ל-Shared-Memory Butterfly
//
module dual_port_ram #(
    parameter LOCAL_ADDR_WIDTH = 10,      // 2^10 = 1024 תאים במודול
    parameter DATA_WIDTH       = 32
)(
    input  wire                           clk,

    // ── Port A ── (כניסה מה-BN - "forward")
    input  wire                           we_a,
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_a,
    input  wire [DATA_WIDTH-1:0]          wdata_a,
    output reg  [DATA_WIDTH-1:0]          rdata_a,

    // ── Port B ── (החזרה ל-core - "backward")
    input  wire                           we_b,
    input  wire [LOCAL_ADDR_WIDTH-1:0]    addr_b,
    input  wire [DATA_WIDTH-1:0]          wdata_b,
    output reg  [DATA_WIDTH-1:0]          rdata_b
);
    // מערך הזיכרון - תא אחד של 32-ביט × 1024
    reg [DATA_WIDTH-1:0] mem [0:(1<<LOCAL_ADDR_WIDTH)-1];

    // כתיבה: שני הפורטים יכולים לכתוב באותו מחזור (לכתובות שונות)
    always @(posedge clk) begin
        if (we_a) mem[addr_a] <= wdata_a;
        if (we_b) mem[addr_b] <= wdata_b;
    end

    // קריאה: הערך חוזר מחזור-אחד אחרי הצגת הכתובת
    always @(posedge clk) begin
        rdata_a <= mem[addr_a];
        rdata_b <= mem[addr_b];
    end
endmodule
