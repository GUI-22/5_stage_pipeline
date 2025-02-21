
module alu (
    // 连接 ALU 模块的信号
    input wire  [15:0] alu_a,
    input wire  [15:0] alu_b,
    input wire  [ 3:0] alu_op,
    output reg [15:0] alu_y
);
  always_comb begin
    alu_y = 0;
    casez (alu_op)
      4'd1: begin
        alu_y = alu_a + alu_b;
        // alu_y = 0;
      end 
      4'd2: begin
        alu_y = alu_a - alu_b;
        // alu_y = 0;
      end 
      4'd3: begin
        alu_y = alu_a & alu_b;
        // alu_y = 0;
      end 
      4'd4: begin
        alu_y = alu_a | alu_b;
        // alu_y = 0;
      end 
      4'd5: begin
        alu_y = alu_a ^ alu_b;
        // alu_y = 0;
      end 
      4'd6: begin
        alu_y = ~alu_a;
        // alu_y = 0;
      end 
      4'd7: begin
        alu_y = alu_a << (alu_b & 16'h000f);
        // alu_y = 0;
      end 
      4'd8: begin
        alu_y = alu_a >> (alu_b & 16'h000f);
        // alu_y = 0;
      end 
      4'd9: begin
        alu_y = ((alu_a[15] == 0 ? 0 : 16'hffff) << (16 - (alu_b & 16'h000f))) | (alu_a >> (alu_b & 16'h000f));
        // alu_y = 0;
      end 
      4'd10: begin
        alu_y = (alu_a << (alu_b & 16'h000f)) | (alu_a >> (16 - (alu_b & 16'h000f)));
        // alu_y = 0;
      end 
    endcase

  end
  
endmodule

