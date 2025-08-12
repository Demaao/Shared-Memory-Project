// tb_core_req_loader_retry.v  (Verilog-2001, no SystemVerilog)
`timescale 1ns/1ps
`include "../src/include/types.vh"

module tb_core_req_loader_retry;

  // Clock & reset
  reg clk = 1'b0;
  always #5 clk = ~clk;   // 100 MHz

  reg rst;
  initial begin
    rst = 1'b1;
    repeat (4) @(posedge clk);
    rst = 1'b0;
  end

  // Params / widths
  localparam integer K_REQ = `K_LOG2;
  localparam integer TOT_W = `CORE_REQ_W;

  // Request storage (flattened 1D: index = core*K_REQ + req)
  reg [TOT_W-1:0] req_mem [0:(`N_CORES*K_REQ)-1];

  // index helper
  function integer IDX;
    input integer c;
    input integer r;
    begin
      IDX = c*K_REQ + r;
    end
  endfunction

  // Per-core read pointer (use reg array for pure Verilog)
  reg [31:0] idx [0:`N_CORES-1];

  // DUT interface (flattened bus)
  reg  [`N_CORES*TOT_W-1:0] in_core_req_flat;
  reg  [`N_CORES-1:0]       in_vld;
  wire [`N_CORES-1:0]       retry;

  // temporaries for bitwise copy
  reg [TOT_W-1:0] req_word;
  integer b;

  // DUT
  top dut (
    .clk            (clk),
    .rst            (rst),
    .core_req_flat  (in_core_req_flat),
    .core_req_vld   (in_vld),
    .core_req_retry (retry)
  );

  // File loader
  integer fd;
  integer core_i, req_i;
  reg [TOT_W-1:0] packed;
  reg [8*256-1:0] fname;
  reg [1023:0]    dummy;
  integer header_lines;

  initial begin : LOAD_FILE
    $sformat(fname, "requests_K%0d.mem", `K_LOG2);
    fd = $fopen(fname, "r");
    if (fd == 0) begin
      $display("ERROR: cannot open %0s", fname);
      $finish;
    end

    // init memory and pointers
    for (core_i = 0; core_i < `N_CORES; core_i = core_i + 1) begin
      idx[core_i] = 0;
      for (req_i = 0; req_i < K_REQ; req_i = req_i + 1)
        req_mem[IDX(core_i, req_i)] = {TOT_W{1'b0}};
    end

    // skip 3 header lines
    for (header_lines = 0; header_lines < 3; header_lines = header_lines + 1)
      $fgets(dummy, fd);

    // read lines: "<core> <idx> <hex>"
    while (!$feof(fd)) begin
      if ($fscanf(fd, "%d %d %h", core_i, req_i, packed) == 3) begin
        if (core_i < `N_CORES && req_i < K_REQ)
          req_mem[IDX(core_i, req_i)] = packed;
      end else begin
        $fgets(dummy, fd);
      end
    end
    $fclose(fd);

    $display("Loaded %0d cores x %0d requests/core from %0s",
             `N_CORES, K_REQ, fname);
  end

  // Driver with retry handshake
  integer c;
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      in_vld <= {`N_CORES{1'b0}};
      for (c = 0; c < `N_CORES; c = c + 1) begin
        for (b = 0; b < TOT_W; b = b + 1)
          in_core_req_flat[c*TOT_W + b] <= 1'b0;
        idx[c] <= 0;
      end
    end else begin
      for (c = 0; c < `N_CORES; c = c + 1) begin
        if (idx[c] < K_REQ) begin
          packed  = req_mem[IDX(c, idx[c])];

          // use packed request word directly (avoids macro issues)
          req_word = packed;

          // copy word bits into the flat bus slice for core c
          for (b = 0; b < TOT_W; b = b + 1)
            in_core_req_flat[c*TOT_W + b] <= req_word[b];

          in_vld[c] <= 1'b1;

          if (retry[c] == 1'b0)
            idx[c] <= idx[c] + 1;   // advance only if not retried
        end else begin
          for (b = 0; b < TOT_W; b = b + 1)
            in_core_req_flat[c*TOT_W + b] <= 1'b0;
          in_vld[c] <= 1'b0;
        end
      end
    end
  end

  // Stop condition
  integer done_count;
  always @(posedge clk) begin
    done_count = 0;
    for (c = 0; c < `N_CORES; c = c + 1)
      if (idx[c] >= K_REQ) done_count = done_count + 1;

    if (done_count == `N_CORES) begin
      repeat (10) @(posedge clk);
      $display("All cores completed %0d requests with retry-handshake. Stopping.", K_REQ);
      $finish;
    end
  end

endmodule
