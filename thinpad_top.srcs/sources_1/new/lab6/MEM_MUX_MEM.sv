`include "./common_macros.svh"
`include "./exception_macros.svh"

module MEM_MUX_MEM #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [DATA_WIDTH-1:0] alu_rst_i,
    input wire [DATA_WIDTH-1:0] mem_data_i,
    input wire [`MXLEN-1:0] csr_data_i,
    input wire [`MUX_MEM_CHOICE_WIDTH-1:0] mux_mem_choice_i,

    output logic [DATA_WIDTH-1:0] rf_wdata_o
);

    always_comb begin
        if (mux_mem_choice_i == `MUX_MEM_CHOICE_ALU_RST) begin
            rf_wdata_o = alu_rst_i;
        end 
        else if (mux_mem_choice_i == `MUX_MEM_CHOICE_CSR_DATA) begin
            rf_wdata_o = csr_data_i;
        end
        else begin
            rf_wdata_o = mem_data_i;
        end
    end

endmodule