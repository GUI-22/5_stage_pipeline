`include "./common_macros.svh"
`include "./exception_macros.svh"

module EXE_MEM_REG #(
    parameter ADDR_width=32,
    parameter DATA_width=32
)
(
    input wire clk,
    input wire rst,

    input wire bubble_i,
    input wire stall_i,

    // interrupt
    input wire time_exceeded_i,

    // EXE

    // to mem (dm & mux_dm)
    input wire [DATA_width-1:0] EXE_alu_result_i,

    input wire EXE_query_wen_i,
    input wire EXE_query_ren_i,
    input wire [2:0] EXE_query_width_i,
    input wire EXE_query_sign_ext_i,
    input wire [DATA_width-1:0] EXE_query_data_m2s_i,
    input wire [`MUX_MEM_CHOICE_WIDTH-1:0] EXE_mux_mem_choice_i,

    input wire [`CSR_OP_WIDTH-1:0] EXE_csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] EXE_csr_addr_i,

    // to wb
    input wire [`REG_NUM_WIDTH-1:0] EXE_rf_waddr_i,
    input wire EXE_rf_wen_i,
    input wire [ADDR_width-1:0] EXE_pc_i,

    // excp
    input wire EXE_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] EXE_exception_code_i,
    input wire [`MXLEN-1:0] EXE_exception_val_i,

    // MEM

    // to mem (dm & mux_dm)
    output reg [DATA_width-1:0] MEM_alu_result_o,

    output reg MEM_query_wen_o,
    output reg MEM_query_ren_o,
    output reg [2:0] MEM_query_width_o,
    output reg MEM_query_sign_ext_o,
    output reg [DATA_width-1:0] MEM_query_data_m2s_o,
    output reg [`MUX_MEM_CHOICE_WIDTH-1:0] MEM_mux_mem_choice_o,

    output reg [`CSR_OP_WIDTH-1:0] MEM_csr_op_o,
    output reg [`CSR_ADDR_WIDTH-1:0] MEM_csr_addr_o,

    // to wb
    output reg [`REG_NUM_WIDTH-1:0] MEM_rf_waddr_o,
    output reg MEM_rf_wen_o,
    output reg [ADDR_width-1:0] MEM_pc_o,

    // excp
    output reg BEFORE_MEM_exception_flag_o,
    output reg [`EXCP_CODE_WIDTH-1:0] BEFORE_MEM_exception_code_o,
    output reg [`MXLEN-1:0] BEFORE_MEM_exception_val_o,

    // interrupt
    output reg interrupt_flag_o

);
    always_ff @(posedge clk) begin
        if (rst) begin
            // NOP
            MEM_alu_result_o <= 0;

            MEM_query_wen_o <= 0;
            MEM_query_ren_o <= 0;
            MEM_query_width_o <= 4;
            MEM_query_sign_ext_o <= `ZERO_EXT;
            MEM_query_data_m2s_o <= 0;
            MEM_mux_mem_choice_o <= `MUX_MEM_CHOICE_ALU_RST;

            MEM_csr_op_o <= `NO_CSR_OP;
            MEM_csr_addr_o <= 0;

            MEM_rf_waddr_o <= 0;
            MEM_rf_wen_o <= 0;
            MEM_pc_o <= `PC_NOP_ADDR;

            BEFORE_MEM_exception_flag_o <= 0;
            BEFORE_MEM_exception_code_o <= 0;
            BEFORE_MEM_exception_val_o <= 0;

            interrupt_flag_o <= 0;
        end
        else if (stall_i) begin
            // do nothing
            // don't modify interrupt_flag_o, because we cannot interrupt write or read MEM_DM
        end
        else if (bubble_i) begin
            // NOP
            MEM_alu_result_o <= 0;

            MEM_query_wen_o <= 0;
            MEM_query_ren_o <= 0;
            MEM_query_width_o <= 4;
            MEM_query_sign_ext_o <= `ZERO_EXT;
            MEM_query_data_m2s_o <= 0;
            MEM_mux_mem_choice_o <= `MUX_MEM_CHOICE_ALU_RST;

            MEM_csr_op_o <= `NO_CSR_OP;
            MEM_csr_addr_o <= 0;

            MEM_rf_waddr_o <= 0;
            MEM_rf_wen_o <= 0;
            MEM_pc_o <= `PC_NOP_ADDR;

            BEFORE_MEM_exception_flag_o <= 0;
            BEFORE_MEM_exception_code_o <= 0;
            BEFORE_MEM_exception_val_o <= 0;

            // the only condition which sets bubble_EXE_MEM_REG == 1 is that catch_from_processor == 1. But when catch == 1, in following cycle mode==M, mie==0, so in following cycle whether inter_flag_o==1 or inter_flag_o==0 both will not cause interrupt.
            // conculsion: when bubble_i==1, interrupt_flag_o be 1 or 0 both OK
            if (time_exceeded_i == 1) begin
                interrupt_flag_o <= 1;
            end
            else begin
                interrupt_flag_o <= 0;
            end
        end
        else begin
            MEM_alu_result_o <= EXE_alu_result_i;

            MEM_query_wen_o <= EXE_query_wen_i;
            MEM_query_ren_o <= EXE_query_ren_i;
            MEM_query_width_o <= EXE_query_width_i;
            MEM_query_sign_ext_o <= EXE_query_sign_ext_i;
            MEM_query_data_m2s_o <= EXE_query_data_m2s_i;
            MEM_mux_mem_choice_o <= EXE_mux_mem_choice_i;

            MEM_csr_op_o <= EXE_csr_op_i;
            MEM_csr_addr_o <= EXE_csr_addr_i;

            MEM_rf_waddr_o <= EXE_rf_waddr_i;
            MEM_rf_wen_o <= EXE_rf_wen_i;
            MEM_pc_o <= EXE_pc_i;

            BEFORE_MEM_exception_flag_o <= EXE_exception_flag_i;
            BEFORE_MEM_exception_code_o <= EXE_exception_code_i;
            BEFORE_MEM_exception_val_o <= EXE_exception_val_i;

            if (time_exceeded_i == 1) begin
                interrupt_flag_o <= 1;
            end
            else begin
                interrupt_flag_o <= 0;
            end
        end
    end
 
endmodule