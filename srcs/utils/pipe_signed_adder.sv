module pipe_signed_adder #(
    parameter DATA_WIDTH = 48
)(
    input  wire clk,
    input  wire rst_n,
    input  wire signed [DATA_WIDTH-1:0] a,
    input  wire signed [DATA_WIDTH-1:0] b,
    output wire signed [DATA_WIDTH-1:0] sum
);

    // Tính toán các hằng số cục bộ
    localparam LOW_WIDTH  = DATA_WIDTH / 2;              // 24 bit
    localparam HIGH_WIDTH = DATA_WIDTH - LOW_WIDTH;     // 24 bit
    localparam LOW_MSB    = LOW_WIDTH - 1;               // 23
    localparam HIGH_MSB   = DATA_WIDTH - 1;              // 47

    // Các thanh ghi Pipeline
    reg [LOW_MSB:0]    sum_low_reg;
    reg                carry_reg;
    reg [HIGH_WIDTH-1:0] a_high_pipe, b_high_pipe;

    always @(posedge clk) begin
        if (!rst_n) begin
            sum_low_reg <= 0;
            carry_reg   <= 0;
            a_high_pipe <= 0;
            b_high_pipe <= 0;
        end else begin
            // --- STAGE 1: Cộng nửa thấp ---
            // Sử dụng các param thay vì con số cụ thể
            {carry_reg, sum_low_reg} <= a[LOW_MSB:0] + b[LOW_MSB:0];
            
            a_high_pipe <= a[HIGH_MSB:LOW_WIDTH];
            b_high_pipe <= b[HIGH_MSB:LOW_WIDTH];

            // --- STAGE 2: Cộng nửa cao với bit nhớ ---
            
        end
    end
    assign sum[LOW_MSB:0]           = sum_low_reg;
    assign sum[HIGH_MSB:LOW_WIDTH]  = a_high_pipe + b_high_pipe + carry_reg;

endmodule