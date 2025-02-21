`include "./common_macros.svh"
`include "./exception_macros.svh"

`define uart_addr_rw 32'h10000000
`define uart_addr_check 32'h10000005
`define uart_sel_check 4'b0010
`define uart_sel_rw 4'b0001


module MEM_DM #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i,
    input wire rst_i,

    input wire [2:0] query_width_i,
    input wire query_sign_ext_i,
    input wire [ADDR_WIDTH-1:0] query_adr_i,
    input wire [DATA_WIDTH-1:0] query_dat_i,
    input wire query_wen_i,
    input wire query_ren_i,

    input wire BEFORE_MEM_exception_flag_i,
    input wire [`EXCP_CODE_WIDTH-1:0] BEFORE_MEM_exception_code_i,
    input wire [`MXLEN-1:0] BEFORE_MEM_exception_val_i,

    input wire [`TIME_DATA_WIDTH-1:0] mtime_i,
    input wire [`TIME_DATA_WIDTH-1:0] mtimecmp_i,
    
    output logic query_ack_o,
    output logic [DATA_WIDTH-1:0] query_data_o,

    output logic MEM_exception_flag_o,
    output logic [`EXCP_CODE_WIDTH-1:0] MEM_exception_code_o,
    output logic [`MXLEN-1:0] MEM_exception_val_o,

    output logic [ADDR_WIDTH-1:0]   wbm_adr_o,    
    output logic [DATA_WIDTH-1:0]   wbm_dat_m2s_o,    
    input wire [DATA_WIDTH-1:0]   wbm_dat_s2m_i,    
    output logic wbm_we_o,     
    output logic [`SELECT_WIDTH-1:0] wbm_sel_o,    
    output logic wbm_stb_o,    
    input wire wbm_ack_i,    
    output logic wbm_cyc_o,

    input wire wbm_err_i // page fault response
);

    // state
    typedef enum logic [4:0] {
        ST_IDLE,
        ST_WRITE_ACTION,
        ST_READ_ACTION,
        ST_DONE
    } state_t;
    state_t state;

    assign wbm_cyc_o = wbm_stb_o;

    reg [DATA_WIDTH-1:0] wbm_dat;
    always_comb begin
        if (wbm_ack_i) begin
            wbm_dat = wbm_dat_s2m_i;
        end
    end

    // test cycle counting
    always_ff @(posedge clk_i or posedge rst_i) begin

        if (rst_i) begin
            // reset
            state <= ST_IDLE;
            query_ack_o <= 0;
            wbm_stb_o <= 0;
            wbm_we_o <= 0;
            wbm_sel_o <= 0;

            MEM_exception_flag_o <= 0;
            MEM_exception_code_o <= 0;
            MEM_exception_val_o <= 0;

        end else begin

            case(state)
                ST_IDLE: begin
                    if (BEFORE_MEM_exception_flag_i == 1) begin // excp
                        state <= ST_IDLE;
                        MEM_exception_flag_o <= BEFORE_MEM_exception_flag_i;
                        MEM_exception_code_o <= BEFORE_MEM_exception_code_i;
                        MEM_exception_val_o <= BEFORE_MEM_exception_val_i;
                    end

                    else begin // no excp before MEM
                        MEM_exception_flag_o <= 0;
                        MEM_exception_code_o <= 0;
                        MEM_exception_val_o <= 0;

                        if (query_wen_i == 1) begin
                            // write
                            if (
                                query_adr_i == `MTIME_ADDR_LOW || 
                                query_adr_i == `MTIME_ADDR_HIGH ||
                                query_adr_i == `MTIMECMP_ADDR_LOW ||
                                query_adr_i == `MTIMECMP_ADDR_HIGH
                            ) begin
                                state <= ST_DONE;
                                query_ack_o <= 1;
                            end
                            else begin
                                state <= ST_WRITE_ACTION;
                                wbm_stb_o <= 1;
                                wbm_we_o <= 1;
                                if (query_width_i == 1) begin
                                    //wbm_sel_o <= 4'b0001;
                                    case(query_adr_i[1:0])
                                        2'b00: wbm_sel_o <= 4'b0001;
                                        2'b01: wbm_sel_o <= 4'b0010;
                                        2'b10: wbm_sel_o <= 4'b0100;
                                        2'b11: wbm_sel_o <= 4'b1000;
                                    endcase
                                end else if (query_width_i == 2) begin
                                    wbm_sel_o <= 4'b0011;
                                end else if (query_width_i == 3) begin
                                    wbm_sel_o <= 4'b0111;
                                end else begin
                                    wbm_sel_o <= 4'b1111;
                                end
                                wbm_dat_m2s_o <= query_dat_i << (query_adr_i[1:0] * 8);
                                wbm_adr_o <= query_adr_i;
                                query_ack_o <= 0;
                            end
                            

                        end else if (query_ren_i == 1) begin
                            // read
                            if (
                                query_adr_i == `MTIME_ADDR_LOW || 
                                query_adr_i == `MTIME_ADDR_HIGH ||
                                query_adr_i == `MTIMECMP_ADDR_LOW ||
                                query_adr_i == `MTIMECMP_ADDR_HIGH
                            ) begin
                                state <= ST_DONE;
                                query_ack_o <= 1;
                                case (query_adr_i) 
                                    `MTIME_ADDR_LOW: begin
                                        query_data_o <= mtime_i[31:0];
                                    end
                                    `MTIME_ADDR_HIGH: begin
                                        query_data_o <= mtime_i[63:32];
                                    end
                                    `MTIMECMP_ADDR_LOW: begin
                                        query_data_o <= mtimecmp_i[31:0];
                                    end
                                    `MTIMECMP_ADDR_HIGH: begin
                                        query_data_o <= mtimecmp_i[63:32];
                                    end
                                    default: begin
                                        // never reach here
                                    end
                                endcase
                            end
                            else begin
                                state <= ST_READ_ACTION;
                                wbm_stb_o <= 1;
                                wbm_we_o <= 0;
                                if (query_width_i == 1) begin
                                    case(query_adr_i[1:0])
                                        2'b00: wbm_sel_o <= 4'b0001;
                                        2'b01: wbm_sel_o <= 4'b0010;
                                        2'b10: wbm_sel_o <= 4'b0100;
                                        2'b11: wbm_sel_o <= 4'b1000;
                                    endcase
                                end else if (query_width_i == 2) begin
                                    wbm_sel_o <= 4'b0011;
                                end else if (query_width_i == 3) begin
                                    wbm_sel_o <= 4'b0111;
                                end else begin
                                    wbm_sel_o <= 4'b1111;
                                end
                                wbm_adr_o <= query_adr_i;
                                query_ack_o <= 0;
                            end

                        end else begin
                            // no mmu query
                            state <= ST_IDLE;
                        end
                    end
                end

                ST_WRITE_ACTION: begin
                    if (wbm_ack_i == 1 && wbm_err_i == 0) begin
                        state <= ST_DONE;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                        wbm_we_o <= 0;
                    end
                    else if (wbm_ack_i == 1 && wbm_err_i == 1) begin
                        // page fault
                        state <= ST_DONE;
                        MEM_exception_flag_o <= 1;
                        MEM_exception_code_o <= `EXCP_STORE_PAGE_FAULT;
                        MEM_exception_val_o <= query_adr_i;
                        query_ack_o <= 1;

                        wbm_stb_o <= 0;
                        wbm_we_o <= 0;
                    end
                end

                ST_READ_ACTION: begin
                    if (wbm_ack_i == 1 && wbm_err_i == 0) begin
                        state <= ST_DONE;
                        query_ack_o <= 1;
                        wbm_stb_o <= 0;
                        wbm_we_o <= 0;
                        if (query_sign_ext_i == `ZERO_EXT) begin
                            if (query_width_i == 1) begin
                                //query_data_o <= {24'b0, wbm_dat[7:0]}; 
                                case(query_adr_i[1:0])
                                    2'b00: query_data_o <= {24'b0, wbm_dat[7:0]};
                                    2'b01: query_data_o <= {24'b0, wbm_dat[15:8]};
                                    2'b10: query_data_o <= {24'b0, wbm_dat[23:16]};
                                    2'b11: query_data_o <= {24'b0, wbm_dat[31:24]};
                                endcase
                            end else if (query_width_i == 2) begin
                                query_data_o <= {16'b0, wbm_dat[15:0]};
                            end else if (query_width_i == 3) begin
                                query_data_o <= {8'b0, wbm_dat[23:0]}; 
                            end else begin
                                query_data_o <= wbm_dat; 
                            end
                        end else begin
                            if (query_width_i == 1) begin
                                //query_data_o <= {{24{wbm_dat[7]}}, wbm_dat[7:0]}; 
                                case(query_adr_i[1:0])
                                    2'b00: query_data_o <= {{24{wbm_dat[7]}}, wbm_dat[7:0]};
                                    2'b01: query_data_o <= {{24{wbm_dat[15]}}, wbm_dat[15:8]};
                                    2'b10: query_data_o <= {{24{wbm_dat[23]}}, wbm_dat[23:16]};
                                    2'b11: query_data_o <= {{24{wbm_dat[31]}}, wbm_dat[31:24]};
                                endcase
                            end else if (query_width_i == 2) begin
                                query_data_o <= {{16{wbm_dat[15]}}, wbm_dat[15:0]}; 
                            end else if (query_width_i == 3) begin
                                query_data_o <= {{8{wbm_dat[23]}}, wbm_dat[23:0]}; 
                            end else begin
                                query_data_o <= wbm_dat; 
                            end
                        end
                    end
                    else if (wbm_ack_i == 1 && wbm_err_i == 1) begin
                        // page fault
                        state <= ST_DONE;
                        MEM_exception_flag_o <= 1;
                        MEM_exception_code_o <= `EXCP_LOAD_PAGE_FAULT;
                        MEM_exception_val_o <= query_adr_i;
                        query_ack_o <= 1;
                        query_data_o <= 0;

                        wbm_stb_o <= 0;
                        wbm_we_o <= 0;
                    end
                end

                ST_DONE: begin
                    state <= ST_IDLE;
                    query_ack_o <= 0;
                    wbm_stb_o <= 0;
                end

            endcase

        end

    end

endmodule