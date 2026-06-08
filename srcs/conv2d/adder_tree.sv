module adder_tree #(
    parameter C = 8,
    parameter DATA_WIDTH = 32
)(
    input  wire signed [C*DATA_WIDTH-1:0] data_in,
    output wire signed [DATA_WIDTH+$clog2(C)-1:0] data_out
);

    localparam STAGES = $clog2(C);
    localparam OUT_WIDTH = DATA_WIDTH + STAGES;

    wire signed [DATA_WIDTH-1:0] inputs [0:C-1];
    genvar i, j;

    generate
        for (i = 0; i < C; i = i + 1) begin : unpack
            assign inputs[i] = data_in[i*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate

    wire signed [OUT_WIDTH-1:0] nodes [0:STAGES][0:C-1];

    generate
        for (i = 0; i < C; i = i + 1) begin : init_tree
            assign nodes[0][i] = $signed(inputs[i]);
        end
    endgenerate

    generate
        for (i = 0; i < STAGES; i = i + 1) begin : stage_loop
            for (j = 0; j < (C >> (i+1)); j = j + 1) begin : adder_loop
                assign nodes[i+1][j] = nodes[i][2*j] + nodes[i][2*j+1];
            end
        end
    endgenerate

    assign data_out = nodes[STAGES][0];

endmodule