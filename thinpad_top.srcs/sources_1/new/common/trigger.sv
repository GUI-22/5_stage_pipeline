module trigger (
  input wire clk,
  input wire insig,
  output reg outsig
);
    reg last_insig;
    always @(posedge clk) begin
        if (last_insig != 0 || insig != 1) begin
            outsig <= 0;
        end else begin
            outsig <= 1;
        end
        last_insig <= insig;
    end
endmodule
