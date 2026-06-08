
import definition::*;

module conv2d_weight_agu #(
    parameter MAX_CHANNEL = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Config signals
    input  wire                                 mode_i,
    input  wire                                 norm_en_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_in_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_out_i,
    
    // Control signals
    input  wire                                 cw_rd_i,
    input  wire                                 nw_rd_i,
    input  wire                                 bw_rd_i,
    input  wire                                 done_i,

    // Output control signals
    output wire [$clog2(NUM_LANE+1)-1:0]        lane_cnt_o,
    output wire                                 ld_w_done_o,
    output wire                                 w_agu_done_o,

    // Output address signals
    output wire [WEIGHT_ADDR_WIDTH-1:0]         w_addr_o
);

    localparam KERNEL_AREA = KERNEL_SIZE * KERNEL_SIZE;
    localparam MAX_THREAD = MAX_CHANNEL / NUM_LANE;
    localparam MAX_PROCESS = MAX_CHANNEL / NUM_LANE;

    //=======================================
    // Declare config signals & base address
    //=======================================

    wire [$clog2(MAX_THREAD+1)-1:0]  num_thread;
    wire [$clog2(MAX_PROCESS+1)-1:0] num_process;
    wire [$clog2(KERNEL_AREA+1)-1:0] max_cell_val;

    assign num_thread  = channel_in_i / NUM_LANE;  
    assign num_process = channel_out_i / NUM_LANE; 
    assign max_cell_val = (mode_i == 1'b1) ? (KERNEL_AREA - 1) : 0;

    wire [WEIGHT_ADDR_WIDTH-1:0] base_norm_weight;
    wire [WEIGHT_ADDR_WIDTH-1:0] base_bias_weight;
    wire [WEIGHT_ADDR_WIDTH-1:0] base_conv_weight;

    assign base_norm_weight = {WEIGHT_ADDR_WIDTH{1'b0}};
    assign base_bias_weight = base_norm_weight + num_process;
    assign base_conv_weight = (norm_en_i == 1'b1) ? 
                              (base_bias_weight + num_process) : {WEIGHT_ADDR_WIDTH{1'b0}};

    //========================
    // Counters
    //========================

    wire [$clog2(KERNEL_AREA+1)-1:0] cell_cnt;
    wire [$clog2(MAX_THREAD+1)-1:0]  thread_cnt;
    wire [$clog2(MAX_PROCESS+1)-1:0] process_cnt;

    wire cell_max, lane_max, thread_max;
    wire at_thread_max, at_process_max;

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(KERNEL_AREA+1))
    ) counter_cell (
        .clk(clk),
        .rst_n(rst_n),
        .inc(cw_rd_i),
        .max_value(max_cell_val),
        .max_tick(cell_max),
        .value(cell_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(NUM_LANE+1))
    ) counter_lane (
        .clk(clk),
        .rst_n(rst_n),
        .inc(cell_max),
        .max_value(($clog2(NUM_LANE+1))'(NUM_LANE - 1'b1)),
        .max_tick(lane_max),
        .value(lane_cnt_o)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_THREAD+1))
    ) counter_thread (
        .clk(clk),
        .rst_n(rst_n),
        .inc(lane_max),
        .max_value(num_thread - 1'b1),
        .max_tick(thread_max),
        .at_max(at_thread_max),
        .value(thread_cnt)
    );

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH($clog2(MAX_PROCESS+1))
    ) counter_process (
        .clk(clk),
        .rst_n(rst_n),
        .inc(thread_max),
        .max_value(num_process - 1'b1),
        .at_max(at_process_max),
        .value(process_cnt)
    );

    //========================
    // Address Calculation
    //========================

    wire [WEIGHT_ADDR_WIDTH-1:0] weight_addr_mux;
    wire [WEIGHT_ADDR_WIDTH-1:0] address;
    wire [WEIGHT_ADDR_WIDTH-1:0] address_1x1;
    wire [WEIGHT_ADDR_WIDTH-1:0] address_3x3;
    wire [WEIGHT_ADDR_WIDTH-1:0] norm_address;
    wire [WEIGHT_ADDR_WIDTH-1:0] bias_address;

    wire [WEIGHT_ADDR_WIDTH-1:0] address_reg;
    wire [WEIGHT_ADDR_WIDTH-1:0] norm_address_reg;
    wire [WEIGHT_ADDR_WIDTH-1:0] bias_address_reg;

    wire [$clog2(KERNEL_AREA+1)-1:0] cell_cnt_reg;

    assign norm_address = process_cnt + base_norm_weight;
    assign bias_address = process_cnt + base_bias_weight;
    
    assign address = lane_cnt_o + (channel_out_i * thread_cnt) + process_cnt * NUM_LANE;

    register #(
        .DATA_WIDTH(WEIGHT_ADDR_WIDTH)
    ) reg_base_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(cw_rd_i),
        .d(address),
        .q(address_reg)
    );

    register #(
        .DATA_WIDTH(WEIGHT_ADDR_WIDTH)
    ) reg_norm_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(nw_rd_i),
        .d(norm_address),
        .q(norm_address_reg)
    );

    register #(
        .DATA_WIDTH(WEIGHT_ADDR_WIDTH)
    ) reg_bias_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(bw_rd_i),
        .d(bias_address),
        .q(bias_address_reg)
    );

    register #(
        .DATA_WIDTH($clog2(KERNEL_AREA+1))
    ) reg_cell_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .en(cw_rd_i),
        .d(cell_cnt),
        .q(cell_cnt_reg)
    );

    assign address_1x1 = address_reg + base_conv_weight;
    assign address_3x3 = cell_cnt_reg + (address_reg * KERNEL_AREA) + base_conv_weight;

    reg  nw_rd_d1;
    reg  bw_rd_d1;
    reg  cw_rd_d1;
    wire read_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            nw_rd_d1 <= 1'b0;
            bw_rd_d1 <= 1'b0;
            cw_rd_d1 <= 1'b0;

        end else begin
            nw_rd_d1 <= nw_rd_i;
            bw_rd_d1 <= bw_rd_i;
            cw_rd_d1 <= cw_rd_i;
        end
    end

    assign read_en =  nw_rd_d1 | bw_rd_d1 | cw_rd_d1;

    assign weight_addr_mux = (nw_rd_d1) ? norm_address_reg :
                             (bw_rd_d1) ? bias_address_reg :
                             (cw_rd_d1 && (mode_i == 1'b0)) ? address_1x1 :
                             (cw_rd_d1 && (mode_i == 1'b1)) ? address_3x3 :
                             {WEIGHT_ADDR_WIDTH{1'b0}};

    register #(
        .DATA_WIDTH(WEIGHT_ADDR_WIDTH)
    ) reg_weight_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(read_en),
        .d(weight_addr_mux),
        .q(w_addr_o)
    );

    // CONTROL SIGNALS 

    wire w_agu_done_en;

    assign w_agu_done_en = (at_process_max & at_thread_max) | done_i;

    register #(
        .DATA_WIDTH(1)
    ) reg_w_agu_done (
        .clk(clk),
        .rst_n(rst_n),
        .en(w_agu_done_en),
        .d(done_i ? 1'b0 : 1'b1), 
        .q(w_agu_done_o)
    );

    assign ld_w_done_o = lane_max;
     
endmodule