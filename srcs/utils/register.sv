module register #(
    parameter DATA_WIDTH = 16,
    parameter IDLE = 0
)(
    input clk,
    input rst_n,
    input en,
    input [DATA_WIDTH-1:0] d,
    
    output reg [DATA_WIDTH-1:0] q
);
    
    always @(posedge clk) begin
        if(rst_n == 0) begin
            q <= IDLE;
        end
        else if (en == 1) begin
            q <= d;
        end
    end
endmodule