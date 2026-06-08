import definition::*;

module ew_mac_ofm_agu #(
    parameter MAX_SIZE     = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_i,

    // Control signals
    input  wire                                 valid_i,

    // Output control signals
    output wire                                 wr_done_o,

    // Output address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ofm_addr_o
);

    localparam MAX_THREAD = MAX_CHANNEL / NUM_LANE;

    //========================
    // Declare config signals
    //========================

    wire [$clog2(MAX_THREAD+1)-1:0] num_thread;

    assign num_thread  = channel_i / NUM_LANE; 

    //========================
    // Counters
    //========================

    wire [$clog2(MAX_SIZE+1)-1:0]    col_cnt; 
    wire [$clog2(MAX_SIZE+1)-1:0]    row_cnt; 
    wire [$clog2(MAX_THREAD+1)-1:0]  thread_cnt;

    wire col_max, row_max, thread_max;
    
    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1))
    ) col_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(thread_max),
        .max_value(size_i - 1'b1),
        .max_tick(col_max),
        .value(col_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1))
    ) row_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(col_max),
        .max_value(size_i - 1'b1),
        .max_tick(row_max),
        .value(row_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_THREAD+1))
    ) thread_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(valid_i), 
        .max_value(num_thread - 1'b1),
        .max_tick(thread_max),
        .value(thread_cnt)
    );

    // ADDRESS CALCULATION

    wire [DATA_ADDR_WIDTH-1:0]      element_1;
    wire [DATA_ADDR_WIDTH-1:0]      element_2;
    wire [DATA_ADDR_WIDTH-1:0]      element_1_reg;
    wire [DATA_ADDR_WIDTH-1:0]      element_2_reg;
    wire [DATA_ADDR_WIDTH-1:0]      ofm_addr_cal;
    wire [$clog2(MAX_SIZE+1)-1:0]   col_cnt_reg;

    wire                            valid_d1;

    assign element_1 = row_cnt * size_i;
    assign element_2 = thread_cnt * size_i * size_i;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(element_1),
        .q(element_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(element_2),
        .q(element_2_reg)
    );

    register #(
        .DATA_WIDTH($clog2(MAX_SIZE+1+1))
    ) reg_col (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(col_cnt),
        .q(col_cnt_reg)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_i),
        .q(valid_d1)
    );

    assign ofm_addr_cal = col_cnt_reg + element_1_reg + element_2_reg;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_output_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_d1),
        .d(ofm_addr_cal),
        .q(ofm_addr_o)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_row_max (
        .clk(clk),
        .rst_n(rst_n),
        .din(row_max),
        .dout(wr_done_o)
    );

endmodule