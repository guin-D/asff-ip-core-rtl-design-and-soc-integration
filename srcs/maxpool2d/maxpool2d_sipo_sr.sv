import definition::*;

module sipo_shift_reg #(
    parameter DATA_WIDTH = 16
)(

    input  wire clk,
    input  wire rst_n,
    input  wire rst_local_n,
    input  wire en,
    input  wire signed [DATA_WIDTH-1:0] data_in,
    
    output reg  signed [DATA_WIDTH-1:0] data_out_0,
    output reg  signed [DATA_WIDTH-1:0] data_out_1,
    output reg  signed [DATA_WIDTH-1:0] data_out_2
);

    wire signed [DATA_WIDTH-1:0] NEG_INF;
    assign NEG_INF = {1'b1, {(DATA_WIDTH-1){1'b0}}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_0 <= NEG_INF;
            data_out_1 <= NEG_INF;
            data_out_2 <= NEG_INF;

        end else if (en) begin

            data_out_0 <= data_in;

            if (!rst_local_n) begin
                data_out_1 <= NEG_INF;
                data_out_2 <= NEG_INF;
            end else begin
                data_out_1 <= data_out_0;
                data_out_2 <= data_out_1;
            end

        end
    end

endmodule