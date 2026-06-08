import definition::*;

module ew_mac_top #(
    parameter EW_MAC_LEVEL = 0,
    parameter MAX_SIZE     = MAX_SIZE,
    parameter MAX_CHANNEL  = MAX_CHANNEL
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]                 ifm_i,
    input  wire [BUS_WIDTH-1:0]                 siw_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     channel_i,

    // Address signals
    output wire [DATA_ADDR_WIDTH-1:0]           ifm_addr_o,
    output wire [DATA_ADDR_WIDTH-1:0]           siw_addr_o,
    output wire [DATA_ADDR_WIDTH-1:0]           ofm_addr_o,
    output wire [$clog2(3)-1:0]                 slot_o,

    // Control signals
    input  wire                                 start_i,

    // Output data signals
    output wire [BUS_WIDTH-1:0]                 data_o,
    output wire                                 we_o,

    // Status signals
    output wire                                 done_o
);

    wire siw_rd, siw_rd_d1;
    wire ifm_rd, ifm_rd_d1;
    wire final_siw, final_siw_d1;
    wire [$clog2(3)-1:0] slot_cnt;
    wire rd_pack_done;
    wire rd_siw_done;
    wire rd_ifm_done;
    wire rd_pixel_done;
    wire wr_done;
    wire ofm_addr_valid;


    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_siw_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(siw_rd),
        .dout(siw_rd_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_ifm_rd (
        .clk(clk),
        .rst_n(rst_n),
        .din(ifm_rd),
        .dout(ifm_rd_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(4)
    ) delay_final_siw (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_siw),
        .dout(final_siw_d1)
    );

    delay_buffer #(
        .DATA_WIDTH(2),
        .DELAY(2)
    ) delay_slot_cnt (
        .clk(clk),
        .rst_n(rst_n),
        .din(slot_cnt),
        .dout(slot_o)
    );


    wire [DATA_ADDR_WIDTH-1:0] gamma_offset;

    assign gamma_offset = size_i * size_i;

    ew_mac_siw_agu #(
        .MAX_SIZE        (MAX_SIZE)
    ) siw_agu_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        
        // Config signals
        .size_i          (size_i),
        .gamma_offset_i  (gamma_offset),
        
        // Control signals
        .start_i         (start_i),
        .rd_i            (siw_rd),
        
        // Output control signals
        .rd_pack_done_o  (rd_pack_done),
        // .rd_done_o       (),
        
        // Output address signals
        .siw_addr_o      (siw_addr_o)
    );

    ew_mac_ifm_agu #(
        .EW_MAC_LEVEL       (EW_MAC_LEVEL),
        .MAX_SIZE           (MAX_SIZE),
        .MAX_CHANNEL        (MAX_CHANNEL)
    ) ifm_agu_inst (
        .clk                (clk),
        .rst_n              (rst_n),
        
        // Config signals
        .size_i             (size_i),
        .channel_i          (channel_i),
        
        // Control signals
        .rd_i               (ifm_rd),
        
        // Output control signals
        .slot_cnt_o         (slot_cnt),
        .final_siw_o        (final_siw),
        .rd_pixel_done_o    (rd_pixel_done),
        .rd_done_o          (rd_ifm_done),
        
        // Output address signals
        .ifm_addr_o         (ifm_addr_o)
    );

    ew_mac_dtp dtp_inst (
        .clk               (clk),
        .rst_n             (rst_n),
        
        // Data signals
        .data_i            (ifm_i),
        .valid_i           (ifm_rd_d1),
        .siw_i             (siw_i),
        .w_valid_i         (siw_rd_d1),
        
        // Control signals
        .final_siw_i       (final_siw_d1),
        
        // Output control signals
        .ofm_addr_valid_o  (ofm_addr_valid),
        
        // Output signals
        .data_o            (data_o),
        .valid_o           (we_o)
    );

    ew_mac_ofm_agu #(
        .MAX_SIZE        (MAX_SIZE),
        .MAX_CHANNEL     (MAX_CHANNEL)
    ) ofm_agu_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        
        // Config signals
        .size_i          (size_i),
        .channel_i       (channel_i),
        
        // Control signals
        .valid_i         (ofm_addr_valid),
        
        // Output control signals
        .wr_done_o       (wr_done),
        
        // Output address signals
        .ofm_addr_o      (ofm_addr_o)
    );

    ew_mac_fsm u_ew_mac_fsm (
        .clk              (clk),
        .rst_n            (rst_n),

        // Control signals
        .start_i          (start_i),
        .rd_pack_done_i   (rd_pack_done),
        .rd_pixel_done_i  (rd_pixel_done),
        .rd_done_i        (rd_ifm_done),
        .wr_done_i        (wr_done),

        // Output control signals
        .siw_rd_o         (siw_rd),
        .ifm_rd_o         (ifm_rd),

        // Status signals
        .done_o           (done_o)
    );

endmodule