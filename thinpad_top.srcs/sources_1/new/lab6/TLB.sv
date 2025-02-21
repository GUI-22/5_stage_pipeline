`include "./common_macros.svh"
`include "./exception_macros.svh"

module TLB #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i,
    input wire rst_i,

    input wire [`VPN_WIDTH-1:0] vpn_query_i,
    output logic [`PPN_WIDTH-1:0] ppn_query_o,
    output logic hit_query_o,

    input wire [`VPN_WIDTH-1:0] vpn_update_i,
    input wire [`PPN_WIDTH-1:0] ppn_update_i,
    input wire tlb_wen_i,

    input wire sfence_i
);

    tlb_t tlb_item;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            tlb_item.valid <= 0;
            tlb_item.vpn <= 0;
            tlb_item.ppn <= 0;
        end else begin
            if (sfence_i) begin
                tlb_item.valid <= 0;
                tlb_item.vpn <= 0;
                tlb_item.ppn <= 0;
            end 
            else if (tlb_wen_i) begin
                tlb_item.vpn <= vpn_update_i;
                tlb_item.ppn <= ppn_update_i;
                tlb_item.valid <= 1;
            end
        end
    end

    always_comb begin
        if (tlb_item.valid && tlb_item.vpn == vpn_query_i) begin
            hit_query_o = 1;
            ppn_query_o = tlb_item.ppn;
        end else begin
            hit_query_o = 0;
            ppn_query_o = 0;
        end
    end

endmodule