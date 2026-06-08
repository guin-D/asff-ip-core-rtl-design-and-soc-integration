import definition::*;

module softmax_ifm_agu #(
    parameter MAX_SIZE    = MAX_SIZE
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_i,
    input  wire [DATA_ADDR_WIDTH-1:0]           gamma_offset_i,

    // Control signals
    input  wire                                 start_i,
    input  wire                                 rd_i,

    // Output control signals
    output wire                                 thread_cnt_o,
    output wire                                 rd_done_o,

    // Output address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o
);

    localparam NUM_THREAD = SOFTMAX_CHANNEL / NUM_LANE;

    //========================
    // Counters
    //========================

    wire [$clog2(MAX_SIZE+1)-1:0]    col_cnt; 
    wire [$clog2(MAX_SIZE+1)-1:0]    row_cnt; 
    wire [$clog2(NUM_THREAD+1)-1:0]  thread_cnt;
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
        .COUNT_WIDTH($clog2(NUM_THREAD+1))
    ) thread_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(rd_i), 
        .max_value(($clog2(NUM_THREAD+1))'(NUM_THREAD - 1'b1)),
        .max_tick(thread_max),
        .value(thread_cnt)
    );

    //===============================
    // Address calculation
    //===============================

    wire [DATA_ADDR_WIDTH-1:0] ifm_addr_cal;
    reg  [DATA_ADDR_WIDTH-1:0] ptr_0;
    reg  [DATA_ADDR_WIDTH-1:0] ptr_1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ptr_0 <= 16'd0;
            ptr_1 <= 16'd0;
        end 
        else if (start_i && !rd_i) begin
            ptr_0 <= 16'd0;
            ptr_1 <= gamma_offset_i;
        end 
        else if (rd_i) begin

            if (thread_cnt == 1'b1) begin
                ptr_0 <= ptr_0 + 1'b1;
                ptr_1 <= ptr_1 + 1'b1;
            end
        end
    end

    assign ifm_addr_cal = thread_cnt ? ptr_1 : ptr_0;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_input_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_i),
        .d(ifm_addr_cal),
        .q(ifm_addr_o)
    );

    assign rd_done_o = row_max;
    assign thread_cnt_o = thread_cnt;

endmodule