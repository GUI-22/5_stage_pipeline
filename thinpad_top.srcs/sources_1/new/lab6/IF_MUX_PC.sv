`include "./common_macros.svh"


module IF_MUX_PC #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire[ADDR_WIDTH-1:0] npc_from_calculator_i,
    input wire need_branch_i,
    input wire [`ADDR_WIDTH-1:0] npc_from_exception_processor_i,
    input wire catch_from_excp_processor_i,

    output logic[ADDR_WIDTH-1:0] npc_from_mux_pc_o,
    output logic pc_wrong_o
);
    always_comb begin
        if (catch_from_excp_processor_i) begin
            npc_from_mux_pc_o = npc_from_exception_processor_i;
            pc_wrong_o = 1;
        end
        else if (need_branch_i && pc_i != npc_from_calculator_i) begin
            // in this case, the pc of instr (which is after branch) is guessed wrong
            npc_from_mux_pc_o = npc_from_calculator_i;
            pc_wrong_o = 1;
        end
        else begin
            npc_from_mux_pc_o = pc_i + 4;
            pc_wrong_o = 0;
        end
    end
 
endmodule