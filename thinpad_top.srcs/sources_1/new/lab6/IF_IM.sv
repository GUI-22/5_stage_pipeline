`include "./common_macros.svh"
`include "./exception_macros.svh"

`define uart_addr_rw 32'h10000000
`define uart_addr_check 32'h10000005
`define uart_sel_check 4'b0010
`define uart_sel_rw 4'b0001




module IF_IM #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i,
    input wire rst_i,

    input wire stall_im_i,

    input wire [ADDR_WIDTH-1:0] query_adr_i,
    output logic query_ack_o,
    output logic [DATA_WIDTH-1:0] query_data_o,

    output logic exception_flag_o,
    output logic [`EXCP_CODE_WIDTH-1:0] exception_code_o,
    output logic [`MXLEN-1:0] exception_val_o,

    output logic [ADDR_WIDTH-1:0]   wbm_adr_o,    
    output logic [DATA_WIDTH-1:0]   wbm_dat_m2s_o,    
    input wire [DATA_WIDTH-1:0]   wbm_dat_s2m_i,    
    output logic wbm_we_o,     
    output logic [`SELECT_WIDTH-1:0] wbm_sel_o,    
    output logic wbm_stb_o,    
    input wire wbm_ack_i,    
    output logic wbm_cyc_o,

    input wire wbm_err_i, // page fault response

    input wire exception_handled_i
);

    // state
    typedef enum logic [4:0] {
        ST_IDLE,
        ST_READ_ACTION,
        ST_DONE
    } state_t;
    state_t state;

    reg [DATA_WIDTH-1:0] wbm_dat;
    always_comb begin
        if (wbm_ack_i) begin
            wbm_dat = wbm_dat_s2m_i;
        end
    end

    assign wbm_cyc_o = wbm_stb_o;

    // page fault record

    logic page_fault_flag;

    // test cycle counting
    always_ff @(posedge clk_i or posedge rst_i) begin

        if (rst_i) begin
            // reset
            state <= ST_IDLE;
            query_ack_o <= 0;
            wbm_stb_o <= 0;
            wbm_we_o <= 0;
            wbm_sel_o <= 0;
            exception_flag_o <= 0;
            exception_code_o <= 0;
            exception_val_o <= 0;

            page_fault_flag <= 0;

        end else begin
            if (exception_handled_i) begin
                page_fault_flag <= 0;
                exception_flag_o <= 0;
            end

            case(state)
                ST_IDLE: begin
                    if (page_fault_flag == 1) begin
                        // do nothing, wait for exception handling
                        state <= ST_IDLE;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                    end
                    else begin
                        // read instr
                        if (query_adr_i[1:0] == 2'b0) begin // addr mod 4 = 0
                            state <= ST_READ_ACTION;
                            wbm_stb_o <= 1;
                            wbm_sel_o <= 4'b1111;
                            wbm_adr_o <= query_adr_i;
                            query_ack_o <= 0;
                            exception_flag_o <= 0;
                        end
                        else begin // excp: misaligned
                            state <= ST_DONE;
                            exception_flag_o <= 1;
                            exception_code_o <= `EXCP_INSTR_ADDR_MISALIGNED;
                            exception_val_o <= query_adr_i;
                            query_ack_o <= 1;
                            query_data_o <= `INSTR_NOP;
                        end
                    end
                end

                ST_READ_ACTION: begin
                    if (wbm_ack_i == 1 && wbm_err_i == 0) begin
                        state <= ST_DONE;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                        query_data_o <= wbm_dat; 
                    end
                    else if (wbm_ack_i == 1 && wbm_err_i == 1) begin
                        // page fault
                        state <= ST_DONE;
                        exception_flag_o <= 1;
                        exception_code_o <= `EXCP_INSTR_PAGE_FAULT;
                        exception_val_o <= query_adr_i;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                        query_data_o <= `INSTR_NOP;

                        page_fault_flag <= 1;
                    end
                end

                ST_DONE: begin
                    if (stall_im_i) begin
                        state <= ST_DONE;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                        query_data_o <= wbm_dat; 
                    end else begin
                        state <= ST_IDLE;
                        query_ack_o <= 0;
                        wbm_stb_o <= 0;
                    end
                    
                end

            endcase

        end

    end

endmodule