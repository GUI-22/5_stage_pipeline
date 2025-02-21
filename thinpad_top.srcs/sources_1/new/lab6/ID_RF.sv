`include "./common_macros.svh"

module ID_RF (

    input wire clk,
    input wire rst,

    input wire  rf_wen_i,
    input wire  [`REG_NUM_WIDTH-1:0]  rf_waddr_i,
    input wire  [`DATA_WIDTH-1:0] rf_wdata_i,

    input wire  [`REG_NUM_WIDTH-1:0]  rf_addr_a_i, 
    output reg [`DATA_WIDTH-1:0] rf_data_a_o, 
    input wire  [`REG_NUM_WIDTH-1:0]  rf_addr_b_i,
    output reg [`DATA_WIDTH-1:0] rf_data_b_o,
    
    // data bypassing
    input wire [`REG_NUM_WIDTH-1:0]  EXE_rf_waddr_i,
    input wire [`DATA_WIDTH-1:0] EXE_rf_wdata_i,
    input wire EXE_rf_wen_i,
    input wire EXE_query_ren_i, // does EXE need to read from sram?

    input wire [`REG_NUM_WIDTH-1:0]  MEM_rf_waddr_i,
    input wire [`DATA_WIDTH-1:0] MEM_rf_wdata_i,
    input wire MEM_rf_wen_i,

    input wire [`REG_NUM_WIDTH-1:0]  WB_rf_waddr_i,
    input wire [`DATA_WIDTH-1:0] WB_rf_wdata_i,
    input wire WB_rf_wen_i
);

    logic [31:0] regs [0:31];

    always_ff @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 0;
            end
        end
        else begin
            if (rf_wen_i && rf_waddr_i != 0) begin
                regs[rf_waddr_i] <= rf_wdata_i;
        end

        end
    end


    always_comb begin
      if (rf_addr_a_i == EXE_rf_waddr_i && EXE_rf_wen_i && !EXE_query_ren_i && EXE_rf_waddr_i != 0) begin
        // EXE will not read from sram & write to the same register (also it's not zero!)
        rf_data_a_o = EXE_rf_wdata_i;
      end else if (rf_addr_a_i == MEM_rf_waddr_i && MEM_rf_wen_i && MEM_rf_waddr_i != 0) begin
        rf_data_a_o = MEM_rf_wdata_i;
      end else if (rf_addr_a_i == WB_rf_waddr_i && WB_rf_wen_i && WB_rf_waddr_i != 0) begin
        // to WB part we don't care about sram read
        rf_data_a_o = WB_rf_wdata_i;
      end else if (rf_addr_a_i == rf_waddr_i && rf_wen_i && rf_waddr_i != 0) begin
          // reading from the write port
          rf_data_a_o = rf_wdata_i;
        end else begin
          // normal reading
          rf_data_a_o = regs[rf_addr_a_i];
        end

        // same for rf_data_b_o
        if (rf_addr_b_i == EXE_rf_waddr_i && EXE_rf_wen_i && !EXE_query_ren_i && EXE_rf_waddr_i != 0) begin
          rf_data_b_o = EXE_rf_wdata_i;
        end else if (rf_addr_b_i == MEM_rf_waddr_i && MEM_rf_wen_i && MEM_rf_waddr_i != 0) begin
          rf_data_b_o = MEM_rf_wdata_i;
        end else if (rf_addr_b_i == WB_rf_waddr_i && WB_rf_wen_i && WB_rf_waddr_i != 0) begin
          rf_data_b_o = WB_rf_wdata_i;
        end else if (rf_addr_b_i == rf_waddr_i && rf_wen_i && rf_waddr_i != 0) begin
          rf_data_b_o = rf_wdata_i;
        end else begin
          rf_data_b_o = regs[rf_addr_b_i];
        end
    end

  
endmodule

