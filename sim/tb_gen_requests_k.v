// tb_gen_requests_k.v
`timescale 1ns/1ps
`include "config.vh"          // Global configuration macros

// Testbench module

module tb_gen_requests_k;
// Instantiate the DUT (Device Under Test)
    gen_requests_k uut();

    initial begin
        $display("=== Simulation started ===");
        #10; // Wait a short time just to let simulation progress
        $display("=== Simulation finished ===");
    end
endmodule