import definition::*;

module pe #(
    parameter SUM_WIDTH = 32,
    parameter MAX_SIZE  = MAX_SIZE 
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Data signals
    input  wire signed [DATA_WIDTH-1:0]         data_i,
    input  wire                                 valid_i,
    input  wire signed [DATA_WIDTH-1:0]         weight_i,
    input  wire                                 w_valid_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_in_i,
    input  wire                                 mode_i,

    // Control signals
    input  wire                                 mul_en_i,
    input  wire                                 done_i,

    // Output signals
    output wire signed [SUM_WIDTH-1:0]          data_o,
    output reg                                  valid_o
);
    
    localparam LINE_BUF_MAX_SIZE = MAX_SIZE + 2;

    wire [DATA_WIDTH-1:0] data_out_r0;
    wire [DATA_WIDTH-1:0] data_out_r1;

    wire [$clog2(LINE_BUF_MAX_SIZE+1)-1:0] line_buffer_limit = size_in_i + 2;


    circular_rmw_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(LINE_BUF_MAX_SIZE),
        .START_READ_PTR(1)
    ) row_0_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wrap_limit(line_buffer_limit),
        .w_en((valid_i && (mode_i == 1'b1))),
        .data_in(data_i),
        .r_en((valid_i && (mode_i == 1'b1))),
        .data_out(data_out_r0)
    );

    circular_rmw_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(LINE_BUF_MAX_SIZE),
        .START_READ_PTR(1)
    ) row_1_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wrap_limit(line_buffer_limit),
        .w_en((valid_i && (mode_i == 1'b1))),
        .data_in(data_out_r0),
        .r_en((valid_i && (mode_i == 1'b1))),
        .data_out(data_out_r1)
    );

    reg signed [DATA_WIDTH-1:0] weight_reg [0:8];
    reg  [DATA_WIDTH-1:0] weight_temp;
    reg w_valid_temp;

    integer i;

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i <= 8; i = i + 1) begin
                weight_reg[i] <= {DATA_WIDTH{1'b0}};
            end
            weight_temp <= {DATA_WIDTH{1'b0}};
            w_valid_temp <= 1'b0;
        end else begin
            if (w_valid_temp) begin
                weight_reg[8] <= weight_temp;
            end
            if (w_valid_temp && (mode_i == 1'b1)) begin
                for (i = 1; i <= 8; i = i + 1) begin
                    weight_reg[i-1] <= weight_reg[i];
                end
            end
            weight_temp <= weight_i;
            w_valid_temp <= w_valid_i;
        end
    end

    reg signed [DATA_WIDTH-1:0] input_reg [0:8];

    integer k;

    always @(posedge clk) begin
        if (!rst_n || done_i) begin
            for (k = 0; k < 9; k = k + 1) begin
                input_reg[k] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            if (valid_i) begin
                input_reg[8] <= data_i; 
            end
            if (valid_i && (mode_i == 1'b1)) begin
                input_reg[7] <= input_reg[8];
                input_reg[6] <= input_reg[7];

                input_reg[5] <= data_out_r0;
                input_reg[4] <= input_reg[5];
                input_reg[3] <= input_reg[4];

                input_reg[2] <= data_out_r1;
                input_reg[1] <= input_reg[2];
                input_reg[0] <= input_reg[1];
            end
        end
    end


    reg valid_d1, valid_d2, valid_d3, valid_d4, valid_d5;

    always @(posedge clk) begin
        if (!rst_n || done_i) begin
            valid_d1  <= 1'b0;
            valid_d2  <= 1'b0;
            valid_d3  <= 1'b0;
            valid_d4  <= 1'b0;
            valid_d5  <= 1'b0;
            valid_o   <= 1'b0;
        end else begin
            valid_d1  <= valid_i & mul_en_i; 
            valid_d2  <= valid_d1;
            valid_d3  <= valid_d2;
            valid_d4  <= valid_d3;
            valid_d5  <= valid_d4;
            valid_o <= valid_d5;

        end
    end

    reg signed [DATA_WIDTH*2-1:0] p1_reg [0:8];
    reg signed [SUM_WIDTH-1:0] p2_reg [0:4];
    reg signed [SUM_WIDTH-1:0] p3_reg [0:2];
    reg signed [SUM_WIDTH-1:0] p4_reg [0:1];
    reg signed [SUM_WIDTH-1:0] p5_reg;

    always @(posedge clk) begin
        if (!rst_n || done_i) begin
            for (i = 0; i < 9; i = i + 1) p1_reg[i] <= {SUM_WIDTH{1'b0}};
            for (i = 0; i < 5; i = i + 1) p2_reg[i] <= {SUM_WIDTH{1'b0}};
            for (i = 0; i < 3; i = i + 1) p3_reg[i] <= {SUM_WIDTH{1'b0}};
            for (i = 0; i < 2; i = i + 1) p4_reg[i] <= {SUM_WIDTH{1'b0}};
            p5_reg <= {SUM_WIDTH{1'b0}};
        end else begin
            
            if (valid_d1) begin
                p1_reg[0] <= input_reg[0] * weight_reg[0];
                p1_reg[1] <= input_reg[1] * weight_reg[1];
                p1_reg[2] <= input_reg[2] * weight_reg[2];
                p1_reg[3] <= input_reg[3] * weight_reg[3];
                p1_reg[4] <= input_reg[4] * weight_reg[4];
                p1_reg[5] <= input_reg[5] * weight_reg[5];
                p1_reg[6] <= input_reg[6] * weight_reg[6];
                p1_reg[7] <= input_reg[7] * weight_reg[7];
                p1_reg[8] <= input_reg[8] * weight_reg[8];
                
            end

            if (valid_d2) begin
                p2_reg[0] <= p1_reg[0] + p1_reg[1];
                p2_reg[1] <= p1_reg[2] + p1_reg[3];
                p2_reg[2] <= p1_reg[4] + p1_reg[5];
                p2_reg[3] <= p1_reg[6] + p1_reg[7];
                p2_reg[4] <= p1_reg[8]; 
            end

            if (valid_d3) begin
                p3_reg[0] <= p2_reg[0] + p2_reg[1];
                p3_reg[1] <= p2_reg[2] + p2_reg[3];
                p3_reg[2] <= p2_reg[4]; 
            end

            if (valid_d4) begin
                p4_reg[0] <= p3_reg[0] + p3_reg[1];
                p4_reg[1] <= p3_reg[2]; 
            end

            if (valid_d5) begin
                p5_reg <= p4_reg[0] + p4_reg[1];
            end
        end
    end

    assign data_o = p5_reg;

endmodule