import definition::*;

module asff_system_wrapper (
    input  wire        axi_clk,
    input  wire        rst_n,      
    input  wire        axi_rst_n,      

    input  wire        start_i,
    input  wire [$clog2(MAX_SIZE+1)-1:0]    cfg_size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0] cfg_channel_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0] cfg_channel_com_i,

    input  wire                 s_axis_valid_i,
    input  wire [BUS_WIDTH-1:0] s_axis_data_i,
    output wire                 s_axis_ready_o,

    output wire                 m_axis_valid_o,
    output wire [BUS_WIDTH-1:0] m_axis_data_o,
    input  wire                 m_axis_ready_i,

    output wire                 done_o
);

    wire combined_rst_n;
    reg  sync_rst_n_v1;
    reg  sync_rst_n;

    assign combined_rst_n = rst_n && axi_rst_n;

    always @(posedge axi_clk or negedge combined_rst_n) begin
        if (!combined_rst_n) begin
            sync_rst_n_v1 <= 1'b0;
            sync_rst_n    <= 1'b0;
        end else begin
            sync_rst_n_v1 <= 1'b1;
            sync_rst_n    <= sync_rst_n_v1;
        end
    end

    asff_top u_asff_core (
        .clk               (axi_clk),
        .rst_n             (sync_rst_n), 
        .start_i           (start_i),
        .cfg_size_i        (cfg_size_i),
        .cfg_channel_i     (cfg_channel_i),
        .cfg_channel_com_i (cfg_channel_com_i),
        .s_axis_valid_i    (s_axis_valid_i),
        .s_axis_data_i     (s_axis_data_i),
        .s_axis_ready_o    (s_axis_ready_o),
        .m_axis_valid_o    (m_axis_valid_o),
        .m_axis_data_o     (m_axis_data_o),
        .m_axis_ready_i    (m_axis_ready_i),
        .done_o            (done_o)
    );

endmodule