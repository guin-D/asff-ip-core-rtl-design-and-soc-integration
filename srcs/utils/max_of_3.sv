import definition::*;

module max_of_3 #(
    parameter DATA_WIDTH = 16
) (
    input  signed [DATA_WIDTH-1:0] data_in_0,
    input  signed [DATA_WIDTH-1:0] data_in_1,
    input  signed [DATA_WIDTH-1:0] data_in_2,
    output signed [DATA_WIDTH-1:0] data_out
);

    wire signed [DATA_WIDTH-1:0] max_0_1;

    assign max_0_1 = (data_in_0 > data_in_1) ? data_in_0 : data_in_1;

    assign data_out = (max_0_1 > data_in_2) ? max_0_1 : data_in_2;

endmodule