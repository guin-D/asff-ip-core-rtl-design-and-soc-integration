import definition::*;

module maxpool2d_ifm_agu #(
    parameter MAX_SIZE_IN  = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_in_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_in_i, 

    // Control signals
    input  wire                                 rd_i,

    // Output control signals
    output wire                                 c_en_o,
    output wire                                 mp_en_o,
    output wire                                 rd_done_o,
    output wire                                 final_row_o,
    output wire                                 final_col_o,
    output wire                                 rd_valid_o,

    // Output address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o
);

    localparam MAX_THREAD = MAX_CHANNEL / NUM_LANE;

    //========================
    // Declare config signals
    //========================

    wire [$clog2(MAX_THREAD+1)-1:0] num_thread;
    wire [$clog2(MAX_SIZE+1+1)-1:0] size_limit; 
    wire [$clog2(MAX_SIZE+1+1)-1:0] col_limit; 
    wire [$clog2(MAX_SIZE+1+1)-1:0] row_limit;
    
    assign num_thread  = channel_in_i / NUM_LANE; 

    //========================
    // Counters
    //========================

    wire [$clog2(MAX_SIZE+1+1)-1:0]  col_cnt; 
    wire [$clog2(MAX_SIZE+1+1)-1:0]  row_cnt; 
    wire [$clog2(MAX_THREAD+1)-1:0]  thread_cnt;
    wire col_max, row_max, thread_max;
    
    dynamic_counter #(
        .START_VALUE(1),
        .COUNT_WIDTH($clog2(MAX_SIZE+1+1))
    ) col_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(rd_i),
        .max_value(size_in_i),
        .max_tick(col_max),
        .value(col_cnt)
    );
    dynamic_counter #(
        .START_VALUE(1),
        .COUNT_WIDTH($clog2(MAX_SIZE+1+1))
    ) row_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(col_max),
        .max_value(size_in_i),
        .max_tick(row_max),
        .value(row_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_THREAD+1))
    ) thread_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(row_max), 
        .max_value(num_thread - 1'b1),
        .max_tick(thread_max),
        .at_max(at_thread_max),
        .at_max_pulse(thread_max_pulse),
        .value(thread_cnt)
    );

    //========================
    // Calculate OFM address
    //========================

    wire [DATA_ADDR_WIDTH-1:0] ifm_addr_cal;

    assign ifm_addr_cal = ifm_addr_o + 1;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_ifm_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_i),
        .d(ifm_addr_cal),
        .q(ifm_addr_o)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_rd_valid (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(rd_i),
        .q(rd_valid_o)
    );

    assign rd_done_o = thread_max;
    assign final_row_o = row_max;
    assign final_col_o = col_max;
    assign c_en_o = (col_cnt[0] == 1'b0);
    assign mp_en_o = (col_cnt[0] == 1'b0) && (row_cnt[0] == 1'b0);

endmodule