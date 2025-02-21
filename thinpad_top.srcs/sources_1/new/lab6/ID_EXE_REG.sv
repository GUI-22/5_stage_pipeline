`include "./common_macros.svh"
`include "./exception_macros.svh"

module ID_EXE_REG #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk,
    input wire rst,

    input wire bubble_i,
    input wire stall_i,

    // ID
    // to exe (alu)
    input wire [DATA_WIDTH-1:0] ID_alu_oprand_a_i,
    input wire [DATA_WIDTH-1:0] ID_alu_oprand_b_i,
    input wire [`ALU_OPERATOR_WIDTH-1:0] ID_alu_op_i,

    // to mem (dm & mux_dm)
    input wire ID_query_wen_i,
    input wire ID_query_ren_i,
    input wire [2:0] ID_query_width_i,
    input wire ID_query_sign_ext_i,
    input wire [DATA_WIDTH-1:0] ID_query_data_m2s_i,
    input wire [`MUX_MEM_CHOICE_WIDTH-1:0] ID_mux_mem_choice_i,

    input wire [`CSR_OP_WIDTH-1:0] ID_csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] ID_csr_addr_i,

    // to wb
    input wire [`REG_NUM_WIDTH-1:0] ID_rf_waddr_i,
    input wire ID_rf_wen_i,
    input wire [ADDR_WIDTH-1:0] ID_pc_i,

    // excp
    input wire ID_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] ID_exception_code_i,
    input wire [`MXLEN-1:0] ID_exception_val_i,

    // EXE
    // to exe (alu)
    output reg [DATA_WIDTH-1:0] EXE_alu_oprand_a_o,
    output reg [DATA_WIDTH-1:0] EXE_alu_oprand_b_o,
    output reg [`ALU_OPERATOR_WIDTH-1:0] EXE_alu_op_o,

    // to mem (dm & mux_dm)
    output reg EXE_query_wen_o,
    output reg EXE_query_ren_o,
    output reg [2:0] EXE_query_width_o,
    output reg EXE_query_sign_ext_o,
    output reg [DATA_WIDTH-1:0] EXE_query_data_m2s_o,
    output reg [`MUX_MEM_CHOICE_WIDTH-1:0] EXE_mux_mem_choice_o,

    output reg [`CSR_OP_WIDTH-1:0] EXE_csr_op_o,
    output reg [`CSR_ADDR_WIDTH-1:0] EXE_csr_addr_o,

    // to wb
    output reg [`REG_NUM_WIDTH-1:0] EXE_rf_waddr_o,
    output reg EXE_rf_wen_o,
    output reg [ADDR_WIDTH-1:0] EXE_pc_o,

    // excp
    output reg BEFORE_EXE_exception_flag_o,
    output reg [`EXCP_CODE_WIDTH-1:0] BEFORE_EXE_exception_code_o,
    output reg [`MXLEN-1:0] BEFORE_EXE_exception_val_o
);
    always_ff @(posedge clk) begin
        if (rst) begin
            // NOP
            EXE_alu_oprand_a_o <= 0;
            EXE_alu_oprand_b_o <= 0;
            EXE_alu_op_o <= `ALU_ADD;

            EXE_query_wen_o <= 0;
            EXE_query_ren_o <= 0;
            EXE_query_width_o <= 4;
            EXE_query_sign_ext_o <= `ZERO_EXT;
            EXE_query_data_m2s_o <= 0;
            EXE_mux_mem_choice_o <= `MUX_MEM_CHOICE_ALU_RST;

            EXE_csr_op_o <= `NO_CSR_OP;
            EXE_csr_addr_o <= 0;

            EXE_rf_waddr_o <= 0;
            EXE_rf_wen_o <= 0;
            EXE_pc_o <= `PC_NOP_ADDR;

            BEFORE_EXE_exception_flag_o <= 0;
            BEFORE_EXE_exception_code_o <= 0;
            BEFORE_EXE_exception_val_o <= 0;
        end
        else if (stall_i) begin
            // do nothing
        end
        else if (bubble_i) begin
            // NOP
            EXE_alu_oprand_a_o <= 0;
            EXE_alu_oprand_b_o <= 0;
            EXE_alu_op_o <= `ALU_ADD;

            EXE_query_wen_o <= 0;
            EXE_query_ren_o <= 0;
            EXE_query_width_o <= 4;
            EXE_query_sign_ext_o <= `ZERO_EXT;
            EXE_query_data_m2s_o <= 0;
            EXE_mux_mem_choice_o <= `MUX_MEM_CHOICE_ALU_RST;

            EXE_csr_op_o <= `NO_CSR_OP;
            EXE_csr_addr_o <= 0;

            EXE_rf_waddr_o <= 0;
            EXE_rf_wen_o <= 0;
            EXE_pc_o <= `PC_NOP_ADDR;

            BEFORE_EXE_exception_flag_o <= 0;
            BEFORE_EXE_exception_code_o <= 0;
            BEFORE_EXE_exception_val_o <= 0;
        end
        else begin
            EXE_alu_oprand_a_o <= ID_alu_oprand_a_i;
            EXE_alu_oprand_b_o <= ID_alu_oprand_b_i;
            EXE_alu_op_o <= ID_alu_op_i;

            EXE_query_wen_o <= ID_query_wen_i;
            EXE_query_ren_o <= ID_query_ren_i;
            EXE_query_width_o <= ID_query_width_i;
            EXE_query_sign_ext_o <= ID_query_sign_ext_i;
            EXE_query_data_m2s_o <= ID_query_data_m2s_i;
            EXE_mux_mem_choice_o <= ID_mux_mem_choice_i;

            EXE_csr_op_o <= ID_csr_op_i;
            EXE_csr_addr_o <= ID_csr_addr_i;

            EXE_rf_waddr_o <= ID_rf_waddr_i;
            EXE_rf_wen_o <= ID_rf_wen_i;
            EXE_pc_o <= ID_pc_i;

            BEFORE_EXE_exception_flag_o <= ID_exception_flag_i;
            BEFORE_EXE_exception_code_o <= ID_exception_code_i;
            BEFORE_EXE_exception_val_o <= ID_exception_val_i;
        end
    end
 
endmodule