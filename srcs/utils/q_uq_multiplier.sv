import definition::*;

module q_uq_multiplier (
    input  wire signed [DATA_WIDTH-1:0]   a_q,
    input  wire        [DATA_WIDTH-1:0]   b_uq,
    output wire signed [DATA_WIDTH*2-1:0] p_q
);

    wire signed [DATA_WIDTH:0]      b_q;
    wire signed [DATA_WIDTH*2:0]    mult;

    assign b_q = {1'b0, b_uq};
    
    assign mult = a_q * b_q;

    assign p_q = mult[DATA_WIDTH*2-1:0];

endmodule