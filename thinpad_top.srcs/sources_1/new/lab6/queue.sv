/*
Implementation of a queue with a fixed size
*/
module queue #(
    parameter SIZE = 16,
    parameter WIDTH = $clog2(SIZE)
)(
    input wire clk,
    input wire rst,

    input wire use_en,
    input wire [WIDTH-1:0] in_data,

    output wire [WIDTH-1:0] last // last element in the queue
);
/*
    i). when reset
        - elements are sorted in the queue: 0,1,...
    ii). when use_en is high
        - the in_data element is set to be the first element
        - other elements between the original first and in_data are shifted to the right 
*/
    reg [WIDTH-1:0] queue [SIZE-1:0];
    assign last = queue[SIZE-1];

    logic [WIDTH-1:0] in_data_index; // the index of in_data in the queue

    always_comb begin
        for (int i = 0; i < SIZE; i++) begin
            if (queue[i] == in_data) begin
                in_data_index = i;
            end
        end
    end

    logic shift [SIZE-1:0]; // if to shift the element at the index
    always_comb begin
        for (int i = 0; i < SIZE; i++) begin
            shift[i] = (i < in_data_index) ? 1 : 0;
        end
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < SIZE; i++) begin
                queue[i] <= i;
            end
        end else begin
            if (use_en) begin
                for (int i = 0; i < SIZE; i++) begin
                    // shift the elements
                    if (shift[i]) begin
                        queue[i+1] <= queue[i];
                    end
                end
                queue[0] <= in_data;
            end else begin
                // do nothing ！
            end
        end
    end

endmodule