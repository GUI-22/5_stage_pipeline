`include "./common_macros.svh"
`include "./exception_macros.svh"


module CONTROLLER #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    // catch (excp or mret or interrupt)
    input wire catch_from_excp_processor_i,

    // check pc & im conflict
    input wire IF_im_query_ack_i,
    input wire IF_pc_wrong_i,

    // check data confilct
    input wire ID_mux_a_choice_i,
    input wire [`REG_NUM_WIDTH-1:0] ID_rf_addr_a_i,
    input wire ID_mux_b_choice_i,
    input wire [`REG_NUM_WIDTH-1:0] ID_rf_addr_b_i,

    input wire [`REG_NUM_WIDTH-1:0] EXE_rf_waddr_i,
    input wire EXE_rf_wen_i,
    input wire [`CSR_OP_WIDTH-1:0] EXE_csr_op_i,

    input wire [`REG_NUM_WIDTH-1:0] MEM_rf_waddr_i,
    input wire MEM_rf_wen_i,

    input wire [`REG_NUM_WIDTH-1:0] WB_rf_waddr_i,
    input wire WB_rf_wen_i,

    input wire [`INSTR_REPR_WIDTH-1:0] ID_instr_type_i,

    // dm caused conflict
    input wire MEM_query_ren_i,
    input wire MEM_query_wen_i,
    input wire MEM_dm_query_ack_i,
    input wire BEFORE_MEM_exception_flag_i,

    // outputs
    output logic bubble_PC_o,
    output logic stall_PC_o,

    output logic stall_IM_o,

    output logic bubble_IF_ID_REG_o,
    output logic stall_IF_ID_REG_o,

    output logic bubble_ID_EXE_REG_o,
    output logic stall_ID_EXE_REG_o,

    output logic bubble_EXE_MEM_REG_o,
    output logic stall_EXE_MEM_REG_o,

    output logic bubble_MEM_WB_REG_o,

    input wire EXE_query_ren_i
);

    logic dm_hazard;
    logic data_hazard;

    always_comb begin 
        dm_hazard = (MEM_query_ren_i == 1 || MEM_query_wen_i == 1) && (MEM_dm_query_ack_i == 0) && (BEFORE_MEM_exception_flag_i == 0);
        /*
        data_hazard = 
        (
            (
                (ID_mux_a_choice_i == `MUX_A_CHOICE_RF_DATA_A) && 
                (   (EXE_rf_waddr_i == ID_rf_addr_a_i[`REG_NUM_WIDTH-1:0] && EXE_rf_wen_i == 1) ||
                    (MEM_rf_waddr_i == ID_rf_addr_a_i[`REG_NUM_WIDTH-1:0] && MEM_rf_wen_i == 1) ||
                    (WB_rf_waddr_i == ID_rf_addr_a_i[`REG_NUM_WIDTH-1:0] && WB_rf_wen_i == 1)
                )
            )
            ||
            (
                (ID_mux_b_choice_i == `MUX_B_CHOICE_RF_DATA_B) && 
                (   (EXE_rf_waddr_i == ID_rf_addr_b_i[`REG_NUM_WIDTH-1:0] && EXE_rf_wen_i == 1) ||
                    (MEM_rf_waddr_i == ID_rf_addr_b_i[`REG_NUM_WIDTH-1:0] && MEM_rf_wen_i == 1) ||
                    (WB_rf_waddr_i == ID_rf_addr_b_i[`REG_NUM_WIDTH-1:0] && WB_rf_wen_i == 1)
                )
            )
        );
        */
        data_hazard = 
        (
            (
                (ID_mux_a_choice_i == `MUX_A_CHOICE_RF_DATA_A) && 
                (   
                    (EXE_rf_waddr_i == ID_rf_addr_a_i && EXE_rf_wen_i == 1) && 
                    (
                        EXE_query_ren_i ||
                        EXE_csr_op_i == `CSR_OP_CSRRC ||
                        EXE_csr_op_i == `CSR_OP_CSRRS ||
                        EXE_csr_op_i == `CSR_OP_CSRRW
                    )
                )
            )
            ||
            (
                (ID_mux_b_choice_i == `MUX_B_CHOICE_RF_DATA_B) && 
                (   
                    (EXE_rf_waddr_i == ID_rf_addr_b_i && EXE_rf_wen_i == 1) && 
                    (
                        EXE_query_ren_i ||
                        EXE_csr_op_i == `CSR_OP_CSRRC ||
                        EXE_csr_op_i == `CSR_OP_CSRRS ||
                        EXE_csr_op_i == `CSR_OP_CSRRW
                    )
                )
            )
        );
    end


    always_comb begin
        if (catch_from_excp_processor_i && IF_im_query_ack_i == 0) begin
            stall_EXE_MEM_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            stall_IF_ID_REG_o = 0;
            stall_IM_o = 0;
            stall_PC_o = 1;

            bubble_PC_o = 0;
            bubble_MEM_WB_REG_o = 1;
            bubble_IF_ID_REG_o = 1;
            bubble_ID_EXE_REG_o = 1;
            bubble_EXE_MEM_REG_o = 1;
        end

        else if (catch_from_excp_processor_i && IF_im_query_ack_i == 1) begin
            stall_EXE_MEM_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            stall_IF_ID_REG_o = 0;
            stall_IM_o = 0;
            stall_PC_o = 0;

            bubble_PC_o = 0;
            bubble_MEM_WB_REG_o = 1;
            bubble_IF_ID_REG_o = 1;
            bubble_ID_EXE_REG_o = 1;
            bubble_EXE_MEM_REG_o = 1;
        end
        
        else if (dm_hazard) begin
            stall_EXE_MEM_REG_o = 1;
            stall_ID_EXE_REG_o = 1;
            stall_IF_ID_REG_o = 1;
            stall_IM_o = 1;
            stall_PC_o = 1;

            bubble_MEM_WB_REG_o = 1;

            bubble_PC_o = 0;
            bubble_IF_ID_REG_o = 0;
            bubble_ID_EXE_REG_o = 0;
            bubble_EXE_MEM_REG_o = 0;
        end 

        else if (data_hazard) begin
            stall_IF_ID_REG_o = 1;
            stall_IM_o = 1;
            stall_PC_o = 1;

            bubble_ID_EXE_REG_o = 1;

            bubble_PC_o = 0;
            bubble_IF_ID_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            bubble_EXE_MEM_REG_o = 0;
            stall_EXE_MEM_REG_o = 0;
            bubble_MEM_WB_REG_o = 0;
        end

        else if (IF_pc_wrong_i == 1 && IF_im_query_ack_i == 0) begin
            stall_IF_ID_REG_o = 1;
            stall_PC_o = 1;

            bubble_ID_EXE_REG_o = 1;

            bubble_PC_o = 0;
            stall_IM_o = 0;
            bubble_IF_ID_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            bubble_EXE_MEM_REG_o = 0;
            stall_EXE_MEM_REG_o = 0;
            bubble_MEM_WB_REG_o = 0;
        end 

        else if (IF_pc_wrong_i == 1 && IF_im_query_ack_i == 1) begin
            bubble_IF_ID_REG_o = 1;

            bubble_PC_o = 0;
            stall_PC_o = 0;
            stall_IM_o = 0;
            stall_IF_ID_REG_o = 0;
            bubble_ID_EXE_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            bubble_EXE_MEM_REG_o = 0;
            stall_EXE_MEM_REG_o = 0;
            bubble_MEM_WB_REG_o = 0;
        end
        
        else if (IF_im_query_ack_i == 0) begin
            stall_PC_o = 1;
            bubble_IF_ID_REG_o = 1;

            bubble_PC_o = 0;
            stall_IM_o = 0;
            stall_IF_ID_REG_o = 0;
            bubble_ID_EXE_REG_o = 0;
            stall_ID_EXE_REG_o = 0;
            bubble_EXE_MEM_REG_o = 0;
            stall_EXE_MEM_REG_o = 0;
            bubble_MEM_WB_REG_o = 0;
        end
        
        else begin 
            bubble_PC_o = 0;
            stall_PC_o = 0;

            stall_IM_o = 0;

            bubble_IF_ID_REG_o = 0;
            stall_IF_ID_REG_o = 0;

            bubble_ID_EXE_REG_o = 0;
            stall_ID_EXE_REG_o = 0;

            bubble_EXE_MEM_REG_o = 0;
            stall_EXE_MEM_REG_o = 0;

            bubble_MEM_WB_REG_o = 0;
        end
        
    end

endmodule