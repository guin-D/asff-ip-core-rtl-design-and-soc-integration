import definition::*;

module asff_top (
    input  wire                          clk,
    input  wire                          rst_n,

    // Control signals
    input  wire                          start_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0]        cfg_size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_com_i,

    // AXI4-Stream Slave
    input  wire                 s_axis_valid_i,
    input  wire [BUS_WIDTH-1:0] s_axis_data_i,
    output reg                  s_axis_ready_o,

    // AXI4-Stream Master
    output wire                 m_axis_valid_o,
    output wire [BUS_WIDTH-1:0] m_axis_data_o,
    input  wire                 m_axis_ready_i,

    // Status signals
    output reg                                 done_o
);

    //==============================
    // Process data from AXI-Stream
    //==============================

    reg  [BUS_WIDTH-1:0] data_in;
    reg                  valid_in;
    wire                 axis_fire;

    assign axis_fire = s_axis_valid_i && s_axis_ready_o;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in <= 1'b0;
            data_in  <= 0;
        end 
        else begin
            valid_in <= axis_fire;

            if (axis_fire)
                data_in <= s_axis_data_i;
        end
    end

    //==============================
    // Config size and channel
    //==============================

    reg [$clog2(MAX_SIZE+1)-1:0]        cfg_size_l0;
    reg [$clog2(MAX_SIZE+1)-1:0]        cfg_size_l1;
    reg [$clog2(MAX_SIZE+1)-1:0]        cfg_size_l2;
    reg [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_l0;
    reg [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_l1;
    reg [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_l2;
    reg [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_com;
    reg [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0]     cfg_area_l0;
    reg [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0]     cfg_area_l1;
    reg [$clog2(MAX_SIZE*MAX_SIZE+1)-1:0]     cfg_area_l2;
    reg [$clog2(MAX_SIZE*9+1)-1:0]     cfg_channel_k_l0;
    reg [$clog2(MAX_SIZE*9+1)-1:0]     cfg_channel_k_l1;
    reg [$clog2(MAX_SIZE*9+1)-1:0]     cfg_channel_k_l2;



    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cfg_size_l0     <= 0;
            cfg_size_l1     <= 0;
            cfg_size_l2     <= 0;
            cfg_channel_l0  <= 0;
            cfg_channel_l1  <= 0;
            cfg_channel_l2  <= 0;
            cfg_channel_com <= 0;
            cfg_area_l0     <= 0;
            cfg_area_l1     <= 0;
            cfg_area_l2     <= 0;
            cfg_channel_k_l0   <= 0;
            cfg_channel_k_l1   <= 0;
            cfg_channel_k_l2   <= 0;

        end 
        else begin
            if (start_i) begin
                cfg_size_l0     <= cfg_size_i;
                cfg_size_l1     <= cfg_size_i << 1;
                cfg_size_l2     <= cfg_size_i << 2;
                cfg_channel_l0  <= cfg_channel_i << 2;
                cfg_channel_l1  <= cfg_channel_i << 1;
                cfg_channel_l2  <= cfg_channel_i;
                cfg_channel_com <= cfg_channel_com_i;
                cfg_area_l0     <= cfg_size_i * cfg_size_i;
                cfg_area_l1     <= (cfg_size_i << 1) * (cfg_size_i << 1);
                cfg_area_l2     <= (cfg_size_i << 2) * (cfg_size_i << 2);
                cfg_channel_k_l0   <= (cfg_channel_i << 2) * 9;
                cfg_channel_k_l1   <= (cfg_channel_i << 1) * 9;
                cfg_channel_k_l2   <= cfg_channel_i * 9;
            end
        end
    end

    //==============================
    // BUFFER
    //==============================

    reg                       wea_x0, wea_x1, wea_x2;
    reg [1:0]                 slot_in_x0, slot_in_x1, slot_in_x2;
    reg [1:0]                 slot_out_x0, slot_out_x1, slot_out_x2;
    reg [DATA_ADDR_WIDTH-1:0] addra_x0, addra_x1, addra_x2;
    reg [DATA_ADDR_WIDTH-1:0] addrb_x0, addrb_x1, addrb_x2;
    reg [BUS_WIDTH-1:0]       dina_x0, dina_x1, dina_x2;
    wire [BUS_WIDTH-1:0]       doutb_x0, doutb_x1, doutb_x2;

    x_buf_ram #(
        .MAX_SIZE(MAX_HW_L0),
        .MAX_CHANNEL(MAX_CHANNEL_L0),
        .BUF_LEVEL(0)
    ) x0_buf_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cfg_size_i(cfg_size_l0),
        .cfg_channel_i(cfg_channel_l0),
        .wea(wea_x0),
        .slot_in(slot_in_x0),
        .slot_out(slot_out_x0),
        .addra(addra_x0),
        .dina(dina_x0),
        .addrb(addrb_x0),
        .doutb(doutb_x0)
    );

    x_buf_ram #(
        .MAX_SIZE(MAX_HW_L1),
        .MAX_CHANNEL(MAX_CHANNEL_L1),
        .BUF_LEVEL(1)
    ) x1_buf_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cfg_size_i(cfg_size_l1),
        .cfg_channel_i(cfg_channel_l1),
        .wea(wea_x1),
        .slot_in(slot_in_x1),
        .slot_out(slot_out_x1),
        .addra(addra_x1),
        .dina(dina_x1),
        .addrb(addrb_x1),
        .doutb(doutb_x1)
    );

    x_buf_ram #(
        .MAX_SIZE(MAX_HW_L2),
        .MAX_CHANNEL(MAX_CHANNEL_L2),
        .BUF_LEVEL(2)
    ) x2_buf_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .cfg_size_i(cfg_size_l2),
        .cfg_channel_i(cfg_channel_l2),
        .wea(wea_x2),
        .slot_in(slot_in_x2),
        .slot_out(slot_out_x2),
        .addra(addra_x2),
        .dina(dina_x2),
        .addrb(addrb_x2),
        .doutb(doutb_x2)
    );

    reg                         we_w0, we_w0p;
    reg [WEIGHT_ADDR_WIDTH-1:0] addr_w0, addr_w0p;
    reg [BUS_WIDTH-1:0]         din_w0, din_w0p;
    wire [BUS_WIDTH-1:0]         dout_w0, dout_w0p;

    reg                         we_w1, we_w1p;
    reg [WEIGHT_ADDR_WIDTH-1:0] addr_w1, addr_w1p;
    reg [BUS_WIDTH-1:0]         din_w1, din_w1p;
    wire [BUS_WIDTH-1:0]         dout_w1, dout_w1p;

    reg                         we_w2, we_w2p;
    reg [WEIGHT_ADDR_WIDTH-1:0] addr_w2, addr_w2p;
    reg [BUS_WIDTH-1:0]         din_w2, din_w2p;
    wire [BUS_WIDTH-1:0]         dout_w2, dout_w2p;

    W_BUF_RAM_0_PING w_buf_ram_ping (
        .clka  (clk),        
        .wea   (we_w0),         
        .addra (addr_w0),      
        .dina  (din_w0),        
        .douta (dout_w0)       
    );

    W_BUF_RAM_0_PONG w_buf_ram_pong (
        .clka  (clk),        
        .wea   (we_w0p),         
        .addra (addr_w0p),      
        .dina  (din_w0p),        
        .douta (dout_w0p)        
    );

    W_BUF_RAM_1 w_buf_ram_1_ping (
        .clka  (clk),        
        .wea   (we_w1),         
        .addra (addr_w1),      
        .dina  (din_w1),        
        .douta (dout_w1)       
    );

    W_BUF_RAM_1 w_buf_ram_1_pong (
        .clka  (clk),        
        .wea   (we_w1p),         
        .addra (addr_w1p),      
        .dina  (din_w1p),        
        .douta (dout_w1p)        
    );

    W_BUF_RAM_2 w_buf_ram_2_ping (
        .clka  (clk),        
        .wea   (we_w2),         
        .addra (addr_w2),      
        .dina  (din_w2),        
        .douta (dout_w2)       
    );

    W_BUF_RAM_2 w_buf_ram_2_pong (
        .clka  (clk),        
        .wea   (we_w2p),         
        .addra (addr_w2p),      
        .dina  (din_w2p),        
        .douta (dout_w2p)        
    );

    reg  [1:0]                  slot_t0;
    reg                         we_t0;
    reg  [DATA_ADDR_WIDTH-1:0]  addr_t0;
    reg  [BUS_WIDTH-1:0]        din_t0;
    wire [BUS_WIDTH-1:0]        dout_t0;

    reg  [1:0]                  slot_t1;
    reg                         we_t1;
    reg  [DATA_ADDR_WIDTH-1:0]  addr_t1;
    reg  [BUS_WIDTH-1:0]        din_t1;
    wire [BUS_WIDTH-1:0]        dout_t1;

    reg  [1:0]                  slot_t2;
    reg                         we_t2;
    reg  [DATA_ADDR_WIDTH-1:0]  addr_t2;
    reg  [BUS_WIDTH-1:0]        din_t2;
    wire [BUS_WIDTH-1:0]        dout_t2;

    temp_buf_ram #(
        .MAX_SIZE(MAX_HW_L0),
        .BUF_LEVEL(0)
    ) t0_buf_ram_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .cfg_size_i (cfg_size_l0),
        .we         (we_t0),
        .slot       (slot_t0),
        .addr       (addr_t0),
        .din        (din_t0),
        .dout       (dout_t0)
    );

    temp_buf_ram #(
        .MAX_SIZE(MAX_HW_L1),
        .BUF_LEVEL(1)
    ) t1_buf_ram_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .cfg_size_i (cfg_size_l1),
        .we         (we_t1),
        .slot       (slot_t1),
        .addr       (addr_t1),
        .din        (din_t1),
        .dout       (dout_t1)
    );

    temp_buf_ram #(
        .MAX_SIZE(MAX_HW_L2),
        .BUF_LEVEL(2)
    ) t2_buf_ram_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .cfg_size_i (cfg_size_l2),
        .we         (we_t2),
        .slot       (slot_t2),
        .addr       (addr_t2),
        .din        (din_t2),
        .dout       (dout_t2)
    );

    reg                         wea_siw0, wea_siw1, wea_siw2;
    reg  [DATA_ADDR_WIDTH-1:0]  addra_siw0, addra_siw1, addra_siw2;
    reg  [BUS_WIDTH-1:0]        dina_siw0, dina_siw1, dina_siw2;
    reg  [DATA_ADDR_WIDTH-1:0]  addrb_siw0, addrb_siw1, addrb_siw2;
    wire [BUS_WIDTH-1:0]        doutb_siw0, doutb_siw1, doutb_siw2;

    SIW_BUF_RAM_0 siw0_buf_ram_inst (
        .clka  (clk),
        .wea   (wea_siw0),
        .addra (addra_siw0),
        .dina  (dina_siw0),
        .clkb  (clk),
        .addrb (addrb_siw0),
        .doutb (doutb_siw0)
    );

    SIW_BUF_RAM_1 siw1_buf_ram_inst (
        .clka  (clk),
        .wea   (wea_siw1),
        .addra (addra_siw1),
        .dina  (dina_siw1),
        .clkb  (clk),
        .addrb (addrb_siw1),
        .doutb (doutb_siw1)
    );

    SIW_BUF_RAM_2 siw2_buf_ram_inst (
        .clka  (clk),
        .wea   (wea_siw2),
        .addra (addra_siw2),
        .dina  (dina_siw2),
        .clkb  (clk),
        .addrb (addrb_siw2),
        .doutb (doutb_siw2)
    );

    //==============================
    // CALCULATION MODULE
    //==============================

    // --- Maxpool Top Signals ---
    
    reg [BUS_WIDTH-1:0]                mp_ifm;
    reg [$clog2(MAX_HW_L2+1)-1:0]      mp_size_in;
    reg [$clog2(MAX_CHANNEL_L2+1)-1:0] mp_channel_in;
    wire [DATA_ADDR_WIDTH-1:0]          mp_ifm_addr;
    wire [DATA_ADDR_WIDTH-1:0]          mp_ofm_addr;
    reg                                mp_start;
    wire [BUS_WIDTH-1:0]                mp_ofm;
    wire                                mp_we;
    wire                                mp_done;

    // --- Instance ---
    maxpool_top #(
        .MAX_SIZE_IN  (MAX_HW_L2),
        .MAX_SIZE_OUT (MAX_HW_L1),
        .MAX_CHANNEL  (MAX_CHANNEL_L2)
    ) u_maxpool_top (
        .clk           (clk),           
        .rst_n         (rst_n),         
        .ifm_i         (mp_ifm),
        .size_in_i     (mp_size_in),
        .channel_in_i  (mp_channel_in),
        .ifm_addr_o    (mp_ifm_addr),
        .ofm_addr_o    (mp_ofm_addr),
        .start_i       (mp_start),
        .ofm_o         (mp_ofm),
        .we_o          (mp_we),
        .done_o        (mp_done)
    );

    

    reg  [BUS_WIDTH-1:0]                cv_ifm_0;
    reg  [BUS_WIDTH-1:0]                cv_weight_0;
    reg                                 cv_mode_0;
    reg                                 cv_stride_2_en_0;
    reg  [1:0]                          cv_upscaled_mode_0;
    reg                                 cv_norm_en_0;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_in_0;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_in_0;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_out_0;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_out_0;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ifm_addr_0;
    wire [WEIGHT_ADDR_WIDTH-1:0]        cv_weight_addr_0;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ofm_addr_0;
    reg                                 cv_start_0;
    wire [BUS_WIDTH-1:0]                cv_ofm_0;
    wire                                cv_we_0;
    wire                                cv_done_0;

    // --- Conv2d Unit 1 ---
    reg  [BUS_WIDTH-1:0]                cv_ifm_1;
    reg  [BUS_WIDTH-1:0]                cv_weight_1;
    reg                                 cv_mode_1;
    reg                                 cv_stride_2_en_1;
    reg  [1:0]                          cv_upscaled_mode_1;
    reg                                 cv_norm_en_1;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_in_1;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_in_1;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_out_1;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_out_1;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ifm_addr_1;
    wire [WEIGHT_ADDR_WIDTH-1:0]        cv_weight_addr_1;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ofm_addr_1;
    reg                                 cv_start_1;
    wire [BUS_WIDTH-1:0]                cv_ofm_1;
    wire                                cv_we_1;
    wire                                cv_done_1;

    // --- Conv2d Unit 2 ---
    reg  [BUS_WIDTH-1:0]                cv_ifm_2;
    reg  [BUS_WIDTH-1:0]                cv_weight_2;
    reg                                 cv_mode_2;
    reg                                 cv_stride_2_en_2;
    reg  [1:0]                          cv_upscaled_mode_2;
    reg                                 cv_norm_en_2;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_in_2;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_in_2;
    reg  [$clog2(MAX_SIZE+1)-1:0]       cv_size_out_2;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]    cv_channel_out_2;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ifm_addr_2;
    wire [WEIGHT_ADDR_WIDTH-1:0]        cv_weight_addr_2;
    wire [DATA_ADDR_WIDTH-1:0]          cv_ofm_addr_2;
    reg                                 cv_start_2;
    wire [BUS_WIDTH-1:0]                cv_ofm_2;
    wire                                cv_we_2;
    wire                                cv_done_2;
    reg                                 cv_ack;

    conv2d_top #(
        .MAX_SIZE               (MAX_SIZE),
        .MAX_CHANNEL            (MAX_CHANNEL),
        .HAS_UPSCALED_INTERFACE (0)
    ) conv2d_0_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .ifm_i           (cv_ifm_0),
        .weight_i        (cv_weight_0),
        .mode_i          (cv_mode_0),
        .stride_2_en_i   (cv_stride_2_en_0),
        .upscaled_mode_i (cv_upscaled_mode_0),
        .norm_en_i       (cv_norm_en_0),
        .size_in_i       (cv_size_in_0),
        .channel_in_i    (cv_channel_in_0),
        .size_out_i      (cv_size_out_0),
        .channel_out_i   (cv_channel_out_0),
        .ifm_addr_o      (cv_ifm_addr_0),
        .weight_addr_o   (cv_weight_addr_0),
        .ofm_addr_o      (cv_ofm_addr_0),
        .start_i         (cv_start_0),
        .ack_i           (cv_ack),
        .ofm_o           (cv_ofm_0),
        .we_o            (cv_we_0),
        .done_o          (cv_done_0)
    );

    conv2d_top #(
        .MAX_SIZE               (MAX_SIZE),
        .MAX_CHANNEL            (MAX_CHANNEL),
        .HAS_UPSCALED_INTERFACE (1)
    ) conv2d_1_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .ifm_i           (cv_ifm_1),
        .weight_i        (cv_weight_1),
        .mode_i          (cv_mode_1),
        .stride_2_en_i   (cv_stride_2_en_1),
        .upscaled_mode_i (cv_upscaled_mode_1),
        .norm_en_i       (cv_norm_en_1),
        .size_in_i       (cv_size_in_1),
        .channel_in_i    (cv_channel_in_1),
        .size_out_i      (cv_size_out_1),
        .channel_out_i   (cv_channel_out_1),
        .ifm_addr_o      (cv_ifm_addr_1),
        .weight_addr_o   (cv_weight_addr_1),
        .ofm_addr_o      (cv_ofm_addr_1),
        .start_i         (cv_start_1),
        .ack_i           (cv_ack),
        .ofm_o           (cv_ofm_1),
        .we_o            (cv_we_1),
        .done_o          (cv_done_1)
    );

    conv2d_top #(
        .MAX_SIZE               (MAX_SIZE),
        .MAX_CHANNEL            (MAX_CHANNEL),
        .HAS_UPSCALED_INTERFACE (1)
    ) conv2d_2_inst (
        .clk             (clk),
        .rst_n           (rst_n),
        .ifm_i           (cv_ifm_2),
        .weight_i        (cv_weight_2),
        .mode_i          (cv_mode_2),
        .stride_2_en_i   (cv_stride_2_en_2),
        .upscaled_mode_i (cv_upscaled_mode_2),
        .norm_en_i       (cv_norm_en_2),
        .size_in_i       (cv_size_in_2),
        .channel_in_i    (cv_channel_in_2),
        .size_out_i      (cv_size_out_2),
        .channel_out_i   (cv_channel_out_2),
        .ifm_addr_o      (cv_ifm_addr_2),
        .weight_addr_o   (cv_weight_addr_2),
        .ofm_addr_o      (cv_ofm_addr_2),
        .start_i         (cv_start_2),
        .ack_i           (cv_ack),
        .ofm_o           (cv_ofm_2),
        .we_o            (cv_we_2),
        .done_o          (cv_done_2)
    );

    reg  [BUS_WIDTH-1:0]        ifm_sm0, ifm_sm1, ifm_sm2;
    reg  [$clog2(MAX_SIZE+1)-1:0] size_sm0, size_sm1, size_sm2;
    wire [DATA_ADDR_WIDTH-1:0]  ifm_addr_sm0, ifm_addr_sm1, ifm_addr_sm2;
    wire [DATA_ADDR_WIDTH-1:0]  siw_addr_sm0, siw_addr_sm1, siw_addr_sm2;
    reg                         start_sm0, start_sm1, start_sm2;
    wire [BUS_WIDTH-1:0]        data_sm0, data_sm1, data_sm2;
    wire                        we_sm0, we_sm1, we_sm2;
    wire                        done_sm0, done_sm1, done_sm2;

    softmax_top #(.MAX_SIZE(MAX_SIZE)) softmax_0_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_sm0),
        .size_i     (size_sm0),
        .ifm_addr_o (ifm_addr_sm0),
        .siw_addr_o (siw_addr_sm0),
        .start_i    (start_sm0),
        .data_o     (data_sm0),
        .we_o       (we_sm0),
        .done_o     (done_sm0)
    );

    softmax_top #(.MAX_SIZE(MAX_SIZE)) softmax_1_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_sm1),
        .size_i     (size_sm1),
        .ifm_addr_o (ifm_addr_sm1),
        .siw_addr_o (siw_addr_sm1),
        .start_i    (start_sm1),
        .data_o     (data_sm1),
        .we_o       (we_sm1),
        .done_o     (done_sm1)
    );

    softmax_top #(.MAX_SIZE(MAX_SIZE)) softmax_2_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_sm2),
        .size_i     (size_sm2),
        .ifm_addr_o (ifm_addr_sm2),
        .siw_addr_o (siw_addr_sm2),
        .start_i    (start_sm2),
        .data_o     (data_sm2),
        .we_o       (we_sm2),
        .done_o     (done_sm2)
    );

    reg  [BUS_WIDTH-1:0]        ifm_ew0, ifm_ew1, ifm_ew2;
    reg  [BUS_WIDTH-1:0]        siw_ew0, siw_ew1, siw_ew2;
    reg  [$clog2(MAX_SIZE+1)-1:0] size_ew0, size_ew1, size_ew2;
    reg  [$clog2(MAX_CHANNEL+1)-1:0] channel_ew0, channel_ew1, channel_ew2;
    wire [DATA_ADDR_WIDTH-1:0]  ifm_addr_ew0, ifm_addr_ew1, ifm_addr_ew2;
    wire [DATA_ADDR_WIDTH-1:0]  siw_addr_ew0, siw_addr_ew1, siw_addr_ew2;
    wire [DATA_ADDR_WIDTH-1:0]  ofm_addr_ew0, ofm_addr_ew1, ofm_addr_ew2;
    wire [$clog2(3)-1:0]        slot_ew0, slot_ew1, slot_ew2;
    reg                         start_ew0, start_ew1, start_ew2;
    wire [BUS_WIDTH-1:0]        data_ew0, data_ew1, data_ew2;
    wire                        we_ew0, we_ew1, we_ew2;
    wire                        done_ew0, done_ew1, done_ew2;

    ew_mac_top #(
        .EW_MAC_LEVEL(0), 
        .MAX_SIZE(MAX_SIZE), 
        .MAX_CHANNEL(MAX_CHANNEL)
    ) ew_mac_0_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_ew0),
        .siw_i      (siw_ew0),
        .size_i     (size_ew0),
        .channel_i  (channel_ew0),
        .ifm_addr_o (ifm_addr_ew0),
        .siw_addr_o (siw_addr_ew0),
        .ofm_addr_o (ofm_addr_ew0),
        .slot_o     (slot_ew0),
        .start_i    (start_ew0),
        .data_o     (data_ew0),
        .we_o       (we_ew0),
        .done_o     (done_ew0)
    );

    ew_mac_top #(
        .EW_MAC_LEVEL(1), 
        .MAX_SIZE(MAX_SIZE), 
        .MAX_CHANNEL(MAX_CHANNEL)
    ) ew_mac_1_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_ew1),
        .siw_i      (siw_ew1),
        .size_i     (size_ew1),
        .channel_i  (channel_ew1),
        .ifm_addr_o (ifm_addr_ew1),
        .siw_addr_o (siw_addr_ew1),
        .ofm_addr_o (ofm_addr_ew1),
        .slot_o     (slot_ew1),
        .start_i    (start_ew1),
        .data_o     (data_ew1),
        .we_o       (we_ew1),
        .done_o     (done_ew1)
    );

    ew_mac_top #(
        .EW_MAC_LEVEL(2), 
        .MAX_SIZE(MAX_SIZE), 
        .MAX_CHANNEL(MAX_CHANNEL)
    ) ew_mac_2_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .ifm_i      (ifm_ew2),
        .siw_i      (siw_ew2),
        .size_i     (size_ew2),
        .channel_i  (channel_ew2),
        .ifm_addr_o (ifm_addr_ew2),
        .siw_addr_o (siw_addr_ew2),
        .ofm_addr_o (ofm_addr_ew2),
        .slot_o     (slot_ew2),
        .start_i    (start_ew2),
        .data_o     (data_ew2),
        .we_o       (we_ew2),
        .done_o     (done_ew2)
    );

    //==============================
    // ADDRESS COUNTER
    //==============================

    reg [GLOBAL_ADDR_WIDTH:0] max_addr;
    reg [GLOBAL_ADDR_WIDTH:0] l_max_addr;
    reg [GLOBAL_ADDR_WIDTH:0] s_max_addr;
    reg [8:0]                   mux_load;
    wire                         cnt_max;
    wire [GLOBAL_ADDR_WIDTH-1:0] addr_cnt;
    reg                         en_cnt;

    dynamic_counter #(
        .START_VALUE(0),
        .COUNT_WIDTH(GLOBAL_ADDR_WIDTH)
    ) addr_counter (
        .clk(clk),
        .rst_n(rst_n),
        .inc(en_cnt),
        .max_value((max_addr/NUM_LANE)-1),
        .max_tick(cnt_max),
        .value(addr_cnt)
    );

    //==============================
    // FIFO OUT
    //==============================

    reg                   fifo_wr_en;
    reg  [BUS_WIDTH-1:0]  fifo_din;
    wire                  fifo_full;
    reg                   fifo_rd_en;
    wire [BUS_WIDTH-1:0]  fifo_dout;
    wire                  fifo_empty;

    sync_fifo fwft_fifo_inst (
        .clk   (clk),
        .rst_n (rst_n),
        .wr_en (fifo_wr_en),
        .din   (fifo_din),
        .full  (fifo_full),
        .rd_en (fifo_rd_en),
        .dout  (fifo_dout),
        .empty (fifo_empty)
    );

    //==============================
    // FSM TOP
    //==============================

    reg start_load;
    reg start_store;
    reg valid_out;
    reg ldone;
    reg sdone;
    reg [GLOBAL_ADDR_WIDTH:0] max_addr_s0;
    reg [GLOBAL_ADDR_WIDTH:0] max_addr_s1;
    reg [GLOBAL_ADDR_WIDTH:0] max_addr_s2;
    reg [8:0]                 mux_load_s0;
    reg [8:0]                 mux_load_s1;
    reg [8:0]                 mux_load_s2;
    reg l_ack;
    reg [GLOBAL_ADDR_WIDTH:0] saddrb_x0, saddrb_x1, saddrb_x2;

    typedef enum reg [3:0] { 
        IDLE,
        S_0,
        S_1,
        S_2,
        S_3,
        S_4,
        S_5,
        S_6,
        S_7,
        S_8,
        S_9,
        S_10,
        DONE
    } state_t;

    (* max_fanout = 5 *) state_t state;
    state_t next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            l_ack <= 0;
            cv_ack <= 0;
        end else begin
            
            l_ack <= 0;
            cv_ack <= 0;
            if (state != next_state) begin
                l_ack <= 1;
                cv_ack <= 1;
            end
            if (l_ack && !(state == IDLE)) begin
                state <= next_state;
            end else if (state == IDLE) begin
                state <= next_state;
            end
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: if (start_i) next_state = S_0;
            S_0: if (ldone) begin
                next_state = S_1;
            end 
            S_1: if (ldone && mp_done) begin
                next_state = S_2;
            end 
            S_2: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) begin
                next_state = S_3;
            end 
            S_3: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) begin
                next_state = S_4;
            end
            S_4: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) begin
                next_state = S_5;
            end 
            S_5: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) begin
                next_state = S_6;
            end 
            S_6: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) begin
                next_state = S_7;
            end
            S_7: if (ldone && cv_done_0 && cv_done_1 && cv_done_2) next_state = S_8;
            S_8: if (done_sm0 && done_sm1 && done_sm2) next_state = S_9;
            S_9: if (done_ew0 && done_ew1 && done_ew2) next_state = S_10;
            S_10: if (sdone) next_state = DONE;

            default: begin
                next_state = state;
            end
        endcase
    end

    always @(*) begin
        start_load  = 0;
        start_store = 0;
        max_addr_s0 = 0;
        max_addr_s1 = 0;
        max_addr_s2 = 0;
        mux_load_s0 = 0;
        mux_load_s1 = 0;
        mux_load_s2 = 0;
        en_cnt      = 0;
        max_addr    = 0;

        slot_in_x0  = 0;
        slot_in_x1  = 0;
        slot_in_x2  = 0;
        slot_out_x0 = 0;
        slot_out_x1 = 0;
        slot_out_x2 = 0;
        wea_x0      = 0;
        wea_x1      = 0;
        wea_x2      = 0;
        addra_x0    = 0;
        addra_x1    = 0;
        addra_x2    = 0;
        dina_x0     = 0;
        dina_x1     = 0;
        dina_x2     = 0;
        addrb_x0    = 0;
        addrb_x1    = 0;
        addrb_x2    = 0;

        we_w0       = 0;
        we_w1       = 0;
        we_w2       = 0;
        addr_w0     = 0;
        addr_w1     = 0;
        addr_w2     = 0;
        din_w0      = 0;
        din_w1      = 0;
        din_w2      = 0;
        we_w0p      = 0;
        we_w1p      = 0;
        we_w2p      = 0;
        addr_w0p    = 0;
        addr_w1p    = 0;
        addr_w2p    = 0;
        din_w0p     = 0;
        din_w1p     = 0;
        din_w2p     = 0;

        slot_t0  = 2'b00;
        we_t0    = 1'b0;
        addr_t0  = {DATA_ADDR_WIDTH{1'b0}};
        din_t0   = {BUS_WIDTH{1'b0}};
        slot_t1  = 2'b00;
        we_t1    = 1'b0;
        addr_t1  = {DATA_ADDR_WIDTH{1'b0}};
        din_t1   = {BUS_WIDTH{1'b0}};
        slot_t2  = 2'b00;
        we_t2    = 1'b0;
        addr_t2  = {DATA_ADDR_WIDTH{1'b0}};
        din_t2   = {BUS_WIDTH{1'b0}};

        wea_siw0   = 0;
        addra_siw0 = 0;
        dina_siw0  = 0;
        addrb_siw0 = 0;
        wea_siw1   = 0;
        addra_siw1 = 0;
        dina_siw1  = 0;
        addrb_siw1 = 0;
        wea_siw2   = 0;
        addra_siw2 = 0;
        dina_siw2  = 0;
        addrb_siw2 = 0;

        mp_start      = 0;
        mp_ifm        = 0;
        mp_size_in    = 0;
        mp_channel_in = 0;

        // --- Conv2d Unit 0 Defaults ---
        cv_ifm_0           = 0;
        cv_weight_0        = 0;
        cv_mode_0          = 0;
        cv_stride_2_en_0   = 0;
        cv_upscaled_mode_0 = 0;
        cv_norm_en_0       = 0;
        cv_size_in_0       = 0;
        cv_channel_in_0    = 0;
        cv_size_out_0      = 0;
        cv_channel_out_0   = 0;
        cv_start_0         = 0;

        // --- Conv2d Unit 1 Defaults ---
        cv_ifm_1           = 0;
        cv_weight_1        = 0;
        cv_mode_1          = 0;
        cv_stride_2_en_1   = 0;
        cv_upscaled_mode_1 = 0;
        cv_norm_en_1       = 0;
        cv_size_in_1       = 0;
        cv_channel_in_1    = 0;
        cv_size_out_1      = 0;
        cv_channel_out_1   = 0;
        cv_start_1         = 0;

        // --- Conv2d Unit 2 Defaults ---
        cv_ifm_2           = 0;
        cv_weight_2        = 0;
        cv_mode_2          = 0;
        cv_stride_2_en_2   = 0;
        cv_upscaled_mode_2 = 0;
        cv_norm_en_2       = 0;
        cv_size_in_2       = 0;
        cv_channel_in_2    = 0;
        cv_size_out_2      = 0;
        cv_channel_out_2   = 0;
        cv_start_2         = 0;

        ifm_sm0   = 0;
        size_sm0  = 0;
        start_sm0 = 0;
        ifm_sm1   = 0;
        size_sm1  = 0;
        start_sm1 = 0;
        ifm_sm2   = 0;
        size_sm2  = 0;
        start_sm2 = 0;

        ifm_ew0     = 0;
        siw_ew0     = 0;
        size_ew0    = 0;
        channel_ew0 = 0;
        start_ew0   = 0;
        ifm_ew1     = 0;
        siw_ew1     = 0;
        size_ew1    = 0;
        channel_ew1 = 0;
        start_ew1   = 0;
        ifm_ew2     = 0;
        siw_ew2     = 0;
        size_ew2    = 0;
        channel_ew2 = 0;
        start_ew2   = 0;

        done_o      = 0;

        case (state)
            S_0: begin 
                // LOAD INPUT
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = cfg_area_l0 * cfg_channel_l0;
                max_addr_s1 = cfg_area_l1 * cfg_channel_l1;
                max_addr_s2 = cfg_area_l2 * cfg_channel_l2;
                mux_load_s0 = 9'b000000001;
                mux_load_s1 = 9'b000000010;
                mux_load_s2 = 9'b000000100;
                slot_in_x0  = 0;
                slot_in_x1  = 1;
                slot_in_x2  = 2;
                wea_x0      = mux_load[0] && valid_in;
                wea_x1      = mux_load[1] && valid_in;
                wea_x2      = mux_load[2] && valid_in;
                addra_x0    = (mux_load[0]) ? addr_cnt : 0;
                addra_x1    = (mux_load[1]) ? addr_cnt : 0;
                addra_x2    = (mux_load[2]) ? addr_cnt : 0;
                dina_x0     = (mux_load[0]) ? data_in : 0;
                dina_x1     = (mux_load[1]) ? data_in : 0;
                dina_x2     = (mux_load[2]) ? data_in : 0;
            end

            S_1: begin
                // LOAD WPING
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_l0 + 2'd2) * cfg_channel_l1;
                max_addr_s1 = (cfg_channel_k_l2 + 2'd2) * cfg_channel_l0;
                max_addr_s2 = (cfg_channel_l1 + 2'd2) * cfg_channel_l2;
                mux_load_s0 = 9'b000001000;
                mux_load_s1 = 9'b000010000;
                mux_load_s2 = 9'b000100000;
                we_w0       = mux_load[3] && valid_in;
                we_w1       = mux_load[4] && valid_in;
                we_w2       = mux_load[5] && valid_in;
                addr_w0     = (mux_load[3]) ? addr_cnt : 0;
                addr_w1     = (mux_load[4]) ? addr_cnt : 0;
                addr_w2     = (mux_load[5]) ? addr_cnt : 0;
                din_w0      = (mux_load[3]) ? data_in : 0;
                din_w1      = (mux_load[4]) ? data_in : 0;
                din_w2      = (mux_load[5]) ? data_in : 0;

                // MAXPOOL
                addrb_x2      = mp_ifm_addr;
                slot_out_x2   = 2;

                mp_start      = 1;
                mp_ifm        = doutb_x2;
                mp_size_in    = cfg_size_l2;
                mp_channel_in = cfg_channel_l2;

                slot_t2       = 0;
                we_t2        = mp_we;
                addr_t2      = mp_ofm_addr;
                din_t2       = mp_ofm;
            end

            S_2: begin
                // LOAD WPONG
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_l0 + 2'd2) * cfg_channel_l2;
                max_addr_s1 = (cfg_channel_k_l1 + 2'd2) * cfg_channel_l0;
                max_addr_s2 = (cfg_channel_k_l2 + 2'd2) * cfg_channel_l1;
                mux_load_s0 = 9'b001000000;
                mux_load_s1 = 9'b010000000;
                mux_load_s2 = 9'b100000000;
                we_w0p      = mux_load[6] && valid_in;
                we_w1p      = mux_load[7] && valid_in;
                we_w2p      = mux_load[8] && valid_in;
                addr_w0p    = (mux_load[6]) ? addr_cnt : 0;
                addr_w1p    = (mux_load[7]) ? addr_cnt : 0;
                addr_w2p    = (mux_load[8]) ? addr_cnt : 0;
                din_w0p     = (mux_load[6]) ? data_in : 0;
                din_w1p     = (mux_load[7]) ? data_in : 0;
                din_w2p     = (mux_load[8]) ? data_in : 0;

                // CONV 0
                slot_out_x0 = 0;
                addrb_x0    = cv_ifm_addr_0;

                addr_w0     = cv_weight_addr_0;

                cv_ifm_0           = doutb_x0;
                cv_weight_0        = dout_w0;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_l1;
                cv_start_0         = 1;

                wea_x1             = cv_we_0;
                slot_in_x1         = 0;
                addra_x1           = cv_ofm_addr_0;
                dina_x1            = cv_ofm_0;

                // CONV 1
                slot_t2 = 0;
                addr_t2    = cv_ifm_addr_1;

                addr_w1     = cv_weight_addr_1;

                cv_ifm_1           = dout_t2;
                cv_weight_1        = dout_w1;
                cv_mode_1          = 1;
                cv_stride_2_en_1   = 1;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l2;
                cv_size_out_1      = cfg_size_l0;
                cv_channel_out_1   = cfg_channel_l0;
                cv_start_1         = 1;

                wea_x0             = cv_we_1;
                slot_in_x0         = 2;
                addra_x0           = cv_ofm_addr_1;
                dina_x0            = cv_ofm_1;

                // CONV 2
                slot_out_x1 = 1;
                addrb_x1    = cv_ifm_addr_2;

                addr_w2     = cv_weight_addr_2;

                cv_ifm_2           = doutb_x1;
                cv_weight_2        = dout_w2;
                cv_mode_2          = 0;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 0;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l1;
                cv_channel_in_2    = cfg_channel_l1;
                cv_size_out_2      = cfg_size_l1;
                cv_channel_out_2   = cfg_channel_l2;
                cv_start_2         = 1;

                wea_x2             = cv_we_2;
                slot_in_x2         = 1;
                addra_x2           = cv_ofm_addr_2;
                dina_x2            = cv_ofm_2;
            end

            S_3: begin
                // LOAD WPING
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_l0 + 2'd2) * cfg_channel_com;
                max_addr_s1 = (cfg_channel_l1 + 2'd2) * cfg_channel_com;
                max_addr_s2 = (cfg_channel_l2 + 2'd2) * cfg_channel_com;
                mux_load_s0 = 9'b000001000;
                mux_load_s1 = 9'b000010000;
                mux_load_s2 = 9'b000100000;
                we_w0       = mux_load[3] && valid_in;
                we_w1       = mux_load[4] && valid_in;
                we_w2       = mux_load[5] && valid_in;
                addr_w0     = (mux_load[3]) ? addr_cnt : 0;
                addr_w1     = (mux_load[4]) ? addr_cnt : 0;
                addr_w2     = (mux_load[5]) ? addr_cnt : 0;
                din_w0      = (mux_load[3]) ? data_in : 0;
                din_w1      = (mux_load[4]) ? data_in : 0;
                din_w2      = (mux_load[5]) ? data_in : 0;

                // CONV 0
                slot_out_x0 = 0;
                addrb_x0    = cv_ifm_addr_0;

                addr_w0p     = cv_weight_addr_0;

                cv_ifm_0           = doutb_x0;
                cv_weight_0        = dout_w0p;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_l2;
                cv_start_0         = 1;

                wea_x2             = cv_we_0;
                slot_in_x2         = 0;
                addra_x2           = cv_ofm_addr_0;
                dina_x2            = cv_ofm_0;

                // CONV 1
                slot_out_x1 = 1;
                addrb_x1    = cv_ifm_addr_1;

                addr_w1p     = cv_weight_addr_1;

                cv_ifm_1           = doutb_x1;
                cv_weight_1        = dout_w1p;
                cv_mode_1          = 1;
                cv_stride_2_en_1   = 1;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l1;
                cv_size_out_1      = cfg_size_l0;
                cv_channel_out_1   = cfg_channel_l0;
                cv_start_1         = 1;

                wea_x0             = cv_we_1;
                slot_in_x0         = 1;
                addra_x0           = cv_ofm_addr_1;
                dina_x0            = cv_ofm_1;

                // CONV 2
                slot_out_x2 = 2;
                addrb_x2    = cv_ifm_addr_2;

                addr_w2p     = cv_weight_addr_2;

                cv_ifm_2           = doutb_x2;
                cv_weight_2        = dout_w2p;
                cv_mode_2          = 1;
                cv_stride_2_en_2   = 1;
                cv_upscaled_mode_2 = 0;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_l2;
                cv_size_out_2      = cfg_size_l1;
                cv_channel_out_2   = cfg_channel_l1;
                cv_start_2         = 1;

                wea_x1             = cv_we_2;
                slot_in_x1         = 2;
                addra_x1           = cv_ofm_addr_2;
                dina_x1            = cv_ofm_2;
            end

            S_4: begin
                // LOAD WPONG
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_l0 + 2'd2) * cfg_channel_com;
                max_addr_s1 = (cfg_channel_l1 + 2'd2) * cfg_channel_com;
                max_addr_s2 = (cfg_channel_l2 + 2'd2) * cfg_channel_com;
                mux_load_s0 = 9'b001000000;
                mux_load_s1 = 9'b010000000;
                mux_load_s2 = 9'b100000000;
                we_w0p      = mux_load[6] && valid_in;
                we_w1p      = mux_load[7] && valid_in;
                we_w2p      = mux_load[8] && valid_in;
                addr_w0p    = (mux_load[6]) ? addr_cnt : 0;
                addr_w1p    = (mux_load[7]) ? addr_cnt : 0;
                addr_w2p    = (mux_load[8]) ? addr_cnt : 0;
                din_w0p     = (mux_load[6]) ? data_in : 0;
                din_w1p     = (mux_load[7]) ? data_in : 0;
                din_w2p     = (mux_load[8]) ? data_in : 0;

                // CONV 0
                slot_out_x0 = 0;
                addrb_x0    = cv_ifm_addr_0;

                addr_w0     = cv_weight_addr_0;

                cv_ifm_0           = doutb_x0;
                cv_weight_0        = dout_w0;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_com;
                cv_start_0         = 1;

                we_t0             = cv_we_0;
                slot_t0            = 0;
                addr_t0           = cv_ofm_addr_0;
                din_t0            = cv_ofm_0;

                // CONV 1
                slot_out_x1 = 0;
                addrb_x1    = cv_ifm_addr_1;

                addr_w1     = cv_weight_addr_1;

                cv_ifm_1           = doutb_x1;
                cv_weight_1        = dout_w1;
                cv_mode_1          = 0;
                cv_stride_2_en_1   = 0;
                cv_upscaled_mode_1 = 1;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l1;
                cv_size_out_1      = cfg_size_l1;
                cv_channel_out_1   = cfg_channel_com;
                cv_start_1         = 1;

                we_t1             = cv_we_1;
                slot_t1            = 0;
                addr_t1           = cv_ofm_addr_1;
                din_t1            = cv_ofm_1;

                // CONV 2
                slot_out_x2 = 0;
                addrb_x2    = cv_ifm_addr_2;

                addr_w2     = cv_weight_addr_2;

                cv_ifm_2           = doutb_x2;
                cv_weight_2        = dout_w2;
                cv_mode_2          = 0;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 2;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_l2;
                cv_size_out_2      = cfg_size_l2;
                cv_channel_out_2   = cfg_channel_com;
                cv_start_2         = 1;

                we_t2             = cv_we_2;
                slot_t2         = 0;
                addr_t2           = cv_ofm_addr_2;
                din_t2            = cv_ofm_2;
            end

            S_5: begin
                // LOAD WPING
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_l0 + 2'd2) * cfg_channel_com;
                max_addr_s1 = (cfg_channel_l1 + 2'd2) * cfg_channel_com;
                max_addr_s2 = (cfg_channel_l2 + 2'd2) * cfg_channel_com;
                mux_load_s0 = 9'b000001000;
                mux_load_s1 = 9'b000010000;
                mux_load_s2 = 9'b000100000;
                we_w0       = mux_load[3] && valid_in;
                we_w1       = mux_load[4] && valid_in;
                we_w2       = mux_load[5] && valid_in;
                addr_w0     = (mux_load[3]) ? addr_cnt : 0;
                addr_w1     = (mux_load[4]) ? addr_cnt : 0;
                addr_w2     = (mux_load[5]) ? addr_cnt : 0;
                din_w0      = (mux_load[3]) ? data_in : 0;
                din_w1      = (mux_load[4]) ? data_in : 0;
                din_w2      = (mux_load[5]) ? data_in : 0;

                // CONV 0
                slot_out_x0 = 1;
                addrb_x0    = cv_ifm_addr_0;

                addr_w0p     = cv_weight_addr_0;

                cv_ifm_0           = doutb_x0;
                cv_weight_0        = dout_w0p;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_com;
                cv_start_0         = 1;

                we_t0             = cv_we_0;
                slot_t0            = 1;
                addr_t0           = cv_ofm_addr_0;
                din_t0            = cv_ofm_0;

                // CONV 1
                slot_out_x1 = 1;
                addrb_x1    = cv_ifm_addr_1;

                addr_w1p     = cv_weight_addr_1;

                cv_ifm_1           = doutb_x1;
                cv_weight_1        = dout_w1p;
                cv_mode_1          = 0;
                cv_stride_2_en_1   = 0;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l1;
                cv_size_out_1      = cfg_size_l1;
                cv_channel_out_1   = cfg_channel_com;
                cv_start_1         = 1;

                we_t1             = cv_we_1;
                slot_t1            = 1;
                addr_t1           = cv_ofm_addr_1;
                din_t1            = cv_ofm_1;

                // CONV 2
                slot_out_x2 = 1;
                addrb_x2    = cv_ifm_addr_2;

                addr_w2p     = cv_weight_addr_2;

                cv_ifm_2           = doutb_x2;
                cv_weight_2        = dout_w2p;
                cv_mode_2          = 0;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 1;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_l2;
                cv_size_out_2      = cfg_size_l2;
                cv_channel_out_2   = cfg_channel_com;
                cv_start_2         = 1;

                we_t2             = cv_we_2;
                slot_t2         = 1;
                addr_t2           = cv_ofm_addr_2;
                din_t2            = cv_ofm_2;
            end
            
            S_6: begin
                // LOAD WPONG
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_com*3) << 2;
                max_addr_s1 = (cfg_channel_com*3) << 2;
                max_addr_s2 = (cfg_channel_com*3) << 2;
                mux_load_s0 = 9'b001000000;
                mux_load_s1 = 9'b010000000;
                mux_load_s2 = 9'b100000000;
                we_w0p      = mux_load[6] && valid_in;
                we_w1p      = mux_load[7] && valid_in;
                we_w2p      = mux_load[8] && valid_in;
                addr_w0p    = (mux_load[6]) ? addr_cnt : 0;
                addr_w1p    = (mux_load[7]) ? addr_cnt : 0;
                addr_w2p    = (mux_load[8]) ? addr_cnt : 0;
                din_w0p     = (mux_load[6]) ? data_in : 0;
                din_w1p     = (mux_load[7]) ? data_in : 0;
                din_w2p     = (mux_load[8]) ? data_in : 0;

                // CONV 0
                slot_out_x0 = 2;
                addrb_x0    = cv_ifm_addr_0;

                addr_w0     = cv_weight_addr_0;

                cv_ifm_0           = doutb_x0;
                cv_weight_0        = dout_w0;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_com;
                cv_start_0         = 1;

                we_t0             = cv_we_0;
                slot_t0            = 2;
                addr_t0           = cv_ofm_addr_0;
                din_t0            = cv_ofm_0;

                // CONV 1
                slot_out_x1 = 2;
                addrb_x1    = cv_ifm_addr_1;

                addr_w1     = cv_weight_addr_1;

                cv_ifm_1           = doutb_x1;
                cv_weight_1        = dout_w1;
                cv_mode_1          = 0;
                cv_stride_2_en_1   = 0;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l1;
                cv_size_out_1      = cfg_size_l1;
                cv_channel_out_1   = cfg_channel_com;
                cv_start_1         = 1;

                we_t1             = cv_we_1;
                slot_t1            = 2;
                addr_t1           = cv_ofm_addr_1;
                din_t1            = cv_ofm_1;

                // CONV 2
                slot_out_x2 = 2;
                addrb_x2    = cv_ifm_addr_2;

                addr_w2     = cv_weight_addr_2;

                cv_ifm_2           = doutb_x2;
                cv_weight_2        = dout_w2;
                cv_mode_2          = 0;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 0;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_l2;
                cv_size_out_2      = cfg_size_l2;
                cv_channel_out_2   = cfg_channel_com;
                cv_start_2         = 1;

                we_t2             = cv_we_2;
                slot_t2         = 2;
                addr_t2           = cv_ofm_addr_2;
                din_t2            = cv_ofm_2;
            end

            S_7: begin
                // LOAD WPING
                start_load  = 1;
                en_cnt      = valid_in;
                max_addr    = l_max_addr;
                max_addr_s0 = (cfg_channel_k_l0 + 2'd2) * (cfg_channel_l0 << 1);
                max_addr_s1 = (cfg_channel_k_l1 + 2'd2) * (cfg_channel_l1 << 1);
                max_addr_s2 = (cfg_channel_k_l2 + 2'd2) * (cfg_channel_l2 << 1);
                mux_load_s0 = 9'b000001000;
                mux_load_s1 = 9'b000010000;
                mux_load_s2 = 9'b000100000;
                we_w0       = mux_load[3] && valid_in;
                we_w1       = mux_load[4] && valid_in;
                we_w2       = mux_load[5] && valid_in;
                addr_w0     = (mux_load[3]) ? addr_cnt : 0;
                addr_w1     = (mux_load[4]) ? addr_cnt : 0;
                addr_w2     = (mux_load[5]) ? addr_cnt : 0;
                din_w0      = (mux_load[3]) ? data_in : 0;
                din_w1      = (mux_load[4]) ? data_in : 0;
                din_w2      = (mux_load[5]) ? data_in : 0;

                // CONV 0
                slot_t0    = 0;
                addr_t0    = cv_ifm_addr_0;

                addr_w0p     = cv_weight_addr_0;

                cv_ifm_0           = dout_t0;
                cv_weight_0        = dout_w0p;
                cv_mode_0          = 0;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 0;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_com*3;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = 4;
                cv_start_0         = 1;

                wea_siw0           = cv_we_0;
                addra_siw0         = cv_ofm_addr_0;
                dina_siw0          = cv_ofm_0;

                // CONV 1
                slot_t1     = 0;
                addr_t1    = cv_ifm_addr_1;

                addr_w1p     = cv_weight_addr_1;

                cv_ifm_1           = dout_t1;
                cv_weight_1        = dout_w1p;
                cv_mode_1          = 0;
                cv_stride_2_en_1   = 0;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 0;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_com*3;
                cv_size_out_1      = cfg_size_l1;
                cv_channel_out_1   = 4;
                cv_start_1         = 1;

                wea_siw1           = cv_we_1;
                addra_siw1         = cv_ofm_addr_1;
                dina_siw1          = cv_ofm_1;

                // CONV 2
                slot_t2     = 0;
                addr_t2    = cv_ifm_addr_2;

                addr_w2p     = cv_weight_addr_2;

                cv_ifm_2           = dout_t2;
                cv_weight_2        = dout_w2p;
                cv_mode_2          = 0;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 0;
                cv_norm_en_2       = 0;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_com*3;
                cv_size_out_2      = cfg_size_l2;
                cv_channel_out_2   = 4;
                cv_start_2         = 1;

                wea_siw2           = cv_we_2;
                addra_siw2         = cv_ofm_addr_2;
                dina_siw2          = cv_ofm_2;
            end

            S_8: begin
                ifm_sm0   = doutb_siw0;
                size_sm0  = cfg_size_l0;
                start_sm0 = 1;

                wea_siw0   = we_sm0;
                addra_siw0 = siw_addr_sm0;
                dina_siw0  = data_sm0;
                addrb_siw0 = ifm_addr_sm0;

                ifm_sm1   = doutb_siw1;
                size_sm1  = cfg_size_l1;
                start_sm1 = 1;

                wea_siw1   = we_sm1;
                addra_siw1 = siw_addr_sm1;
                dina_siw1  = data_sm1;
                addrb_siw1 = ifm_addr_sm1;

                ifm_sm2   = doutb_siw2;
                size_sm2  = cfg_size_l2;
                start_sm2 = 1;

                wea_siw2   = we_sm2;
                addra_siw2 = siw_addr_sm2;
                dina_siw2  = data_sm2;
                addrb_siw2 = ifm_addr_sm2;
            end

            S_9: begin
                slot_out_x0 = slot_ew0;
                addrb_x0    = ifm_addr_ew0;

                addrb_siw0  = siw_addr_ew0;

                ifm_ew0     = doutb_x0;
                siw_ew0     = doutb_siw0;
                size_ew0    = cfg_size_l0;
                channel_ew0 = cfg_channel_l0;
                start_ew0   = 1;

                slot_t0     = 0;
                we_t0      = we_ew0;
                addr_t0    = ofm_addr_ew0;
                din_t0     = data_ew0;

                //
                slot_out_x1 = slot_ew1;
                addrb_x1    = ifm_addr_ew1;

                addrb_siw1  = siw_addr_ew1;

                ifm_ew1     = doutb_x1;
                siw_ew1     = doutb_siw1;
                size_ew1    = cfg_size_l1;
                channel_ew1 = cfg_channel_l1;
                start_ew1   = 1;

                slot_t1     = 0;
                we_t1      = we_ew1;
                addr_t1    = ofm_addr_ew1;
                din_t1     = data_ew1;

                //
                slot_out_x2 = slot_ew2;
                addrb_x2    = ifm_addr_ew2;

                addrb_siw2  = siw_addr_ew2;

                ifm_ew2     = doutb_x2;
                siw_ew2     = doutb_siw2;
                size_ew2    = cfg_size_l2;
                channel_ew2 = cfg_channel_l2;
                start_ew2   = 1;

                slot_t2     = 0;
                we_t2      = we_ew2;
                addr_t2    = ofm_addr_ew2;
                din_t2     = data_ew2;
            end

            S_10: begin
                // CONV 0
                slot_t0     = 0;
                addr_t0    = cv_ifm_addr_0;

                addr_w0     = cv_weight_addr_0;

                cv_ifm_0           = dout_t0;
                cv_weight_0        = dout_w0;
                cv_mode_0          = 1;
                cv_stride_2_en_0   = 0;
                cv_upscaled_mode_0 = 0;
                cv_norm_en_0       = 1;
                cv_size_in_0       = cfg_size_l0;
                cv_channel_in_0    = cfg_channel_l0;
                cv_size_out_0      = cfg_size_l0;
                cv_channel_out_0   = cfg_channel_l0*2;
                cv_start_0         = 1;

                wea_x0           = cv_we_0;
                addra_x0         = cv_ofm_addr_0;
                dina_x0          = cv_ofm_0;
                slot_in_x0       = 2;

                // CONV 1
                slot_t1     = 0;
                addr_t1    = cv_ifm_addr_1;

                addr_w1     = cv_weight_addr_1;

                cv_ifm_1           = dout_t1;
                cv_weight_1        = dout_w1;
                cv_mode_1          = 1;
                cv_stride_2_en_1   = 0;
                cv_upscaled_mode_1 = 0;
                cv_norm_en_1       = 1;
                cv_size_in_1       = cfg_size_l1;
                cv_channel_in_1    = cfg_channel_l1;
                cv_size_out_1      = cfg_size_l1;
                cv_channel_out_1   = cfg_channel_l1*2;
                cv_start_1         = 1;

                wea_x1           = cv_we_1;
                addra_x1         = cv_ofm_addr_1;
                dina_x1          = cv_ofm_1;
                slot_in_x1      = 2;
                

                // CONV 2
                slot_t2     = 0;
                addr_t2    = cv_ifm_addr_2;

                addr_w2     = cv_weight_addr_2;

                cv_ifm_2           = dout_t2;
                cv_weight_2        = dout_w2;
                cv_mode_2          = 1;
                cv_stride_2_en_2   = 0;
                cv_upscaled_mode_2 = 0;
                cv_norm_en_2       = 1;
                cv_size_in_2       = cfg_size_l2;
                cv_channel_in_2    = cfg_channel_l2;
                cv_size_out_2      = cfg_size_l2;
                cv_channel_out_2   = cfg_channel_l2*2;
                cv_start_2         = 1;

                wea_x2           = cv_we_2;
                addra_x2         = cv_ofm_addr_2;
                dina_x2          = cv_ofm_2;
                slot_in_x2       = 2;

                start_store = 1;
                en_cnt      = valid_out && m_axis_ready_i;
                max_addr    = s_max_addr;
                max_addr_s0 = (cfg_area_l0 * cfg_channel_l0) << 1;
                max_addr_s1 = (cfg_area_l1 * cfg_channel_l1) << 1;
                max_addr_s2 = (cfg_area_l2 * cfg_channel_l2) << 1;
                slot_out_x0      = 2;
                slot_out_x1      = 2;
                slot_out_x2      = 2;
                addrb_x0         = saddrb_x0;
                addrb_x1         = saddrb_x1;
                addrb_x2         = saddrb_x2;
            end

            DONE: begin
                done_o = 1;
            end

            default: ;
        endcase
    end


    wire start_d;

    register #(
        .DATA_WIDTH(1)
    ) reg_st (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(start_load),
        .q(start_d)
    );


    //==============================
    // LOAD FSM
    //==============================

    reg s_axis_ready;

    typedef enum reg [2:0] { 
        LIDLE,
        LS_0,
        LS_1,
        LS_2,
        LDONE
    } lstate_t;

    lstate_t lstate;
    lstate_t next_lstate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lstate <= LIDLE;
        else
            lstate <= next_lstate;
    end

    always @(*) begin
        next_lstate = lstate;
        s_axis_ready_o = s_axis_ready;

        case (lstate)
            LIDLE: if (start_load) next_lstate = LS_0;
            LS_0: if (cnt_max) next_lstate = LS_1;
            LS_1: if (cnt_max) next_lstate = LS_2;
            LS_2: if (cnt_max) begin
                s_axis_ready_o = (cnt_max) ? 0 : s_axis_ready;
                next_lstate = LDONE;
            end
            
            LDONE: if (l_ack) next_lstate = LIDLE;
            default: next_lstate = lstate;
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        l_max_addr     <= 0;
        mux_load       <= 0;
        ldone          <= 0;
        s_axis_ready <= 0;
    end else begin
        
        ldone          <= 0;
        s_axis_ready <= 0;

        case (next_lstate) 
            LS_0: begin 
                l_max_addr     <= max_addr_s0;
                mux_load       <= mux_load_s0;
                s_axis_ready <= 1;
            end
            LS_1: begin 
                l_max_addr     <= max_addr_s1;
                mux_load       <= mux_load_s1;
                s_axis_ready <= 1;
            end
            LS_2: begin 
                l_max_addr     <= max_addr_s2;
                mux_load       <= mux_load_s2;
                s_axis_ready <= 1;
            end
            LDONE: begin
                ldone          <= 1'b1;
            end
            default: begin
                l_max_addr     <= 0;
                mux_load       <= 0;
            end
        endcase
    end
end
    wire cnt_max_d;

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_cnt_max (
        .clk(clk),
        .rst_n(rst_n),
        .din(cnt_max),
        .dout(cnt_max_d)
    );

    //==============================
    // STORE FSM
    //==============================

    typedef enum reg [3:0] { 
        SIDLE,
        SCHECK_0,
        SS_0,
        SCHECK_1,
        SS_1,
        SCHECK_2,
        SS_2,
        SWAIT,
        SDONE
    } sstate_t;

    sstate_t sstate;
    sstate_t next_sstate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sstate <= SIDLE;
        else
            sstate <= next_sstate;
    end

    always @(*) begin
        next_sstate = sstate;

        case (sstate)
            SIDLE: if (start_store) next_sstate = SCHECK_0;
            SCHECK_0: if(cv_done_2) next_sstate = SS_0;
            SS_0: if (cnt_max) next_sstate = SCHECK_1;
            SCHECK_1: if(cv_done_1 && fifo_empty) next_sstate = SS_1;
            SS_1: if (cnt_max) next_sstate = SCHECK_2;
            SCHECK_2: if(cv_done_0 && fifo_empty) next_sstate = SS_2;
            SS_2: if (cnt_max) next_sstate = SWAIT;
            SWAIT: if (fifo_empty) next_sstate = SDONE;
            SDONE: if (start_store == 0) next_sstate = SIDLE;
            default: next_sstate = SIDLE;
        endcase
    end

    always @(*) begin
        fifo_din       = 0;
        saddrb_x0       = 0;
        saddrb_x1       = 0;
        saddrb_x2       = 0;

        case (sstate)
            SS_0: begin 
                fifo_din       = doutb_x2;
                saddrb_x2       = addr_cnt;
            end
            SCHECK_1: fifo_din       = doutb_x2;
            SS_1: begin 
                fifo_din       = doutb_x1;
                saddrb_x1       = addr_cnt;
            end
            SCHECK_2: fifo_din       = doutb_x1;
            SS_2: begin 
                fifo_din       = doutb_x0;
                saddrb_x0       = addr_cnt;
            end
            SWAIT: fifo_din       = doutb_x0;
            default: ;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_max_addr <= 0;
            sdone      <= 0;
            valid_out  <= 0;
        end 
        else begin
            s_max_addr <= 0;
            sdone      <= 0;
            valid_out  <= 0;

            case (next_sstate)
                SS_0: begin 
                    s_max_addr <= max_addr_s2;
                    valid_out  <= 1'b1;
                end
                SS_1: begin 
                    s_max_addr <= max_addr_s1;
                    valid_out  <= 1'b1;
                end
                SS_2: begin 
                    s_max_addr <= max_addr_s0;
                    valid_out  <= 1'b1;
                end
                SDONE: begin
                    sdone      <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    wire valid_br_out;

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_valid_ram_out (
        .clk(clk),
        .rst_n(rst_n),
        .din(valid_out && !fifo_full),
        .dout(valid_br_out)
    );

    assign fifo_wr_en = valid_br_out;
    assign fifo_rd_en =  m_axis_ready_i;
    assign m_axis_data_o = fifo_dout;
    assign m_axis_valid_o = !fifo_empty;

endmodule

