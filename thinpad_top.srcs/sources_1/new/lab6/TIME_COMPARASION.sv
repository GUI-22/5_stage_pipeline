`include "./common_macros.svh"
`include "./exception_macros.svh"

module TIME_COMPARASION #(
    parameter ADDR_WIDTH=32,
    parameter DATA_WIDTH=32
)
(
    input wire clk_i, 
    input wire rst_i,

    input wire [ADDR_WIDTH-1:0] query_addr_i,
    input wire [DATA_WIDTH-1:0] query_data_i,
    input wire query_wen_i,
    input wire BEFORE_MEM_exception_flag_i,

    output logic time_exceeded_o,
    output logic [`TIME_DATA_WIDTH-1:0] mtime_o,
    output logic [`TIME_DATA_WIDTH-1:0] mtimecmp_o
);

    logic [`TIME_DATA_WIDTH-1:0] mtime;
    logic [`TIME_DATA_WIDTH-1:0] mtimecmp;

    logic [8:0] count;

    always_comb begin
        if ($unsigned(mtime) >= $unsigned(mtimecmp)) begin
            time_exceeded_o = 1;
        end
        else begin
            time_exceeded_o = 0;
        end
    end

    always_comb begin
        mtime_o = mtime;
        mtimecmp_o = mtimecmp;
    end

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            mtime <= 64'b0;
            mtimecmp <= -1;

            count <= 9'b0;
        end
        else if (query_wen_i == 1 && BEFORE_MEM_exception_flag_i == 0 
        && query_addr_i == `MTIME_ADDR_LOW) begin
            mtime <= {mtime[63:32], query_data_i};
            mtimecmp <= mtimecmp;
        end
        else if (query_wen_i == 1 && BEFORE_MEM_exception_flag_i == 0 
        && query_addr_i == `MTIME_ADDR_HIGH) begin
            mtime <= {query_data_i, mtime[31:0]};
            mtimecmp <= mtimecmp;
        end
        else if (query_wen_i == 1 && BEFORE_MEM_exception_flag_i == 0 
        && query_addr_i == `MTIMECMP_ADDR_LOW) begin
            mtime <= mtime;
            mtimecmp <= {mtimecmp[63:32], query_data_i};
        end
        else if (query_wen_i == 1 && BEFORE_MEM_exception_flag_i == 0 
        && query_addr_i == `MTIMECMP_ADDR_HIGH) begin
            mtime <= mtime;
            mtimecmp <= {query_data_i, mtimecmp[31:0]};
        end
        else begin // count++
            if (count == 9'b111_111_111) begin
                mtime <= mtime + 1;
                count <= 9'b0;
            end
            else begin
                count <= count + 1;
            end
            mtimecmp <= mtimecmp;
        end
    end
 
endmodule