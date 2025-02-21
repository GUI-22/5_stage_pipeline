`include "./common_macros.svh"

module ID_MUX_A #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire [DATA_WIDTH-1:0] rf_data_a_i,
    input wire [ADDR_WIDTH-1:0] pc_i,
    input wire mux_a_choice_i,

    output logic [DATA_WIDTH-1:0] alu_oprand_a_o
);


    always_comb begin
        if (mux_a_choice_i == `MUX_A_CHOICE_RF_DATA_A) begin
            alu_oprand_a_o = rf_data_a_i;
        end else begin
            alu_oprand_a_o = pc_i;
        end
    end

endmodule