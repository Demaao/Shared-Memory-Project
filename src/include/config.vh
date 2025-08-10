`ifndef SM_CONFIG_VH
`define SM_CONFIG_VH

// Width of the global address (32 bits)
`define ADDR_WIDTH       32

// Width of the data bus (can be changed )
`define DATA_WIDTH       32

// Set n = 2^K  (example: K=3 so we have 8 cores/modules)
`define K_LOG2           3

// Number of cores and memory modules (derived from K_LOG2)
`define N_CORES          (1 << `K_LOG2)
`define N_MODULES        (1 << `K_LOG2)

// Number of bits to identify a memory module
`define MOD_ID_BITS      (`K_LOG2)

// Width of the internal address inside a memory module (here 4096 cells)
`define LOCAL_ADDR_BITS  12

// Width of the priority field in the packet
`define PRI_BITS         4

`endif
