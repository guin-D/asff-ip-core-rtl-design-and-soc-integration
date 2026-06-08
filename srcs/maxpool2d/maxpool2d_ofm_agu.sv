import definition::*;

module maxpool2d_ofm_agu #(
    parameter MAX_SIZE_OUT = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_out_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_out_i, 

    // Control signals
    input  wire                                 valid_i,

    // Output control signals
    output wire                                 ofm_agu_done_o,

    // Output address signals
    output wire [DATA_ADDR_WIDTH-1:0]         ofm_addr_o
);

    localparam MAX_THREAD = MAX_CHANNEL / NUM_LANE;

    //========================
    // Counters to get done_o
    //========================

    wire col_max, row_max, thread_max;
    wire [$clog2(MAX_THREAD+1)-1:0] num_thread;

    assign num_thread  = channel_out_i / NUM_LANE; 

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1))
    ) col_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(valid_i),
        .max_value(size_out_i - 1'b1),
        .max_tick(col_max)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1))
    ) row_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(col_max),
        .max_value(size_out_i - 1'b1),
        .max_tick(row_max)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_THREAD+1))
    ) thread_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(row_max), 
        .max_value(num_thread - 1'b1),
        .max_tick(thread_max)
    );

    assign ofm_agu_done_o = thread_max;

    //========================
    // Calculate OFM address
    //========================

    wire [DATA_ADDR_WIDTH-1:0] ofm_addr;

    assign ofm_addr = ofm_addr_o + 1;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_ofm_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(ofm_addr),
        .q(ofm_addr_o)
    );

endmodule