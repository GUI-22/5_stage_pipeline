module sram_controller #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,

    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 32,

    localparam SRAM_BYTES = SRAM_DATA_WIDTH / 8,
    localparam SRAM_BYTE_WIDTH = $clog2(SRAM_BYTES)
) (
    // clk and reset
    input wire clk_i,
    input wire rst_i,

    // wishbone slave interface
    input wire wb_cyc_i,
    input wire wb_stb_i,
    output reg wb_ack_o,
    input wire [ADDR_WIDTH-1:0] wb_adr_i,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH/8-1:0] wb_sel_i,
    input wire wb_we_i,

    // sram interface
    output reg [SRAM_ADDR_WIDTH-1:0] sram_addr,
    inout wire [SRAM_DATA_WIDTH-1:0] sram_data,
    output reg sram_ce_n,
    output reg sram_oe_n,
    output reg sram_we_n,
    output reg [SRAM_BYTES-1:0] sram_be_n
);

    wire [31:0] sram_data_i_comb;
    
    reg [31:0] sram_data_o_reg;
    reg sram_data_t_reg;
    reg sram_ce_n_reg;
    reg sram_oe_n_reg;
    reg sram_we_n_reg;
    reg wb_ack_o_reg;

    assign sram_data = sram_data_t_reg ? 32'bz : sram_data_o_reg;
    assign sram_data_i_comb = sram_data;

    // initial begin
    //     sram_ce_n_reg = 1'b1;
    //     sram_oe_n_reg = 1'b1;
    //     sram_we_n_reg = 1'b1;
    //     wb_ack_o_reg = 0;
    // end

    typedef enum logic [2:0] {
        STATE_IDLE = 0,
        STATE_READ = 1,
        STATE_READ_2 = 2,
        STATE_WRITE = 3,
        STATE_WRITE_2 = 4,
        STATE_WRITE_3 = 5,
        STATE_DONE = 6
    } state_t;
    state_t state;

    always_ff @ (posedge clk_i, posedge rst_i) begin
        if (rst_i) begin
            // high-Z when reset
            sram_data_t_reg <= 1'b1;
            sram_data_o_reg <= 32'b0;
            sram_ce_n_reg <= 1'b1;
            sram_oe_n_reg <= 1'b1;
            sram_we_n_reg <= 1'b1;
            sram_be_n <= 0;
            wb_ack_o_reg <= 0;
            wb_dat_o <= 0;
            state <= STATE_IDLE;
        end else begin
            case(state)
              STATE_IDLE: begin
                if (wb_stb_i && wb_cyc_i) begin
                    if (wb_we_i) begin
                        // write
                        sram_data_t_reg <= 1'b0;
                        sram_data_o_reg <= wb_dat_i;
                        sram_ce_n_reg <= 0;
                        sram_oe_n_reg <= 1;
                        sram_we_n_reg <= 1;
                        sram_addr <= wb_adr_i / 4;
                        sram_be_n <= ~wb_sel_i;
                        state <= STATE_WRITE;
                    end else begin
                        // read
                        sram_data_t_reg <= 1'b1;
                        sram_ce_n_reg <= 0;
                        sram_oe_n_reg <= 0;
                        sram_we_n_reg <= 1;
                        sram_addr <= wb_adr_i / 4;
                        sram_be_n <= 0;
                        state <= STATE_READ;
                    end
                end
              end

              STATE_READ: begin
                state <= STATE_READ_2;
              end

              STATE_READ_2: begin
                wb_dat_o <= sram_data_i_comb;
                wb_ack_o_reg <= 1;
                sram_ce_n_reg <= 1;
                sram_oe_n_reg <= 1;
                state <= STATE_DONE;
              end


              STATE_WRITE: begin
                sram_we_n_reg <= 0;
                state <= STATE_WRITE_2;
              end


              STATE_WRITE_2: begin
                sram_we_n_reg <= 1;
                state <= STATE_WRITE_3;
              end

              STATE_WRITE_3: begin
                wb_ack_o_reg <= 1;
                sram_ce_n_reg <= 1;
                state <= STATE_DONE;
              end


              STATE_DONE: begin
                wb_ack_o_reg <= 0;
                state <= STATE_IDLE;
              end


            endcase
        end
    end

    always_comb begin
      sram_ce_n = sram_ce_n_reg;
      sram_oe_n = sram_oe_n_reg;
      sram_we_n = sram_we_n_reg;
      wb_ack_o = wb_ack_o_reg;
    end


endmodule
