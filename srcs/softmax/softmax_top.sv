import definition::*;

module softmax_top #(
    parameter MAX_SIZE    = MAX_SIZE
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]                 ifm_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_i,

    // Address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o,
    output wire [DATA_ADDR_WIDTH-1:0]           siw_addr_o,

    // Control signals
    input  wire                                 start_i,

    // Output data signals
    output wire [BUS_WIDTH-1:0]                 data_o,
    output wire                                 we_o,

    // Status signals
    output wire                                 done_o
);

    wire rd, rd_d1;
    wire thread_cnt, thread_cnt_d1;
    wire siw_addr_valid;
    wire rd_done;
    wire wr_done;

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(rd),
        .dout(rd_d1)
    );

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_thread_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .din(thread_cnt),
        .dout(thread_cnt_d1)
    );

    wire [DATA_ADDR_WIDTH-1:0] gamma_offset;

    assign gamma_offset = size_i * size_i;

    softmax_ifm_agu #(
        .MAX_SIZE        (MAX_SIZE)
    ) ifm_agu_inst (
        .clk             (clk),
        .rst_n           (rst_n),

        // Config signals
        .size_i          (size_i),
        .gamma_offset_i  (gamma_offset),

        // Control signals
        .start_i         (start_i),
        .rd_i            (rd),

        // Output control signals
        .thread_cnt_o    (thread_cnt),
        .rd_done_o       (rd_done),

        // Output address signals
        .ifm_addr_o      (ifm_addr_o)
    );

    softmax_dtp dtp_inst (
        .clk              (clk),
        .rst_n            (rst_n),

        // Data signals
        .data_i           (ifm_i),
        .valid_i          (rd_d1),
        
        // Control signals
        .thread_cnt_i     (thread_cnt_d1),

        // Output control signals
        .siw_addr_valid_o (siw_addr_valid),

        // Output signals
        .data_o           (data_o),
        .valid_o          (we_o)
    );

    softmax_siw_agu #(
        .MAX_SIZE        (MAX_SIZE)
    ) siw_agu_inst (
        .clk             (clk),
        .rst_n           (rst_n),

        // Config signals
        .size_i          (size_i),
        .gamma_offset_i  (gamma_offset),

        // Control signals
        .start_i         (start_i),
        .valid_i         (siw_addr_valid),

        // Output control signals
        .wr_done_o       (wr_done),

        // Output address signals
        .siw_addr_o      (siw_addr_o)
    );

    softmax_fsm fsm_inst (
        .clk        (clk),
        .rst_n      (rst_n),

        // Control signals
        .start_i    (start_i),
        .rd_done_i  (rd_done),
        .wr_done_i  (wr_done),

        // Output control signals
        .rd_o       (rd),
        
        // Status signals
        .done_o     (done_o)
    );

endmodule
