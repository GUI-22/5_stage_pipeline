`include "./common_macros.svh"
`include "./exception_macros.svh"

module EXE_ALU (
    // 连接 ALU 模块的信号
    input wire  [`DATA_WIDTH-1:0] alu_a,
    input wire  [`DATA_WIDTH-1:0] alu_b,
    input wire  [`ALU_OPERATOR_WIDTH-1:0] alu_op,

    input wire EXE_query_wen_i,
    input wire EXE_query_ren_i,
    input wire [2:0] EXE_query_width_i,

    input wire BEFORE_EXE_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] BEFORE_EXE_exception_code_i,
    input wire [`MXLEN-1:0] BEFORE_EXE_exception_val_i,

    output reg [`DATA_WIDTH-1:0] alu_y,

    output reg EXE_exception_flag_o,
    output reg [`EXCP_CODE_WIDTH-1:0] EXE_exception_code_o,
    output reg [`MXLEN-1:0] EXE_exception_val_o
);

    logic signed [`DATA_WIDTH-1:0] alu_a_s;
    logic signed [`DATA_WIDTH-1:0] alu_b_s;

    assign alu_a_s = alu_a;
    assign alu_b_s = alu_b;

    always_comb begin
        if (BEFORE_EXE_exception_flag_i == 0) begin  // no excp before exe 
            casez (alu_op)
                `ALU_ADD: begin
                    alu_y = alu_a + alu_b;
                end 

                `ALU_SUB: begin
                    alu_y = alu_a - alu_b;
                end 

                `ALU_AND: begin
                    alu_y = alu_a & alu_b;
                end 

                `ALU_OR: begin
                    alu_y = alu_a | alu_b;
                end 

                `ALU_XOR: begin
                    alu_y = alu_a ^ alu_b;
                end 

                `ALU_NOT: begin
                    alu_y = ~alu_a;
                end 

                `ALU_SLL: begin
                    alu_y = alu_a << (alu_b & 32'h0000_00ff);
                end 

                `ALU_SRL: begin
                    alu_y = alu_a >> (alu_b & 32'h0000_00ff);
                end 

                `ALU_JAL: begin
                    alu_y = alu_a + 32'd4; // PC + 4
                end

                `ALU_MIN: begin
                    // this should be signed comparison
                    alu_y = (alu_a_s < alu_b_s) ? alu_a : alu_b;
                end

                `ALU_SBSET: begin
                    alu_y = alu_a | (32'h1 << (alu_b & 32'h0000_001f));
                end

                `ALU_ANDN: begin
                    alu_y = alu_a & ~(alu_b);
                end

                `ALU_SLTU: begin
                    alu_y = ($unsigned(alu_a) < $unsigned(alu_b)) ? 32'h1 : 32'h0;
                end

                default: begin
                    alu_y = 0;
                end
            endcase
        end

        else begin
            alu_y = 0;
        end

    end

    always_comb begin
        if (BEFORE_EXE_exception_flag_i == 0) begin  // no excp before exe 
            if (EXE_query_ren_i && EXE_query_width_i == 3'd4 && (alu_y[1:0] != 2'b0)) begin
                EXE_exception_flag_o = 1;
                EXE_exception_code_o = `EXCP_LOAD_ADDR_MISALIGNED;
                EXE_exception_val_o = alu_y;
            end
            if (EXE_query_wen_i && EXE_query_width_i == 3'd4 && (alu_y[1:0] != 2'b0)) begin
                EXE_exception_flag_o = 1;
                EXE_exception_code_o = `EXCP_STORE_ADDR_MISALIGNED;
                EXE_exception_val_o = alu_y;
            end
            else begin
                EXE_exception_flag_o = 0;
                EXE_exception_code_o = 0;
                EXE_exception_val_o = 0;
            end
        end

        else begin
            EXE_exception_flag_o = BEFORE_EXE_exception_flag_i;
            EXE_exception_code_o = BEFORE_EXE_exception_code_i;
            EXE_exception_val_o = BEFORE_EXE_exception_val_i;
        end
    end



endmodule