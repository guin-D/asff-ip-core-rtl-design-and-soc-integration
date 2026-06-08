module q_to_uq_subtractor #(
    parameter DATA_WIDTH = 16
)(
    input  signed [DATA_WIDTH-1:0] a,
    input  signed [DATA_WIDTH-1:0] b,
    output        [DATA_WIDTH-1:0] diff
);

    wire signed [DATA_WIDTH:0] ext_a = {a[DATA_WIDTH-1], a};
    wire signed [DATA_WIDTH:0] ext_b = {b[DATA_WIDTH-1], b};
    wire signed [DATA_WIDTH:0] temp_diff;

    assign temp_diff = ext_a - ext_b;

    assign diff = temp_diff[DATA_WIDTH-1:0];

endmodule