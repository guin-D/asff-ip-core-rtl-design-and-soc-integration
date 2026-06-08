import definition::*;

module maxpool_top #(
    parameter MAX_SIZE_IN  = MAX_SIZE,
    parameter MAX_SIZE_OUT = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]                 ifm_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_in_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_in_i,

    // Address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o,
    output wire [DATA_ADDR_WIDTH-1:0]           ofm_addr_o,

    // Control signals
    input  wire                                 start_i,

    // Output data signals
    output wire [BUS_WIDTH-1:0]                 ofm_o,
    output wire                                 we_o,

    // Status signals
    output wire                                 done_o
);
        
    wire c_en, c_en_d1;
    wire mp_en, mp_en_d1;
    wire final_row, final_row_d1;
    wire final_col, final_col_d1;
    wire ifm_rd, ifm_rd_d1;

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_c_en (
        .clk(clk),
        .rst_n(rst_n),
        .din(c_en),
        .dout(c_en_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_mp_en (
        .clk(clk),
        .rst_n(rst_n),
        .din(mp_en),
        .dout(mp_en_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_final_row (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_row),
        .dout(final_row_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_final_col (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_col),
        .dout(final_col_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_rd_valid (
        .clk(clk),
        .rst_n(rst_n),
        .din(ifm_rd),
        .dout(ifm_rd_d1)
    );

    wire rd_done;
    wire wr_done;
    wire rd_valid;

    wire [$clog2(MAX_SIZE+1)-1:0]        size_out;
    wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_out;

    assign size_out = size_in_i >> 1;
    assign channel_out = channel_in_i >> 1;

    maxpool2d_ifm_agu #(
        .MAX_SIZE_IN      (MAX_SIZE_IN),
        .MAX_CHANNEL      (MAX_CHANNEL)
    ) u_maxpool2d_ifm_agu (
        .clk              (clk),
        .rst_n            (rst_n),

        // Config signals
        .size_in_i        (size_in_i),
        .channel_in_i     (channel_in_i),

        // Control signals
        .rd_i             (ifm_rd),

        // Output control signals
        .c_en_o           (c_en),
        .mp_en_o          (mp_en),
        .rd_done_o        (rd_done),
        .final_row_o      (final_row),
        .final_col_o      (final_col),
        .rd_valid_o       (rd_valid),

        // Output address signals
        .ifm_addr_o       (ifm_addr_o)
    );

    maxpool2d_ofm_agu #(
        .MAX_SIZE_OUT     (MAX_SIZE_OUT),
        .MAX_CHANNEL      (MAX_CHANNEL)
    ) u_maxpool2d_ofm_agu (
        .clk              (clk),
        .rst_n            (rst_n),

        // Config signals
        .size_out_i       (size_out),
        .channel_out_i    (channel_out),

        // Control signals
        .valid_i          (we_o),

        // Output control signals
        .ofm_agu_done_o   (wr_done),

        // Output address signals
        .ofm_addr_o       (ofm_addr_o)
    );

    wire [1:0] we_dtp;
    assign we_o = &we_dtp;

    genvar i;
    generate
        for (i = 0; i < 2; i = i + 1) begin : gen_maxpool2d_dtp
            maxpool2d_dtp #(
                .MAX_SIZE_OUT (MAX_SIZE_OUT) 
            ) u_dtp_inst (
                .clk          (clk),
                .rst_n        (rst_n),
                
                // Data signals
                .data_i       (ifm_i[i*DATA_WIDTH +: DATA_WIDTH]), 
                .valid_i      (ifm_rd_d1),
                
                // Config signals
                .size_out_i   (size_out),
                
                // Control signals
                .c_en_i       (c_en_d1),
                .mp_en_i      (mp_en_d1),
                .final_col_i  (final_col_d1),
                .final_row_i  (final_row_d1),
                
                // Output signals
                .data_o       (ofm_o[i*DATA_WIDTH +: DATA_WIDTH]),
                .valid_o      (we_dtp[i])
            );
        end
    endgenerate

    maxpool_fsm u_maxpool_fsm (
        .clk              (clk),
        .rst_n            (rst_n),

        // Control signals
        .start_i          (start_i),
        .rd_done_i        (rd_done),
        .wr_done_i        (wr_done),

        // Output control signals
        .ifm_rd_o         (ifm_rd),

        // Status signals
        .done_o           (done_o)
    );

endmodule