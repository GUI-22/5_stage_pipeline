`include "./common_macros.svh"

module MEM_WB_REG #(
    parameter ADDR_width=32,
    parameter DATA_width=32
)
(
    input wire clk,
    input wire rst,

    input wire bubble_i,

    // MEM
    // to wb
    input wire [`REG_NUM_WIDTH-1:0] MEM_rf_waddr_i,
    input wire [DATA_width-1:0] MEM_rf_wdata_i,
    input wire MEM_rf_wen_i,
    input wire [ADDR_width-1:0] MEM_pc_i,

    // WB
    // to wb
    output logic [`REG_NUM_WIDTH-1:0] WB_rf_waddr_o,
    output logic [DATA_width-1:0] WB_rf_wdata_o,
    output logic WB_rf_wen_o,
    output logic [ADDR_width-1:0] WB_pc_o
);
    always_ff @(posedge clk) begin

        if (rst) begin
            // NOP
            WB_rf_waddr_o <= 0;
            WB_rf_wdata_o <= 0;
            WB_rf_wen_o <= 0;
            WB_pc_o <= `PC_NOP_ADDR;
        end

        else if (bubble_i) begin
            // NOP
            WB_rf_waddr_o <= 0;
            WB_rf_wdata_o <= 0;
            WB_rf_wen_o <= 0;
            WB_pc_o <= `PC_NOP_ADDR;
        end

        else begin
            WB_rf_waddr_o <= MEM_rf_waddr_i;
            WB_rf_wdata_o <= MEM_rf_wdata_i;
            WB_rf_wen_o <= MEM_rf_wen_i;
            WB_pc_o <= MEM_pc_i;
        end

    end
 
endmodule