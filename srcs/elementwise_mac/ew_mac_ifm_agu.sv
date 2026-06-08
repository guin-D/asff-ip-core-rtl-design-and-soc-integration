import definition::*;

module ew_mac_ifm_agu #(
    parameter EW_MAC_LEVEL = 0,
    parameter MAX_SIZE     = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_i,

    // Control signals
    input  wire                                 rd_i,

    // Output control signals
    output wire [$clog2(3)-1:0]                 slot_cnt_o,
    output wire                                 final_siw_o,
    output wire                                 rd_pixel_done_o,
    output wire                                 rd_done_o,

    // Output address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o
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
    wire [$clog2(3)-1:0]             slot_cnt;

    wire col_max, row_max, thread_max, slot_max;
    
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
        .inc(slot_max), 
        .max_value(num_thread - 1'b1),
        .max_tick(thread_max),
        .value(thread_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(2+1))
    ) slot_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(rd_i), 
        .max_value(2),
        .max_tick(slot_max),
        .value(slot_cnt)
    );

    //===============================
    // Counters' variable handling
    //===============================

    wire [$clog2(MAX_SIZE+1)-1:0]          mem_row;
    wire [$clog2(MAX_SIZE+1)-1:0]          mem_col;
    wire [$clog2(MAX_SIZE+1)-1:0]          actual_size_in;
    wire [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0] actual_input_area;

    // UPSCALED HANDLING

    generate
        if (EW_MAC_LEVEL == 2) begin : gen_upscaled_interface_lv2
            assign mem_row = (slot_cnt == 2'b00) ? (row_cnt >> 2) :
                             (slot_cnt == 2'b01) ? (row_cnt >> 1) : 
                                                    row_cnt; 

            assign mem_col = (slot_cnt == 2'b00) ? (col_cnt >> 2) :
                             (slot_cnt == 2'b01) ? (col_cnt >> 1) : 
                                                    col_cnt; 

            
            assign actual_size_in = (slot_cnt == 2'b00) ? (size_i >> 2) :
                                    (slot_cnt == 2'b01) ? (size_i >> 1) : 
                                                           size_i;

            
            assign actual_input_area = actual_size_in * actual_size_in;

        end else if (EW_MAC_LEVEL == 1) begin : gen_upscaled_interface_lv1
            assign mem_row = (slot_cnt == 2'b00) ? (row_cnt >> 1) : row_cnt; 

            assign mem_col = (slot_cnt == 2'b00) ? (col_cnt >> 1) : col_cnt; 

            assign actual_size_in = (slot_cnt == 2'b00) ? (size_i >> 1) : size_i;
            
            assign actual_input_area = actual_size_in * actual_size_in;

        end else begin : gen_normal
            assign mem_row = row_cnt;

            assign mem_col = col_cnt; 

            assign actual_size_in = size_i;

            assign actual_input_area = actual_size_in * actual_size_in;

        end
    endgenerate

    // ADDRESS CALCULATION

    wire [DATA_ADDR_WIDTH-1:0]      element_1;
    wire [DATA_ADDR_WIDTH-1:0]      element_2;
    wire [DATA_ADDR_WIDTH-1:0]      element_1_reg;
    wire [DATA_ADDR_WIDTH-1:0]      element_2_reg;
    wire [DATA_ADDR_WIDTH-1:0]      ifm_addr_cal;
    wire [$clog2(MAX_SIZE+1)-1:0]   mem_col_reg;

    wire                            rd_d1;

    assign element_1 = mem_row * actual_size_in;
    assign element_2 = thread_cnt * actual_input_area;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_i),
        .d(element_1),
        .q(element_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_e2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_i),
        .d(element_2),
        .q(element_2_reg)
    );

    register #(
        .DATA_WIDTH($clog2(MAX_SIZE+1+1))
    ) reg_ncol (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_i),
        .d(mem_col),
        .q(mem_col_reg)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_read_en (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(rd_i),
        .q(rd_d1)
    );

    assign ifm_addr_cal = mem_col_reg + element_1_reg + element_2_reg;

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_input_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(rd_d1),
        .d(ifm_addr_cal),
        .q(ifm_addr_o)
    );

    assign rd_pixel_done_o = thread_max;
    assign final_siw_o = slot_max;
    assign slot_cnt_o = slot_cnt;
    assign rd_done_o = row_max;

endmodule