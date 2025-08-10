`ifndef SM_TYPES_VH
`define SM_TYPES_VH
`include "config.vh"


// Total width of a core request vector
`define CORE_REQ_W            (1 + `ADDR_WIDTH + `PRI_BITS)

// Bit positions 
`define CORE_PRI_LSB          0
`define CORE_PRI_MSB          (`CORE_PRI_LSB + `PRI_BITS - 1)

`define CORE_ADDR_LSB         (`CORE_PRI_MSB + 1)
`define CORE_ADDR_MSB         (`CORE_ADDR_LSB + `ADDR_WIDTH - 1)

`define CORE_RW_LSB           (`CORE_ADDR_MSB + 1)
`define CORE_RW_MSB           (`CORE_RW_LSB  + 1 - 1)   // single bit

// Access macros (x is a [CORE_REQ_W-1:0] vector)
`define CORE_REQ_PRIORITY(x)  (x[`CORE_PRI_MSB  : `CORE_PRI_LSB ])
`define CORE_REQ_ADDR(x)      (x[`CORE_ADDR_MSB : `CORE_ADDR_LSB])
`define CORE_REQ_RW(x)        (x[`CORE_RW_MSB   : `CORE_RW_LSB  ])


 // Packet (after hash) - flat bitvector (Verilog-2001)
 // Total width of a packet vector
`define PACKET_W              (1 + `MOD_ID_BITS + `LOCAL_ADDR_BITS + `PRI_BITS)

// Bit positions 
`define PKT_PRI_LSB           0
`define PKT_PRI_MSB           (`PKT_PRI_LSB + `PRI_BITS - 1)

`define PKT_LOCAL_LSB         (`PKT_PRI_MSB + 1)
`define PKT_LOCAL_MSB         (`PKT_LOCAL_LSB + `LOCAL_ADDR_BITS - 1)

`define PKT_MODID_LSB         (`PKT_LOCAL_MSB + 1)
`define PKT_MODID_MSB         (`PKT_MODID_LSB + `MOD_ID_BITS - 1)

`define PKT_RW_LSB            (`PKT_MODID_MSB + 1)
`define PKT_RW_MSB            (`PKT_RW_LSB + 1 - 1)      // single bit

// Access macros (p is a [PACKET_W-1:0] vector)
`define PKT_PRIORITY(p)       (p[`PKT_PRI_MSB   : `PKT_PRI_LSB  ])
`define PKT_LOCAL_ADDR(p)     (p[`PKT_LOCAL_MSB : `PKT_LOCAL_LSB])
`define PKT_MODULE_ID(p)      (p[`PKT_MODID_MSB : `PKT_MODID_LSB])
`define PKT_RW(p)             (p[`PKT_RW_MSB    : `PKT_RW_LSB   ])


// Build a core request vector from fields
// rw: 1 bit, addr: ADDR_WIDTH bits, pri: PRI_BITS bits
`define MAKE_CORE_REQ(rw, addr, pri) \
  { (rw[0]), (addr[`ADDR_WIDTH-1:0]), (pri[`PRI_BITS-1:0]) }

// Build a packet vector from fields

`define MAKE_PACKET(rw, mid, loc, pri) \
  { (rw[0]), (mid[`MOD_ID_BITS-1:0]), (loc[`LOCAL_ADDR_BITS-1:0]), (pri[`PRI_BITS-1:0]) }

`endif
