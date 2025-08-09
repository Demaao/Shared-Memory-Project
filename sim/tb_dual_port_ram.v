`timescale 1ns/1ps

// Testbench for dual_port_ram
module tb_dual_port_ram;

  // 100 MHz clock, period = 10 ns
  reg clk = 0;
  always #5 clk = ~clk;

  // Signals for the two ports
  reg         we_a = 0,  we_b = 0;           // write enable for each port
  reg  [9:0]  addr_a = 0, addr_b = 0;        // LOCAL_ADDR_WIDTH = 10
  reg  [31:0] wdata_a = 0,  wdata_b = 0;     // data to write
  wire [31:0] rdata_a,   rdata_b;            // data read

 
  dual_port_ram #(
    .LOCAL_ADDR_WIDTH(10),
    .DATA_WIDTH(32)
  ) dut (
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
    // to avoid 'X' on first samples 
    repeat (2) @(posedge clk);

    // Test 1: write using A, read using B
    addr_b = 10'h03F;  we_b = 1'b0;
    @(posedge clk);

    addr_a  = 10'h03F; wdata_a = 32'hDEADBEEF; we_a = 1'b1;
    @(posedge clk);
    we_a    = 1'b0;

   
    @(posedge clk); #1;
    $display("T1: rdata_b = %h (expected DEADBEEF)", rdata_b);
    if (rdata_b !== 32'hDEADBEEF) begin
      $display("Test 1 fail");
      $fatal;
    end
    
    // Test 2: WRITE-FIRST - Port A writes while Port B reads same address
    addr_a  = 10'h040; wdata_a = 32'hA5A5_0001; we_a = 1'b1;
    addr_b  = 10'h040; we_b    = 1'b0;
    @(posedge clk); #1;  
    $display("T2: rdata_b = %h (expected A5A50001)", rdata_b);
    if (rdata_b !== 32'hA5A5_0001) begin
      $display("Test 2 fail,got %h", rdata_b);
      $fatal;
    end
    we_a = 1'b0;

   
    // Test 3: two writes to the same address (Port A wins)
    addr_a  = 10'h055; wdata_a = 32'hAAAA_5555; we_a = 1'b1;
    addr_b  = 10'h055; wdata_b = 32'hBBBB_5555; we_b = 1'b1;

    // Collision cycle
    @(posedge clk); #1;
    $display("T3(collision): rdata_a=%h rdata_b=%h (expected both AAAA5555)", rdata_a, rdata_b);
    if (rdata_a !== 32'hAAAA_5555 || rdata_b !== 32'hAAAA_5555) begin
      $display("Test 3 fail (collision forwarding)");
      $fatal;
    end

    // Disable writes, read back using B to confirm memory holds A's data
    we_a = 1'b0; we_b = 1'b0;
    addr_b = 10'h055; we_b = 1'b0;
    @(posedge clk);      // capture addr
    @(posedge clk); #1;  // registered read stable
    $display("T3(readback): rdata_b=%h (expected AAAA5555)", rdata_b);
    if (rdata_b !== 32'hAAAA_5555) begin
      $display("Test 3 fail (A should win on same-address), got %h", rdata_b);
      $fatal;
    end

    $display("All tests pass");
    #10 $finish;
  end

endmodule
