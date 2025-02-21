`include "./common_macros.svh"

`define MXLEN 32

// `define PC_EXCP_ADDR 32'h8888_0000

// privilege mode
`define PRIVILEGE_WIDTH 2
`define MODE_U `PRIVILEGE_WIDTH'd0
`define MODE_S `PRIVILEGE_WIDTH'd1
`define MODE_M `PRIVILEGE_WIDTH'd3

// CSR regs
`define CSR_ADDR_WIDTH 12
    // mtvec
`define CSR_ADDR_MTVEC `CSR_ADDR_WIDTH'h305
typedef struct packed {
    logic [`MXLEN-3:0] base;
    logic [1:0] mode;
} tvec_t;

    // mscratch
`define CSR_ADDR_MSCRATCH `CSR_ADDR_WIDTH'h340
typedef logic[`MXLEN-1:0] scratch_t;

    // mepc
`define CSR_ADDR_MEPC `CSR_ADDR_WIDTH'h341
typedef logic[`MXLEN-1:0] epc_t;

    // mcause
`define CSR_ADDR_MCAUSE `CSR_ADDR_WIDTH'h342
typedef struct packed {
    logic interrupt;
    logic [`MXLEN-2:0] exception_code;
} cause_t;

    // mstatus
`define CSR_ADDR_MSTATUS `CSR_ADDR_WIDTH'h300
typedef struct packed {
    logic sd;
    logic [7:0] wpri_0;
    logic tsr, tw, tvm, mxr, sum, mprv;
    logic [1:0] xs, fs, mpp, vs;
    logic spp, mpie, ube, spie, wpri_1, mie, wpri_2, sie, wpri_3;
} status_t;
// mpp == status[12:11]  mpie == status[7]  mie == status[3]

    // mie
`define CSR_ADDR_MIE `CSR_ADDR_WIDTH'h304
typedef struct packed {
    logic [`MXLEN-12:0] zero_0;
    logic meie, zero_1, seie, zero_2, mtie, zero_3, stie, zero_4, msie, zero_5, ssie, zero_6;
} ie_t;
// tie == ie[7]

    // mip
`define CSR_ADDR_MIP `CSR_ADDR_WIDTH'h344
typedef struct packed {
    logic [`MXLEN-12:0] zero_0;
    logic meip, zero_1, seip, zero_2, mtip, zero_3, stip, zero_4, msip, zero_5, ssip, zero_6;
} ip_t;
// tip == ip[7]

    // mtval
`define CSR_ADDR_MTVAL `CSR_ADDR_WIDTH'h343
typedef logic[`MXLEN-1:0] tval_t;


// CSR operation
`define CSR_OP_WIDTH 3

`define NO_CSR_OP `CSR_OP_WIDTH'd0
`define CSR_OP_CSRRC `CSR_OP_WIDTH'd6
`define CSR_OP_CSRRS `CSR_OP_WIDTH'd1
`define CSR_OP_CSRRW `CSR_OP_WIDTH'd2
`define CSR_OP_EBREAK `CSR_OP_WIDTH'd3
`define CSR_OP_ECALL `CSR_OP_WIDTH'd4
`define CSR_OP_MRET `CSR_OP_WIDTH'd5

// EXCEPTION KINDS (following excp codes are from mannul, please DO NOT MODIFIED THE NUMBERS) 
`define IS_EXCEPTION 1'b0
`define EXCP_CODE_WIDTH 4
    //IF
`define EXCP_INSTR_ADDR_MISALIGNED `EXCP_CODE_WIDTH'd0
`define EXCP_INSTR_ACCESS_FAULT `EXCP_CODE_WIDTH'd1
`define EXCP_INSTR_PAGE_FAULT `EXCP_CODE_WIDTH'd12
    //ID
`define EXCP_ILLEGAL_INSTR `EXCP_CODE_WIDTH'd2
`define EXCP_BREAKPOINT `EXCP_CODE_WIDTH'd3
`define EXCP_ECALL `EXCP_CODE_WIDTH'd10
`define EXCP_ECALL_U `EXCP_CODE_WIDTH'd8
`define EXCP_ECALL_S `EXCP_CODE_WIDTH'd9
`define EXCP_ECALL_M `EXCP_CODE_WIDTH'd11
    //EXE
`define EXCP_LOAD_ADDR_MISALIGNED `EXCP_CODE_WIDTH'd4
`define EXCP_STORE_ADDR_MISALIGNED `EXCP_CODE_WIDTH'd6
    //MEM
`define EXCP_LOAD_ACCESS_FAULT `EXCP_CODE_WIDTH'd5
`define EXCP_STORE_ACCESS_FAULT `EXCP_CODE_WIDTH'd7
`define EXCP_LOAD_PAGE_FAULT `EXCP_CODE_WIDTH'd13
`define EXCP_STORE_PAGE_FAULT `EXCP_CODE_WIDTH'd15


// MTIME & MTIMECMP
`define TIME_DATA_WIDTH 64
`define MTIME_ADDR_LOW `ADDR_WIDTH'h0200_bff8
`define MTIME_ADDR_HIGH `ADDR_WIDTH'h0200_bffc
`define MTIMECMP_ADDR_LOW `ADDR_WIDTH'h0200_4000
`define MTIMECMP_ADDR_HIGH `ADDR_WIDTH'h0200_4004


// INTERRUPT
`define IS_INTERRUPT 1'b1
`define INTER_CODE_WIDTH 4
`define INTER_M_TIMER `INTER_CODE_WIDTH'd7




