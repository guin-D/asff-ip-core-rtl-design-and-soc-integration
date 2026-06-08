module delay_buffer #(
    parameter DATA_WIDTH = 1,
    parameter DELAY = 1
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout
);

    generate
        if (DELAY == 0) begin : gen_no_delay
            assign dout = din;
        end else begin : gen_delay
            reg [DATA_WIDTH-1:0] pipe [0:DELAY-1];
            integer i;

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (i = 0; i < DELAY; i = i + 1) begin
                        pipe[i] <= {DATA_WIDTH{1'b0}};
                    end
                end else begin
                    pipe[0] <= din;
                    for (i = 1; i < DELAY; i = i + 1) begin
                        pipe[i] <= pipe[i-1];
                    end
                end
            end

            assign dout = pipe[DELAY-1];
        end
    endgenerate

endmodule