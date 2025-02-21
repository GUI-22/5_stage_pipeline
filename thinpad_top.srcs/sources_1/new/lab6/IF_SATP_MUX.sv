`include "./common_macros.svh"
`include "./exception_macros.svh"

module IF_SATP_MUX #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [`CSR_OP_WIDTH-1:0] ID_csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] ID_csr_addr_i,
    input wire [`DATA_WIDTH-1:0] ID_rs1_i,

    input wire [`CSR_OP_WIDTH-1:0] EXE_csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] EXE_csr_addr_i,
    input wire [`DATA_WIDTH-1:0] EXE_rs1_i,

    input wire [`CSR_OP_WIDTH-1:0] MEM_csr_op_i,
    input wire [`CSR_ADDR_WIDTH-1:0] MEM_csr_addr_i,
    input wire [`DATA_WIDTH-1:0] MEM_rs1_i,

    input satp_t current_satp_i,

    output satp_t satp_o
);

    logic [`MXLEN-1:0] satp_mem;
    logic [`MXLEN-1:0] satp_exe;
    logic [`MXLEN-1:0] satp_id;

    assign satp_o = satp_id;

    // forwards the satp value to the previous stages

    always_comb begin 
        if (MEM_csr_addr_i == `CSR_ADDR_SATP) begin
            case (MEM_csr_op_i)
                `CSR_OP_CSRRW: satp_mem = MEM_rs1_i;
                `CSR_OP_CSRRC: satp_mem = current_satp_i & (~MEM_rs1_i);
                `CSR_OP_CSRRS: satp_mem = current_satp_i | MEM_rs1_i;
                default: satp_mem = current_satp_i;
            endcase
        end
        else begin
            satp_mem = current_satp_i;
        end
    end

    always_comb begin
        if (EXE_csr_addr_i == `CSR_ADDR_SATP) begin
            case (EXE_csr_op_i)
                `CSR_OP_CSRRW: satp_exe = EXE_rs1_i;
                `CSR_OP_CSRRC: satp_exe = satp_mem & (~EXE_rs1_i);
                `CSR_OP_CSRRS: satp_exe = satp_mem | EXE_rs1_i;
                default: satp_exe = satp_mem;
            endcase
        end
        else begin
            satp_exe = satp_mem;
        end
    end

    always_comb begin
        if (ID_csr_addr_i == `CSR_ADDR_SATP) begin
            case (ID_csr_op_i)
                `CSR_OP_CSRRW: satp_id = ID_rs1_i;
                `CSR_OP_CSRRC: satp_id = satp_exe & (~ID_rs1_i);
                `CSR_OP_CSRRS: satp_id = satp_exe | ID_rs1_i;
                default: satp_id = satp_exe;
            endcase
        end
        else begin
            satp_id = satp_exe;
        end
    end

endmodule