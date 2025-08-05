`timescale 1ns/1ps

//Test for dual_port_ram

module tb_dual_port_ram;

    //100 MHz clock, period = 10 ns 
    reg clk = 0;
    always #5 clk = ~clk;

    //Signals for the two ports 
    reg        we_a = 0,  we_b = 0;            // write-enable for each port
    reg [9:0]  addr_a = 0, addr_b = 0;         // LOCAL_ADDR_WIDTH = 10
    reg [31:0] wdata_a = 0,  wdata_b = 0;      // data to write
    wire [31:0] rdata_a,   rdata_b;            // data read

    // Test :
    dual_port_ram dut (
        .clk    (clk),

        // Port A (forward path)
        .we_a   (we_a),
        .addr_a (addr_a),
        .wdata_a(wdata_a),
        .rdata_a(rdata_a),

        // Port B (backward path)
        .we_b   (we_b),
        .addr_b (addr_b),
        .wdata_b(wdata_b),
        .rdata_b(rdata_b)
    );

    
    initial begin
        // Step 1: write through Port A
        addr_a  = 10'h03F;
        wdata_a = 32'hDEADBEEF;
        we_a    = 1'b1;
        #10;                 // wait one clock cycle
        we_a    = 1'b0;      // stop writing

        // Step 2: read the same address through Port B
        addr_b  = 10'h03F;   // we_b stays 0 (read)
        #10;                 // wait one cycle (rdata_b should update)
        $display("rdata_b = %h (expected DEADBEEF)", rdata_b);

        // Pass/fail check
        if (rdata_b == 32'hDEADBEEF)
            $display("TEST PASS");
        else begin
            $display("TEST FAIL");
            $fatal;
        end

        #10 $finish;
    end
endmodule
