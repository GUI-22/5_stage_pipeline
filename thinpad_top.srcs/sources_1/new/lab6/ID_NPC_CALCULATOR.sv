`include "./common_macros.svh"

module ID_NPC_CALCULATOR #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [`INSTR_REPR_WIDTH-1:0] instr_type_i,
    input wire [DATA_WIDTH-1:0] rf_data_a_i,
    input wire [DATA_WIDTH-1:0] rf_data_b_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire [DATA_WIDTH-1:0] imm_offset_i,

    // npc_calculator --> mux_pc & controller
    output logic [ADDR_WIDTH-1:0] npc_from_calculator_o,
    output logic need_branch_o
);


    always_comb begin
        case (instr_type_i)

            // BEQ
            `INSTR_BEQ: begin
                if (rf_data_a_i == rf_data_b_i) begin
                    need_branch_o = 1;
                    npc_from_calculator_o = pc_i + imm_offset_i;
                end else begin
                    need_branch_o = 0;
                    npc_from_calculator_o = pc_i + 4;
                end
            end

            `INSTR_BNE: begin
                if (rf_data_a_i != rf_data_b_i) begin
                    need_branch_o = 1;
                    npc_from_calculator_o = pc_i + imm_offset_i;
                end else begin
                    need_branch_o = 0;
                    npc_from_calculator_o = pc_i + 4;
                end
            end

            `INSTR_JAL: begin
                need_branch_o = 1;
                npc_from_calculator_o = pc_i + imm_offset_i;
            end

            `INSTR_JALR: begin
                need_branch_o = 1;
                npc_from_calculator_o = (rf_data_b_i + imm_offset_i)&(~1);
            end

            // other instr don't need to branch
            default: begin
                need_branch_o = 0;
                npc_from_calculator_o = pc_i + 4;
            end


        endcase
    end

endmodule