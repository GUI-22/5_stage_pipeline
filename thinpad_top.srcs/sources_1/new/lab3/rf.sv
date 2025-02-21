

module rf (
    input wire  [4:0]  rf_raddr_a, 
    output reg [15:0] rf_rdata_a, 
    input wire  [4:0]  rf_raddr_b,
    output reg [15:0] rf_rdata_b, 
    input wire  [4:0]  rf_waddr,
    input wire  [15:0] rf_wdata,
    input wire  rf_we,
    input wire clk,
    input wire reset
);

  logic [16:0] regs[31:0];

  always_ff @(posedge clk) begin
    if (reset) begin
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        regs[i] <= 0;
      end
    end
    else begin
      if (rf_we && rf_waddr != 0) begin
        regs[rf_waddr] <= rf_wdata;
      end

    end
  end

//   always_comb begin
//     rf_rdata_a = regs[rf_raddr_a];
//     rf_rdata_b = regs[rf_raddr_b];
//   end 
  always_comb begin
    if (rf_raddr_a >= 0 && rf_raddr_a < 32) begin
      if (rf_raddr_a == rf_waddr && rf_we && rf_waddr != 0) begin
        rf_rdata_a = rf_wdata;
      end else begin
        rf_rdata_a = regs[rf_raddr_a];
      end
    end else begin
      rf_rdata_a = 16'h0000; 
    end

    if (rf_raddr_b >= 0 && rf_raddr_b < 32) begin
      if (rf_raddr_b == rf_waddr && rf_we && rf_waddr != 0) begin
        rf_rdata_b = rf_wdata;
      end else begin
        rf_rdata_b = regs[rf_raddr_b];
      end
    end else begin
      rf_rdata_b = 16'h0000; 
    end
  end 

  
endmodule

