import definition::*;

module conv2d_top #(
    parameter MAX_SIZE    = MAX_SIZE,
    parameter MAX_CHANNEL = MAX_CHANNEL,
    parameter HAS_UPSCALED_INTERFACE = 1
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]                 ifm_i,
    input  wire [BUS_WIDTH-1:0]                 weight_i,

    // Config signals
    input  wire                                 mode_i,
    input  wire                                 stride_2_en_i,
    input  wire [1:0]                           upscaled_mode_i,
    input  wire                                 norm_en_i,

    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_in_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_in_i,
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_out_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_out_i,

    // Address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o,
    output wire [WEIGHT_ADDR_WIDTH-1:0]         weight_addr_o,
    output wire [DATA_ADDR_WIDTH-1:0]           ofm_addr_o,

    // Control signals
    input  wire                                 start_i,
    input  wire                                 ack_i,

    // Output data signals
    output wire [BUS_WIDTH-1:0]                 ofm_o,
    output wire                                 we_o,

    // Status signals
    output wire                                 done_o
);

    wire ifm_rd, cw_rd, nw_rd, bw_rd;
    wire ifm_rd_d1, cw_rd_d1, nw_rd_d1, bw_rd_d1;
    wire bus_spr, bus_spr_d1;

    wire ifm_rd_en, mul_en;
    wire ifm_rd_en_d1, mul_en_d1;

    wire final_thread, final_thread_d1;
    wire norm_ld, norm_ld_d1;
    wire ld_w_done, w_agu_done, thread_done, process_done;
    wire ifm_w_agu_done;
    wire ofm_agu_done;
    wire [$clog2(NUM_LANE+1)-1:0] lane_cnt, lane_cnt_d1;
    wire [NUM_LANE-1:0] edtp_valid;

    // wire clk_core; // Dây dẫn clock tốc độ cao cho toàn hệ thống

    // // Khởi tạo Clocking Wizard (Thay clk_wiz_0 bằng tên bạn đã đặt nếu khác)
    // clk_wiz_0 u_clock_gen (
    //     .clk_in1  (clk),      // Đầu vào: Nhận clock gốc từ port
    //     .clk_out1 (clk_core)  // Đầu ra: Cấp clock đã ép xung cho clk_core
    // );

    assign ifm_w_agu_done = w_agu_done & process_done;
    assign we_o = &edtp_valid;

    // Delay c0 to dtp : 3

    // From In c1
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(3)
    ) delay_ifm_rd_en (
        .clk(clk),
        .rst_n(rst_n),
        .din(ifm_rd_en),
        .dout(ifm_rd_en_d1)
    );

    // From In c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_ifm_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(ifm_rd),
        .dout(ifm_rd_d1)
    );

    // From In c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_mul_en (
        .clk(clk),
        .rst_n(rst_n),
        .din(mul_en),
        .dout(mul_en_d1)
    );

    // From In c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_final_thread (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_thread),
        .dout(final_thread_d1)
    );

    // From In c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_norm_ld (
        .clk(clk),
        .rst_n(rst_n),
        .din(norm_ld),
        .dout(norm_ld_d1)
    );

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(3)
    ) delay_cw_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(cw_rd),
        .dout(cw_rd_d1)
    );

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(3)
    ) delay_nw_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(nw_rd),
        .dout(nw_rd_d1)
    );

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(3)
    ) delay_bw_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(bw_rd),
        .dout(bw_rd_d1)
    );

    // From FSM c0
    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(3)
    ) delay_bus_spr (
        .clk(clk),
        .rst_n(rst_n),
        .din(bus_spr),
        .dout(bus_spr_d1)
    );

    // From weight c0
    delay_buffer #(
        .DATA_WIDTH($clog2(NUM_LANE+1)),
        .DELAY(3)
    ) delay_lane_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .din(lane_cnt),
        .dout(lane_cnt_d1)
    );

    conv2d_ifm_agu #(
        .MAX_SIZE         (MAX_SIZE),
        .MAX_CHANNEL      (MAX_CHANNEL),
        .HAS_UPSCALED_INTERFACE (HAS_UPSCALED_INTERFACE)
    ) u_input_agu (
        .clk              (clk),
        .rst_n            (rst_n),

        // Config signals
        .mode_i           (mode_i),
        .stride_2_en_i    (stride_2_en_i),
        .upscaled_mode_i  (upscaled_mode_i),
        .size_in_i        (size_in_i),
        .channel_in_i     (channel_in_i),

        // Control signals
        .read_i           (ifm_rd),

        // Output control signals
        .final_thread_o   (final_thread),
        .norm_ld_o        (norm_ld),
        .thread_done_o    (thread_done),
        .process_done_o   (process_done),
        .read_en_o        (ifm_rd_en),
        .mul_en_o         (mul_en),

        // Output address signals
        .ifm_addr_o       (ifm_addr_o)
    );

    conv2d_weight_agu #(
        .MAX_CHANNEL      (MAX_CHANNEL)
    ) u_weight_agu (
        .clk              (clk),
        .rst_n            (rst_n),

        // Config signals
        .mode_i           (mode_i),
        .norm_en_i        (norm_en_i),
        .channel_in_i     (channel_in_i),
        .channel_out_i    (channel_out_i),

        // Control signals
        .cw_rd_i      (cw_rd),
        .nw_rd_i      (nw_rd),
        .bw_rd_i      (bw_rd),
        .done_i       (done_o),

        // Output control signals
        .lane_cnt_o       (lane_cnt),
        .ld_w_done_o      (ld_w_done),
        .w_agu_done_o     (w_agu_done),

        // Output address signals
        .w_addr_o         (weight_addr_o)
    );

    genvar i;
    generate
        for (i = 0; i < NUM_LANE; i = i + 1) begin : DTP_ARRAY

            wire [BUS_WIDTH-1:0] mux_weight_in;
            wire [BUS_WIDTH-1:0] separated_weight;
            assign separated_weight = { {(BUS_WIDTH - DATA_WIDTH){1'b0}}, weight_i[i*DATA_WIDTH +: DATA_WIDTH] };
            assign mux_weight_in = bus_spr_d1 ? weight_i[i*DATA_WIDTH +: DATA_WIDTH] : weight_i;

            conv2d_dtp #(
                .MAX_SIZE         (MAX_SIZE),
                .MAX_CHANNEL      (MAX_CHANNEL)
            ) u_dtp (
                .clk              (clk),
                .rst_n            (rst_n),

                // Data signals
                .data_i           (ifm_i),
                .valid_i          (ifm_rd_d1),
                .weight_i         (mux_weight_in),
                .w_valid_i        (cw_rd_d1 && (lane_cnt_d1 == i)),
                .nw_valid_i       (nw_rd_d1),
                .bw_valid_i       (bw_rd_d1),

                // Config signals
                .size_out_i       (size_out_i),
                .size_in_i        (size_in_i),
                .mode_i           (mode_i),
                .norm_en_i        (norm_en_i),

                // Control signals
                .read_en_i        (ifm_rd_en_d1),
                .mul_en_i         (mul_en_d1),
                .final_thread_i   (final_thread_d1),
                .norm_ld_i        (norm_ld_d1),
                .done_i           (done_o),

                // Output signals
                .valid_o          (edtp_valid[i]),
                .data_o           (ofm_o[i*DATA_WIDTH +: DATA_WIDTH])
            );
        end
    endgenerate

    conv2d_ofm_agu #(
        .MAX_SIZE        (MAX_SIZE),
        .MAX_CHANNEL     (MAX_CHANNEL)
    ) u_ofm_agu (
        .clk             (clk),
        .rst_n           (rst_n),

        // Config signals
        .size_out_i      (size_out_i),
        .channel_out_i   (channel_out_i),

        // Control signals
        .valid_i         (we_o),

        // Output control signals
        .ofm_agu_done_o  (ofm_agu_done),

        // Output address signals
        .ofm_addr_o      (ofm_addr_o)
    );

    conv2d_fsm u_fsm (
        .clk              (clk),
        .rst_n            (rst_n),

        // Control signals
        .start_i          (start_i),
        .norm_en_i        (norm_en_i),
        .ld_w_done_i      (ld_w_done),
        .thread_done_i    (thread_done),
        .process_done_i   (process_done),
        .ifm_w_agu_done_i (ifm_w_agu_done),
        .ofm_agu_done_i   (ofm_agu_done),
        .ack_i            (ack_i),

        // Output control signals
        .bus_spr_o        (bus_spr),
        .nw_rd_o          (nw_rd),
        .bw_rd_o          (bw_rd),
        .cw_rd_o          (cw_rd),
        .ifm_rd_o         (ifm_rd),

        // Status signals
        .done_o           (done_o)
    );
endmodule