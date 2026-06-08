module signed_adder #(
    parameter DATA_WIDTH = 16
)(
    input  signed [DATA_WIDTH-1:0] a,
    input  signed [DATA_WIDTH-1:0] b,
    output signed [DATA_WIDTH-1:0] sum
);

    assign sum = a + b;

endmodule

