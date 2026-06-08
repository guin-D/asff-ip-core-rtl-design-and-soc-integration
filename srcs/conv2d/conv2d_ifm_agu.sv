import definition::*;

module conv2d_ifm_agu #(
    parameter MAX_SIZE    = MAX_SIZE,
    parameter MAX_CHANNEL = MAX_CHANNEL,
    parameter HAS_UPSCALED_INTERFACE = 1
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire                                 mode_i,
    input  wire                                 stride_2_en_i,
    input  wire [1:0]                           upscaled_mode_i,
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_in_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_in_i,

    // Control signals
    input  wire                                 read_i,

    // Output control signals
    output wire                                 final_thread_o,
    output wire                                 norm_ld_o,
    output wire                                 thread_done_o,
    output wire                                 process_done_o,
    output wire                                 read_en_o,
    output wire                                 mul_en_o,

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
    assign size_limit = (mode_i == 1'b1) ? (size_in_i + 1'b1) : (size_in_i - 1'b1);         // padding                                        
    assign col_limit = size_limit;
    assign row_limit = (mode_i == 1'b1 && stride_2_en_i == 1'b1 && size_in_i[0] == 1'b0) ? (size_limit - 1'b1) : size_limit;  // even != odd

    //========================
    // Counters
    //========================

    wire [$clog2(MAX_SIZE+1+1)-1:0]  col_cnt; 
    wire [$clog2(MAX_SIZE+1+1)-1:0]  row_cnt; 
    wire [$clog2(MAX_THREAD+1)-1:0]  thread_cnt;
    wire col_max, row_max, thread_max;
    
    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1+1))
    ) col_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(read_i),
        .max_value(col_limit),
        .max_tick(col_max),
        .value(col_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_SIZE+1+1))
    ) row_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(col_max),
        .max_value(row_limit),
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

    //===============================
    // Counters' variable handling
    //===============================

    wire [$clog2(MAX_SIZE+1+1)-1:0]        mux_row;
    wire [$clog2(MAX_SIZE+1+1)-1:0]        mux_col;
    wire [$clog2(MAX_SIZE+1+1)-1:0]        mem_row;
    wire [$clog2(MAX_SIZE+1+1)-1:0]        mem_col;
    wire [$clog2(MAX_SIZE+1)-1:0]          actual_size_in;
    wire [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0] actual_input_area;

    assign mux_row = (mode_i == 1'b1) ? (row_cnt - 1'b1) : row_cnt; // skip padding
    assign mux_col = (mode_i == 1'b1) ? (col_cnt - 1'b1) : col_cnt;

    // UPSCALED HANDLING

    generate
        if (HAS_UPSCALED_INTERFACE == 1) begin : gen_upscaled_interface
            assign mem_row = (upscaled_mode_i == 2'b01) ? (mux_row >> 1) :
                                 (upscaled_mode_i == 2'b10) ? (mux_row >> 2) : 
                                                            mux_row; 

            assign mem_col = (upscaled_mode_i == 2'b01) ? (mux_col >> 1) :
                                 (upscaled_mode_i == 2'b10) ? (mux_col >> 2) : 
                                                            mux_col; 

            
            assign actual_size_in = (upscaled_mode_i == 2'b01) ? (size_in_i >> 1) :
                                    (upscaled_mode_i == 2'b10) ? (size_in_i >> 2) : 
                                                            size_in_i;

            
            assign actual_input_area = actual_size_in * actual_size_in;

        end else begin : gen_normal
            assign mem_row = mux_row;

            assign mem_col = mux_col; 

            assign actual_size_in = size_in_i;

            assign actual_input_area = actual_size_in * actual_size_in;

        end
    endgenerate

    // assign mem_row = (upscaled_mode_i == 2'b01) ? (mux_row >> 1) :
    //                      (upscaled_mode_i == 2'b10) ? (mux_row >> 2) : 
    //                                                 mux_row; 

    // assign mem_col = (upscaled_mode_i == 2'b01) ? (mux_col >> 1) :
    //                      (upscaled_mode_i == 2'b10) ? (mux_col >> 2) : 
    //                                                 mux_col; 

    
    // assign actual_size_in = (upscaled_mode_i == 2'b01) ? (size_in_i >> 1) :
    //                         (upscaled_mode_i == 2'b10) ? (size_in_i >> 2) : 
    //                                                    size_in_i;

    
    // assign actual_input_area = actual_size_in * actual_size_in;

    // PADDING HANDLING

    wire is_pad_row;
    wire is_pad_col;
    wire read_en;

    assign is_pad_row = (mode_i == 1'b1) ? ((row_cnt == 0) || (row_cnt == size_limit)) : 1'b0;
    assign is_pad_col = (mode_i == 1'b1) ? ((col_cnt == 0) || (col_cnt == size_limit)) : 1'b0;

    assign read_en = (~(is_pad_row | is_pad_col)) && (read_i == 1);

    // STRIDE HANDLING

    wire col_ge_2;
    wire row_ge_2;
    wire col_even;
    wire row_even;

    assign col_ge_2 = |col_cnt[$clog2(MAX_SIZE+1)-1:1]; 
    assign row_ge_2 = |row_cnt[$clog2(MAX_SIZE+1)-1:1]; 

    assign col_even = (col_cnt[0] == 1'b0);
    assign row_even = (row_cnt[0] == 1'b0);

    assign mul_en_o = (mode_i == 1'b0) ? read_i : 
                    (stride_2_en_i == 1'b0) ? (read_i & col_ge_2 & row_ge_2) :
                                            (read_i & col_ge_2 & row_ge_2 & col_even & row_even);

    // ADDRESS CALCULATION

    wire [DATA_ADDR_WIDTH-1:0]      element_1;
    wire [DATA_ADDR_WIDTH-1:0]      element_2;
    wire [DATA_ADDR_WIDTH-1:0]      element_1_reg;
    wire [DATA_ADDR_WIDTH-1:0]      element_2_reg;
    wire [DATA_ADDR_WIDTH-1:0]      ifm_addr_cal;
    wire [$clog2(MAX_SIZE+1+1)-1:0] mem_col_reg;

    assign element_1 = mem_row * actual_size_in;
    assign element_2 = thread_cnt * actual_input_area;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(read_en),
        .d(element_1),
        .q(element_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(read_en),
        .d(element_2),
        .q(element_2_reg)
    );

    register #(
        .DATA_WIDTH($clog2(MAX_SIZE+1+1))
    ) reg_ncol (
        .clk(clk),
        .rst_n(rst_n),
        .en(read_en),
        .d(mem_col),
        .q(mem_col_reg)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_read_en (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(read_en),
        .q(read_en_o)
    );

    assign ifm_addr_cal = mem_col_reg + element_1_reg + element_2_reg;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_input_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(read_en_o),
        .d(ifm_addr_cal),
        .q(ifm_addr_o)
    );

    // CONTROL SIGNALS 

    assign thread_done_o = row_max;
    assign process_done_o = thread_max;
    assign final_thread_o = at_thread_max;
    assign norm_ld_o = thread_max_pulse;

endmodule