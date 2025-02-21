module lab5_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter uart_addr_rw = 32'h10000000,
    parameter uart_addr_check = 32'h10000005,
    parameter uart_sel_check = 4'b0010,
    parameter uart_sel_rw = 4'b0001,
    parameter uart_check_mask = 32'h00001100
) (
    input wire clk_i,
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] addr_i,
    output reg [3:0] leds_o,
    // wishbone master
    output reg wb_cyc_o,
    output reg wb_stb_o,
    input wire wb_ack_i,
    output reg [ADDR_WIDTH-1:0] wb_adr_o,
    output reg [DATA_WIDTH-1:0] wb_dat_o,
    input wire [DATA_WIDTH-1:0] wb_dat_i,
    output reg [DATA_WIDTH/8-1:0] wb_sel_o,
    output reg wb_we_o
);

  // state
  typedef enum logic [3:0] {
    ST_IDLE,

    ST_READ_WAIT_ACTION,
    ST_READ_WAIT_CHECK,
    ST_READ_DATA_ACTION,
    ST_READ_DATA_DONE,

    ST_WRITE_SRAM_ACTION,
    ST_WRITE_SRAM_DONE,

    ST_WRITE_WAIT_ACTION,
    ST_WRITE_WAIT_CHECK,
    ST_WRITE_DATA_ACTION,
    ST_WRITE_DATA_DONE,
    
    ST_DONE
  } state_t;

  // def vars
  logic [31:0] count;
  logic [DATA_WIDTH-1:0] data_expected;
  logic [DATA_WIDTH-1:0] data_mask;  // mask out rng for write
  logic [DATA_WIDTH/8-1:0] read_compare;  // byte read compare result
  reg [DATA_WIDTH-1:0] wb_dat;
  reg [ADDR_WIDTH-1:0] sram_base_addr;
  reg [3:0] cnt;

  state_t state;

  assign wb_cyc_o = wb_stb_o;

  // test cycle counting
  always_ff @(posedge clk_i or posedge rst_i) begin

    if (rst_i) begin
      state <= ST_IDLE;
      sram_base_addr <= addr_i;
      cnt <= 0;

      wb_stb_o <= 0;
      wb_we_o <= 0;
      leds_o <= 0;
      wb_adr_o <= 0;
      wb_sel_o <= 0;

    end else begin
      case(state)

        ST_IDLE: begin
          if (cnt < 10) begin
            state <= ST_READ_WAIT_ACTION;
            cnt <= cnt + 1;
            wb_stb_o <= 1;
            wb_we_o <= 0;
            wb_adr_o <= uart_addr_check;
            wb_sel_o <= uart_sel_check;
            leds_o <= 1;
          end
        end

        // region: read from uart
        ST_READ_WAIT_ACTION: begin
          if (wb_ack_i == 1) begin
            state <= ST_READ_WAIT_CHECK;
            wb_dat <= wb_dat_i;
            wb_stb_o <= 0;
            wb_we_o <= 0;
          end
          leds_o <= 2;
        end

        ST_READ_WAIT_CHECK: begin
          if (wb_dat[8] == 0) begin
            state <= ST_READ_WAIT_ACTION;
          end else begin
            wb_adr_o <= uart_addr_rw;
            wb_sel_o <= uart_sel_rw;
            state <= ST_READ_DATA_ACTION;
          end
          wb_stb_o <= 1;
          wb_we_o <= 0;
          leds_o <= 3;
        end

        ST_READ_DATA_ACTION: begin
          if (wb_ack_i == 1) begin
            state <= ST_READ_DATA_DONE;
            wb_dat <= wb_dat_i;
            wb_stb_o <= 0;
            wb_we_o <= 0;
          end
          leds_o <= 4;
        end

        ST_READ_DATA_DONE: begin
          state <= ST_WRITE_SRAM_ACTION;
          wb_stb_o <= 1;
          wb_adr_o <= sram_base_addr + (cnt - 1) * 4;
          wb_dat_o <= wb_dat;
          wb_sel_o <= (4'b0001 << ((sram_base_addr + (cnt - 1) * 4) & 2'b11));
          wb_we_o <= 1;
          leds_o <= 5;
        end
        // endregion

        // region: write to sram
        ST_WRITE_SRAM_ACTION: begin
          if (wb_ack_i == 1) begin
            state <= ST_WRITE_SRAM_DONE;
            wb_stb_o <= 0;
            wb_we_o <= 0;
          end
          leds_o <= 6;
        end

        ST_WRITE_SRAM_DONE: begin
          state <= ST_WRITE_WAIT_ACTION;
          wb_stb_o <= 1;
          wb_we_o <= 0;
          wb_adr_o <= uart_addr_check;
          wb_sel_o <= uart_sel_check;
          leds_o <= 7;
        end
        // endregion

        // region: write to sram
        ST_WRITE_WAIT_ACTION: begin
          if (wb_ack_i == 1) begin
            state <= ST_WRITE_WAIT_CHECK;
            wb_dat <= wb_dat_i;
            wb_stb_o <= 0;
            wb_we_o <= 0;
          end
          leds_o <= 8;
        end

        ST_WRITE_WAIT_CHECK: begin
          if (wb_dat[13] == 0) begin
            state <= ST_WRITE_WAIT_ACTION;
          end else begin
            wb_adr_o <= uart_addr_rw;
            wb_sel_o <= uart_sel_rw;
            wb_dat_o <= wb_dat;
            state <= ST_WRITE_DATA_ACTION;
            wb_we_o <= 1;
          end
          wb_stb_o <= 1;
          leds_o <= 9;
        end

        ST_WRITE_DATA_ACTION: begin
          if (wb_ack_i == 1) begin
            state <= ST_WRITE_DATA_DONE;
            wb_stb_o <= 0;
            wb_we_o <= 0;
          end
          leds_o <= 10;
        end

        ST_WRITE_DATA_DONE: begin
          state <= ST_IDLE;
          wb_stb_o <= 1;
          wb_we_o <= 0;
          leds_o <= 11;
        end
        // endregion



      endcase
    end

  end
  


endmodule
