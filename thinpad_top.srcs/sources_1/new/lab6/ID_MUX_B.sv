`include "./common_macros.svh"

module ID_MUX_B #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [DATA_WIDTH-1:0] rf_data_b_i,
    input wire [DATA_WIDTH-1:0] imm_i,
    input wire mux_b_choice_i,

    output logic [DATA_WIDTH-1:0] alu_oprand_b_o
);

    always_comb begin
        if (mux_b_choice_i == `MUX_B_CHOICE_RF_DATA_B) begin
            alu_oprand_b_o = rf_data_b_i;
        end else begin
            alu_oprand_b_o = imm_i;
        end
    end

endmodule