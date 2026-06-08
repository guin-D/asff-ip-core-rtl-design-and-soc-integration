import definition::*;

module conv2d_dtp #(
    parameter MAX_SIZE = MAX_SIZE,
    parameter MAX_CHANNEL = MAX_CHANNEL
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]          data_i,
    input  wire                          valid_i,
    input  wire [BUS_WIDTH-1:0]          weight_i,
    input  wire                          w_valid_i,
    input  wire                          nw_valid_i,
    input  wire                          bw_valid_i,

    // Config signals
    input  wire                          mode_i,
    input  wire                          norm_en_i,
    input  wire [$clog2(MAX_SIZE+1)-1:0] size_out_i,
    input  wire [$clog2(MAX_SIZE+1)-1:0] size_in_i,
    
    // Control signals
    input  wire                          read_en_i,
    input  wire                          mul_en_i,
    input  wire                          final_thread_i,
    input  wire                          norm_ld_i,
    input  wire                          done_i,

    // Output signals
    output [DATA_WIDTH-1:0]              data_o,
    output                               valid_o
);

    localparam SUM_WIDTH = DATA_WIDTH * 2 + $clog2(KERNEL_SIZE*KERNEL_SIZE);
    localparam SUM_WIDTH_2 = SUM_WIDTH + $clog2(NUM_LANE);

    localparam MAX_THREAD = MAX_CHANNEL / NUM_LANE;
    
    //====================
    // PE
    //====================

    wire [DATA_WIDTH*2-1:0]       data_to_pe;
    wire [SUM_WIDTH*NUM_LANE-1:0] data_pe_to_at;

    wire [NUM_LANE-1:0]           valid_epe_to;
    wire                          valid_pe_to;

    // Mux for padding
    assign data_to_pe = (read_en_i == 1'b1) ? data_i : {(DATA_WIDTH*2){1'b0}};

    genvar i;
    generate
        for (i = 0; i < NUM_LANE; i = i + 1) begin : gen_pe_array
            pe #(
                .SUM_WIDTH(SUM_WIDTH),
                .MAX_SIZE(MAX_SIZE)
            ) pe_1x1_inst (
                .clk(clk),
                .rst_n(rst_n),
                .data_i(data_to_pe[i * DATA_WIDTH +: DATA_WIDTH]),           
                .valid_i(valid_i),
                .mul_en_i(mul_en_i),
                .weight_i(weight_i[i * DATA_WIDTH +: DATA_WIDTH]), 
                .w_valid_i(w_valid_i),
                .size_in_i(size_in_i),
                .mode_i(mode_i),
                .done_i(done_i),
                .data_o(data_pe_to_at[i * SUM_WIDTH +: SUM_WIDTH]),
                .valid_o(valid_epe_to[i])
            );
        end
    endgenerate

    assign valid_pe_to = valid_epe_to[1];

    //========================
    // THREAD & PROCESS ADDER 
    //========================

    wire [SUM_WIDTH_2-1:0]    data_at_to_a;
    wire [SUM_WIDTH_2-1:0]    data_at_to_a_reg;
    wire [DATA_WIDTH_BUF-1:0] data_buf_to_a;
    wire [DATA_WIDTH_BUF-1:0] data_at_to_a_reg_aligned;
    wire [DATA_WIDTH_BUF-1:0] data_a_to;

    wire                      valid_pe_to_d1;
    wire                      valid_pe_to_d2;

    adder_tree #(
        .DATA_WIDTH(SUM_WIDTH),
        .C(NUM_LANE)
    ) adder_tree_inst (
        .data_in(data_pe_to_at),
        .data_out(data_at_to_a)
    ); 

    register #(
        .DATA_WIDTH(SUM_WIDTH_2)
    ) reg_in_adder (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_pe_to),
        .d(data_at_to_a),
        .q(data_at_to_a_reg)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_pe_to_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_pe_to),
        .q(valid_pe_to_d1)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_pe_to_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_pe_to_d1),
        .q(valid_pe_to_d2)
    );

    assign data_at_to_a_reg_aligned = {
        {(DATA_WIDTH_BUF - SUM_WIDTH_2){data_at_to_a_reg[SUM_WIDTH_2-1]}},
        data_at_to_a_reg
    };

    pipe_signed_adder #(
        .DATA_WIDTH(DATA_WIDTH_BUF)
    ) adder_inst (
        .clk(clk),
        .rst_n(rst_n),
        .a(data_at_to_a_reg_aligned),
        .b(data_buf_to_a),
        .sum(data_a_to)
    );

    //========================
    // ACCUMULATION BUFFER 
    //========================

    wire [DATA_WIDTH_BUF-1:0] data_to_buf;

    wire [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0] area_out;

    wire final_thread_d1;

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(9)
    ) delay_final_thread (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_thread_i),
        .dout(final_thread_d1)
    );

    assign data_to_buf = (final_thread_d1 == 0) ? data_a_to : {DATA_WIDTH_BUF{1'b0}};

    assign area_out = size_out_i * size_out_i;

    circular_rmw_buffer #(
        .DATA_WIDTH(DATA_WIDTH_BUF),
        .N(MAX_SIZE*MAX_SIZE),
        .USE_BRAM(1)
    ) acc_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wrap_limit(area_out),
        .w_en(valid_pe_to_d2),
        .data_in(data_to_buf),
        .r_en(valid_pe_to),
        .data_out(data_buf_to_a)
    );

    //========================
    // BATCHNORM2D & RELU6
    //========================

    wire norm_ld_d1;
    wire norm_valid;
    wire [DATA_WIDTH-1:0] weight_to_norm;

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(8)
    ) delay_norm_ld (
        .clk(clk),
        .rst_n(rst_n),
        .din(norm_ld_i),
        .dout(norm_ld_d1)
    );

    assign norm_valid = final_thread_d1 & valid_pe_to_d2;
    assign weight_to_norm = weight_i[DATA_WIDTH-1:0];

    conv2d_norm conv2d_norm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(data_a_to),
        .valid_i(norm_valid),
        .weight_i(weight_to_norm),
        .bw_valid_i(bw_valid_i),
        .nw_valid_i(nw_valid_i),
        .norm_en_i(norm_en_i),
        .norm_ld_i(norm_ld_d1),
        .data_o(data_o),
        .valid_o(valid_o)
    );

endmodule