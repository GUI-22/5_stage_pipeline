`include "./common_macros.svh"
`include "./exception_macros.svh"

module IF_ID_REG #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk,
    input wire rst,

    input wire bubble_i,
    input wire stall_i,

    input wire [DATA_WIDTH-1:0] IF_instr_i,
    input wire [ADDR_WIDTH-1:0] IF_pc_i,

    input wire IF_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] IF_exception_code_i,
    input wire [`MXLEN-1:0] IF_exception_val_i,

    output logic [DATA_WIDTH-1:0] ID_instr_o,
    output logic [ADDR_WIDTH-1:0] ID_pc_o,

    output logic BEFORE_ID_exception_flag_o,
    output logic [`EXCP_CODE_WIDTH-1:0] BEFORE_ID_exception_code_o,
    output logic [`MXLEN-1:0] BEFORE_ID_exception_val_o

    
);
    always_ff @(posedge clk) begin
        if (rst) begin
            ID_pc_o <= `PC_NOP_ADDR;
            ID_instr_o <= `INSTR_NOP;
            BEFORE_ID_exception_flag_o <= 0;
            BEFORE_ID_exception_code_o <= 0;
            BEFORE_ID_exception_val_o <= 0;
        end
        else if (stall_i) begin
            // do nothing
        end
        else if (bubble_i) begin
            ID_pc_o <= `PC_NOP_ADDR;
            ID_instr_o <= `INSTR_NOP;
            BEFORE_ID_exception_flag_o <= 0;
            BEFORE_ID_exception_code_o <= 0;
            BEFORE_ID_exception_val_o <= 0;
        end
        else begin
            ID_pc_o <= IF_pc_i;
            ID_instr_o <= IF_instr_i;
            BEFORE_ID_exception_flag_o <= IF_exception_flag_i;
            BEFORE_ID_exception_code_o <= IF_exception_code_i;
            BEFORE_ID_exception_val_o <= IF_exception_val_i;
        end
    end
 
endmodule