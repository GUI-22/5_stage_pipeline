`include "./common_macros.svh"
`include "./exception_macros.svh"

module ID_DECODER #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [DATA_WIDTH-1:0] instr_i,

    input wire BEFORE_ID_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] BEFORE_ID_exception_code_i,
    input wire [`MXLEN-1:0] BEFORE_ID_exception_val_i,

    // decoder --> rf & mux_a & mux_b & npc_calculator
    output logic [`INSTR_REPR_WIDTH-1:0] instr_type_o,
    output logic [`REG_NUM_WIDTH-1:0] rf_addr_a_o,
    output logic [`REG_NUM_WIDTH-1:0] rf_addr_b_o,
    output logic [DATA_WIDTH-1:0] imm_o,
    output logic mux_a_choice_o,
    output logic mux_b_choice_o,

    output logic ID_exception_flag_o,
    output logic [`EXCP_CODE_WIDTH-1:0] ID_exception_code_o,
    output logic [`MXLEN-1:0] ID_exception_val_o,

    // decoder --> alu
    output logic [`ALU_OPERATOR_WIDTH-1:0] alu_op_o,


    // decoder --> mem_dm & mux_dm
    output logic query_wen_o,
    output logic query_ren_o,
    output logic [2:0] query_width_o,
    output logic query_sign_ext_o,
    output logic [`MUX_MEM_CHOICE_WIDTH-1:0] mux_mem_choice_o,

    output logic [`CSR_OP_WIDTH-1:0] csr_op_o,
    output logic [`CSR_ADDR_WIDTH-1:0] csr_addr_o,

    // decoder --> WB
    output logic [`REG_NUM_WIDTH-1:0] rf_waddr_o,
    output logic rf_wen_o,

    // docoder --> TLB
    output logic sfence_o
);

    logic [6:0] op_code;
    logic [2:0] mid_op_code;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [6:0] funct7;
    logic [`CSR_ADDR_WIDTH-1:0] csr_addr;

    assign op_code = instr_i[6:0];
    assign rs1 = instr_i[19:15];
    assign rs2 = instr_i[24:20];
    assign rd = instr_i[11:7];
    assign mid_op_code = instr_i[14:12];
    assign funct7 = instr_i[31:25];
    assign csr_addr = instr_i[31:20];

    always_comb begin
        if (BEFORE_ID_exception_flag_i == 0) begin // no excp before ID
            case (op_code)
                // LUI
                7'b0110111: begin
                    instr_type_o = `INSTR_LUI;
                    rf_addr_a_o = 0;
                    rf_addr_b_o = 0;
                    imm_o = {instr_i[31:12], {12{1'b0}}};
                    mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                    mux_b_choice_o = `MUX_B_CHOICE_IMM;
                    
                    alu_op_o = `ALU_ADD;
                    
                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = rd;
                    rf_wen_o = 1;

                    ID_exception_flag_o = 0;
                    ID_exception_code_o = 0;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

                // BEQ & BNE
                7'b1100011: begin
                    if (mid_op_code == 3'b000) begin 
                        // BEQ
                        instr_type_o = `INSTR_BEQ;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8] ,{1{1'b0}}};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        // alu_op_o = ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_wen_o = 0;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else begin 
                        // BNE
                        instr_type_o = `INSTR_BNE;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8] ,{1{1'b0}}};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;

                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_wen_o = 0;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                end


                // LB & LW
                7'b0000011: begin
                    if (mid_op_code == 3'b000) begin
                        instr_type_o = `INSTR_LB;
                        rf_addr_a_o = rs1;
                        // rf_addr_b_o = rs2;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 1;
                        query_width_o = 1;
                        query_sign_ext_o = `SIGN_EXT;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_DM;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else begin
                        // LW
                        instr_type_o = `INSTR_LW;
                        rf_addr_a_o = rs1;
                        // rf_addr_b_o = rs2;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;

                        alu_op_o = `ALU_ADD;

                        query_wen_o = 0;
                        query_ren_o = 1;
                        query_width_o = 4;
                        query_sign_ext_o = `SIGN_EXT;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_DM;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                end

                // s-type instr
                7'b0100011: begin
                    // SB
                    if (mid_op_code == 3'b000) begin
                        instr_type_o = `INSTR_SB;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 1;
                        query_ren_o = 0;
                        query_width_o = 1;
                        // query_sign_ext_o = SIGN_EXT;
                        // mux_mem_choice_o = MUX_MEM_CHOICE_DM;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        // rf_waddr_o = rd;
                        rf_wen_o = 0;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else begin
                        // SW
                        instr_type_o = `INSTR_SW;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 1;
                        query_ren_o = 0;
                        query_width_o = 4;
                        // query_sign_ext_o = SIGN_EXT;
                        // mux_mem_choice_o = MUX_MEM_CHOICE_DM;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        // rf_waddr_o = rd;
                        rf_wen_o = 0;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                end

                // ADDI & ANDI & ORI & SLLI & SRLI
                7'b0010011: begin
                    if (mid_op_code == 3'b000) begin
                        // ADDI
                        instr_type_o = `INSTR_ADDI;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else if (mid_op_code == 3'b111) begin
                        // ANDI
                        instr_type_o = `INSTR_ANDI;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_AND;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else if (mid_op_code == 3'b110) begin
                        // ORI
                        instr_type_o = `INSTR_ORI;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;
                        
                        alu_op_o = `ALU_OR;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else if (mid_op_code==3'b001) begin 
                        // SLLI
                        instr_type_o = `INSTR_SLLI;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;

                        alu_op_o = `ALU_SLL;

                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else begin 
                        // SRLI
                        instr_type_o = `INSTR_SRLI;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_IMM;

                        alu_op_o = `ALU_SRL;

                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                end


                // ADD & AND & OR & XOR & MIN & SBSET & ANDN & SLTU
                7'b0110011: begin
                    if (mid_op_code == 3'b000) begin
                        // ADD
                        instr_type_o = `INSTR_ADD;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = 32'b0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else if (mid_op_code == 3'b111) begin
                        if (funct7 == 7'd0) begin 
                            // AND
                            instr_type_o = `INSTR_AND;
                            rf_addr_a_o = rs1;
                            rf_addr_b_o = rs2;
                            imm_o = 32'b0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                            
                            alu_op_o = `ALU_AND;
                            
                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `NO_CSR_OP;
                            csr_addr_o = 0;

                            rf_waddr_o = rd;
                            rf_wen_o = 1;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 0;
                        end else begin 
                            // ANDN
                            instr_type_o = `INSTR_ANDN;
                            rf_addr_a_o = rs1;
                            rf_addr_b_o = rs2;
                            imm_o = 32'b0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                            
                            alu_op_o = `ALU_ANDN;
                            
                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `NO_CSR_OP;
                            csr_addr_o = 0;

                            rf_waddr_o = rd;
                            rf_wen_o = 1;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 0;
                        end
                    end else if (mid_op_code == 3'b110) begin 
                        // OR
                        instr_type_o = `INSTR_OR;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = 32'b0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        alu_op_o = `ALU_OR;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end else if (mid_op_code == 3'b100) begin 
                        if (funct7 == 7'd0) begin
                            // XOR
                            instr_type_o = `INSTR_XOR;
                            rf_addr_a_o = rs1;
                            rf_addr_b_o = rs2;
                            imm_o = 32'b0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                            
                            alu_op_o = `ALU_XOR;
                            
                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `NO_CSR_OP;
                            csr_addr_o = 0;

                            rf_waddr_o = rd;
                            rf_wen_o = 1;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 0;
                        end else begin 
                            // MIN
                            instr_type_o = `INSTR_MIN;
                            rf_addr_a_o = rs1;
                            rf_addr_b_o = rs2;
                            imm_o = 32'b0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                            
                            alu_op_o = `ALU_MIN;
                            
                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `NO_CSR_OP;
                            csr_addr_o = 0;

                            rf_waddr_o = rd;
                            rf_wen_o = 1;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 0;
                        end
                    end 
                    else if (mid_op_code == 3'b001) begin 
                        // SBSET -> 001
                        instr_type_o = `INSTR_SBSET;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = 32'b0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;

                        alu_op_o = `ALU_SBSET;

                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                    else begin
                        // SLTU -> 011
                        instr_type_o = `INSTR_SLTU;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = rs2;
                        imm_o = 32'b0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;

                        alu_op_o = `ALU_SLTU;

                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                        csr_op_o = `NO_CSR_OP;
                        csr_addr_o = 0;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                end

                // AUIPC
                7'b0010111: begin 
                    instr_type_o = `INSTR_AUIPC;
                    rf_addr_a_o = 0;
                    rf_addr_b_o = 0;
                    mux_a_choice_o = `MUX_A_CHOICE_PC;
                    mux_b_choice_o = `MUX_B_CHOICE_IMM;

                    imm_o = {instr_i[31:12], {12{1'b0}}};

                    alu_op_o = `ALU_ADD;

                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = rd;
                    rf_wen_o = 1;

                    ID_exception_flag_o = 0;
                    ID_exception_code_o = 0;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

                // JAL
                7'b1101111: begin
                    instr_type_o = `INSTR_JAL;
                    rf_addr_a_o = 0; // pc
                    rf_addr_b_o = 0; // imm
                    imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};
                    mux_a_choice_o = `MUX_A_CHOICE_PC;
                    mux_b_choice_o = `MUX_B_CHOICE_IMM;
                    
                    alu_op_o = `ALU_JAL;
                    
                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = rd;
                    rf_wen_o = 1;

                    ID_exception_flag_o = 0;
                    ID_exception_code_o = 0;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

                // JALR
                7'b1100111: begin
                    instr_type_o = `INSTR_JALR;
                    rf_addr_a_o = 0;
                    rf_addr_b_o = rs1;
                    imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                    mux_a_choice_o = `MUX_A_CHOICE_PC;
                    mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                    
                    alu_op_o = `ALU_JAL;
                    
                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = rd;
                    rf_wen_o = 1;

                    ID_exception_flag_o = 0;
                    ID_exception_code_o = 0;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

                // CSRR or SFENCE.VMA
                7'b1110011: begin
                    if (mid_op_code == 3'b001) begin
                        // CSRRW
                        instr_type_o = `INSTR_CSRRW;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = 0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_CSR_DATA;
                        csr_op_o = `CSR_OP_CSRRW;
                        csr_addr_o = csr_addr;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                    else if (mid_op_code == 3'b010) begin
                        // CSRRS
                        instr_type_o = `INSTR_CSRRS;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = 0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_CSR_DATA;
                        csr_op_o = `CSR_OP_CSRRS;
                        csr_addr_o = csr_addr;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                    else if (mid_op_code == 3'b011) begin
                        // CSRRC
                        instr_type_o = `INSTR_CSRRC;
                        rf_addr_a_o = rs1;
                        rf_addr_b_o = 0;
                        imm_o = 0;
                        mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                        mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                        
                        alu_op_o = `ALU_ADD;
                        
                        query_wen_o = 0;
                        query_ren_o = 0;
                        mux_mem_choice_o = `MUX_MEM_CHOICE_CSR_DATA;
                        csr_op_o = `CSR_OP_CSRRC;
                        csr_addr_o = csr_addr;

                        rf_waddr_o = rd;
                        rf_wen_o = 1;

                        ID_exception_flag_o = 0;
                        ID_exception_code_o = 0;
                        ID_exception_val_o = 0;

                        sfence_o = 0;
                    end
                    else begin
                        // ECALL & EBREAK & MRET & SFENCE.VMA -> 3'b000
                        if (funct7 == 7'b00110_00) begin
                            // MRET
                            instr_type_o = `INSTR_MRET;
                            rf_addr_a_o = 0;
                            rf_addr_b_o = 0;
                            imm_o = 0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                            
                            alu_op_o = `ALU_ADD;
                            
                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `CSR_OP_MRET;
                            csr_addr_o = 0;

                            rf_waddr_o = 0;
                            rf_wen_o = 0;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 0;
                        end
                        else if (funct7 == 7'b0001001) begin
                            // SFENCE.VMA
                            instr_type_o = `INSTR_ADD;
                            rf_addr_a_o = 0;
                            rf_addr_b_o = 0;
                            
                            imm_o = 0;
                            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;

                            alu_op_o = `ALU_ADD;

                            query_wen_o = 0;
                            query_ren_o = 0;
                            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                            csr_op_o = `NO_CSR_OP;
                            csr_addr_o = 0;

                            rf_waddr_o = 0;
                            rf_wen_o = 0;

                            ID_exception_flag_o = 0;
                            ID_exception_code_o = 0;
                            ID_exception_val_o = 0;

                            sfence_o = 1;
                        end
                        else begin
                            // ECALL & EBREAK
                            if (instr_i[20] == 1'b1) begin
                                // EBREAK
                                instr_type_o = `INSTR_EBREAK;
                                rf_addr_a_o = 0;
                                rf_addr_b_o = 0;
                                imm_o = 0;
                                mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                                mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                                
                                alu_op_o = `ALU_ADD;
                                
                                query_wen_o = 0;
                                query_ren_o = 0;
                                mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                                csr_op_o = `CSR_OP_EBREAK;
                                csr_addr_o = 0;

                                rf_waddr_o = 0;
                                rf_wen_o = 0;

                                ID_exception_flag_o = 1;
                                ID_exception_code_o = `EXCP_BREAKPOINT;
                                ID_exception_val_o = 0;

                                sfence_o = 0;
                            end
                            else begin
                                // ECALL
                                instr_type_o = `INSTR_ECALL;
                                rf_addr_a_o = 0;
                                rf_addr_b_o = 0;
                                imm_o = 0;
                                mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                                mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                                
                                alu_op_o = `ALU_ADD;
                                
                                query_wen_o = 0;
                                query_ren_o = 0;
                                mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                                csr_op_o = `CSR_OP_ECALL;
                                csr_addr_o = 0;

                                rf_waddr_o = 0;
                                rf_wen_o = 0;

                                ID_exception_flag_o = 1;
                                ID_exception_code_o = `EXCP_ECALL;
                                ID_exception_val_o = 0;

                                sfence_o = 0;
                            end
                        end
                    end
                end

                // fence.i support
                7'b0001111: begin
                    // we take that all instr with 0001111 are fence.i
                    // op it like ADD instr
                    instr_type_o = `INSTR_ADD;
                    rf_addr_a_o = 0;
                    rf_addr_b_o = 0;
                    mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                    mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;

                    alu_op_o = `ALU_ADD;

                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = 0;
                    rf_wen_o = 0;

                    ID_exception_flag_o = 0;
                    ID_exception_code_o = 0;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

                // illegal instr
                default: begin
                    instr_type_o = `INSTR_ADD;
                    rf_addr_a_o = 0;
                    rf_addr_b_o = 0;
                    // imm_o = 32'b0;
                    mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
                    mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
                    
                    alu_op_o = `ALU_ADD;
                    
                    query_wen_o = 0;
                    query_ren_o = 0;
                    mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
                    csr_op_o = `NO_CSR_OP;
                    csr_addr_o = 0;

                    rf_waddr_o = 0;
                    rf_wen_o = 0;

                    ID_exception_flag_o = 1;
                    ID_exception_code_o = `EXCP_ILLEGAL_INSTR;
                    ID_exception_val_o = 0;

                    sfence_o = 0;
                end

            endcase
        end

        else begin // excp before ID occur
            instr_type_o = `INSTR_ADD;
            rf_addr_a_o = 0;
            rf_addr_b_o = 0;
            // imm_o = 32'b0;
            mux_a_choice_o = `MUX_A_CHOICE_RF_DATA_A;
            mux_b_choice_o = `MUX_B_CHOICE_RF_DATA_B;
            
            alu_op_o = `ALU_ADD;
            
            query_wen_o = 0;
            query_ren_o = 0;
            mux_mem_choice_o = `MUX_MEM_CHOICE_ALU_RST;
            csr_op_o = `NO_CSR_OP;
            csr_addr_o = 0;

            rf_waddr_o = 0;
            rf_wen_o = 0;

            ID_exception_flag_o = 1;
            ID_exception_code_o = BEFORE_ID_exception_code_i;
            ID_exception_val_o = BEFORE_ID_exception_val_i;

            sfence_o = 0;
        end
    end

endmodule