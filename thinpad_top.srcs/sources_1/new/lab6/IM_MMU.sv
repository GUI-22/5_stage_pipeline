`include "common_macros.svh"
`include "exception_macros.svh"

module IM_MMU #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i,
    input wire rst_i,

    // Connect to IM
    input wire [ADDR_WIDTH-1:0] im_addr_i,
    input wire [DATA_WIDTH-1:0] im_data_i,
    output logic [DATA_WIDTH-1:0] im_data_o,
    input wire im_we_i,
    input wire [`SELECT_WIDTH-1:0] im_sel_i,
    input wire im_stb_i,
    output logic im_ack_o,
    input wire im_cyc_i,
    output logic im_err_o,

    // Connect to Arbiter
    output logic [ADDR_WIDTH-1:0] arb_addr_o,
    output logic [DATA_WIDTH-1:0] arb_data_o,
    input wire [DATA_WIDTH-1:0] arb_data_i,
    output logic arb_we_o,
    output logic [`SELECT_WIDTH-1:0] arb_sel_o,
    output logic arb_stb_o,
    input wire arb_ack_i,
    output logic arb_cyc_o,

    // Connect to EXPT_PROC
    input satp_t satp_i,
    input wire [`PRIVILEGE_WIDTH-1:0] privilege_i,

    // Connect to IM TLB
    output logic [`VPN_WIDTH-1:0] vpn_query_o,
    input wire [`PPN_WIDTH-1:0] ppn_query_i,
    input wire hit_query_i,

    output logic [`VPN_WIDTH-1:0] vpn_update_o,
    output logic [`PPN_WIDTH-1:0] ppn_update_o,
    output logic tlb_wen_o
);

    // state

    typedef enum logic [2:0] { 
        ST_IDLE,
        ST_READ_PT_1_ACTION,
        ST_READ_PT_2_ACTION,
        ST_ACTION,
        ST_DONE
    } state_t;
    state_t state;

    // internal signals

    wire [`VPN0_WIDTH-1:0] vpn0;
    wire [`VPN1_WIDTH-1:0] vpn1;
    wire [`VPO_WIDTH-1:0] vpo;
    wire [`VPN_WIDTH-1:0] vpn;

    assign vpn0 = im_addr_i[`VPN0_UPPER:`VPN0_LOWER];
    assign vpn1 = im_addr_i[`VPN1_UPPER:`VPN1_LOWER];
    assign vpo = im_addr_i[`VPO_UPPER:`VPO_LOWER];
    assign vpn = im_addr_i[`VPN_UPPER:`VPN_LOWER];

    wire [`PPN0_WIDTH-1:0] ppn0;
    wire [`PPN1_WIDTH-1:0] ppn1;
    wire [`PPN_WIDTH-1:0] ppn;
    wire pte_v;
    wire pte_r;
    wire pte_w;
    wire pte_x;
    wire pte_u;

    assign ppn0 = arb_data_i[`PPN0_UPPER:`PPN0_LOWER];
    assign ppn1 = arb_data_i[`PPN1_UPPER:`PPN1_LOWER];
    assign ppn = arb_data_i[`PPN_UPPER:`PPN_LOWER];
    assign pte_v = arb_data_i[0];
    assign pte_r = arb_data_i[1];
    assign pte_w = arb_data_i[2];
    assign pte_x = arb_data_i[3];
    assign pte_u = arb_data_i[4];

    logic request_we;
    logic request_privilege;

    // TLB related

    assign vpn_query_o = vpn;

    // state transfer

    assign arb_cyc_o = arb_stb_o;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            state <= ST_IDLE;
            
            im_data_o <= 0;
            im_ack_o <= 0;
            im_err_o <= 0;

            arb_addr_o <= 0;
            arb_data_o <= 0;
            arb_we_o <= 0;
            arb_sel_o <= 0;
            arb_stb_o <= 0;

            request_we <= 0;
            request_privilege <= 0;

            vpn_update_o <= 0;
            ppn_update_o <= 0;
            tlb_wen_o <= 0;
        end
        else begin
            case (state)
                ST_IDLE: begin
                    if (im_stb_i && im_cyc_i) begin
                        im_ack_o <= 0;
                        im_data_o <= 0;
                        im_err_o <= 0;

                        request_we <= im_we_i;
                        request_privilege <= privilege_i;

                        if (satp_i.mode == `SATP_MODE_SV32 && (privilege_i == `MODE_S || privilege_i == `MODE_U)) begin
                            // virtual memory
                            if (hit_query_i) begin
                                arb_addr_o <= {ppn_query_i, vpo};
                                arb_data_o <= im_data_i;
                                arb_we_o <= im_we_i;
                                arb_sel_o <= im_sel_i;
                                arb_stb_o <= 1;

                                state <= ST_ACTION;
                            end
                            else begin
                                arb_addr_o <= {satp_i.ppn[`PPN_WIDTH-3:0], vpn1, 2'b0}; // remove the first 2 bits of ppn
                                arb_data_o <= 0;
                                arb_we_o <= 0;
                                arb_sel_o <= 4'b1111;
                                arb_stb_o <= 1;

                                state <= ST_READ_PT_1_ACTION;
                            end
                        end
                        else begin
                            // no virtual memory
                            arb_addr_o <= im_addr_i;
                            arb_data_o <= im_data_i;
                            arb_we_o <= im_we_i;
                            arb_sel_o <= im_sel_i;
                            arb_stb_o <= 1;

                            state <= ST_ACTION;
                        end
                    end
                end
                ST_READ_PT_1_ACTION: begin
                    if (arb_ack_i) begin
                        if (pte_v == 0 || (pte_r == 0 && pte_w == 1)) begin
                            // page fault
                            im_data_o <= 0;
                            im_ack_o <= 1;
                            im_err_o <= 1;

                            arb_stb_o <= 0;

                            state <= ST_DONE;
                        end
                        else begin
                            arb_addr_o <= {ppn[`PPN_WIDTH-3:0], vpn0, 2'b0}; // remove the first 2 bits of ppn
                            arb_data_o <= 0;
                            arb_we_o <= 0;
                            arb_sel_o <= 4'b1111;
                            arb_stb_o <= 1;
                            
                            state <= ST_READ_PT_2_ACTION;
                        end
                    end
                end
                ST_READ_PT_2_ACTION: begin
                    if (arb_ack_i) begin
                        if (pte_v == 0 || (pte_r == 0 && pte_w == 1)) begin
                            // page fault
                            im_data_o <= 0;
                            im_ack_o <= 1;
                            im_err_o <= 1;

                            arb_stb_o <= 0;

                            state <= ST_DONE;
                        end
                        else if ((pte_u == 0 && request_privilege == `MODE_U) || (pte_x == 0)) begin
                            // page fault
                            im_data_o <= 0;
                            im_ack_o <= 1;
                            im_err_o <= 1;

                            arb_stb_o <= 0;

                            state <= ST_DONE;
                        end
                        else begin
                            arb_addr_o <= {ppn[`PPN_WIDTH-3:0], vpo}; // remove the first 2 bits of ppn
                            arb_data_o <= im_data_i;
                            arb_we_o <= im_we_i;
                            arb_sel_o <= im_sel_i;
                            arb_stb_o <= 1;

                            state <= ST_ACTION;

                            // update TLB

                            vpn_update_o <= vpn;
                            ppn_update_o <= ppn[`PPN_WIDTH-3:0];
                            tlb_wen_o <= 1;
                        end
                    end
                end
                ST_ACTION: begin
                    // update TLB end
                    vpn_update_o <= 0;
                    ppn_update_o <= 0;
                    tlb_wen_o <= 0;

                    if (arb_ack_i) begin
                        im_data_o <= arb_data_i;
                        im_ack_o <= 1;
                        im_err_o <= 0;

                        arb_stb_o <= 0;

                        state <= ST_DONE;
                    end
                end
                ST_DONE: begin
                    state <= ST_IDLE;
                    im_ack_o <= 0;
                    im_err_o <= 0;
                end
                default: begin
                    // never reach
                end
            endcase
        end
    end

endmodule
