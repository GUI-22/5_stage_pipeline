
`include "./common_macros.svh"

module IF_PC #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk, 
    input wire rst,
    input wire stall_pc_i,
    input wire[ADDR_WIDTH-1:0] npc_i,
    output reg[ADDR_WIDTH-1:0] pc_o
);
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_o <= `PC_ENTER_ADDR;
        end
        else if (stall_pc_i) begin
            // pc_o <= pc_o;
        end
        else begin
            pc_o <= npc_i;
        end
    end
 
endmodule