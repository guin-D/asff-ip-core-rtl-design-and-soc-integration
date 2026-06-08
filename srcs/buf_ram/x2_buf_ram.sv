import definition::*;

module x_buf_ram #(
    parameter MAX_SIZE    = MAX_SIZE,
    parameter MAX_CHANNEL = MAX_CHANNEL,
    parameter BUF_LEVEL   = 0
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire [$clog2(MAX_SIZE+1)-1:0]      cfg_size_i,
    input  wire [$clog2(MAX_CHANNEL+1)-1:0]   cfg_channel_i,
    input  wire                               wea,
    input  wire [1:0]                         slot_in,
    input  wire [1:0]                         slot_out,
    input  wire [DATA_ADDR_WIDTH-1:0]         addra,
    input  wire [BUS_WIDTH-1:0]               dina,
    input  wire [DATA_ADDR_WIDTH-1:0]         addrb,
    output wire [BUS_WIDTH-1:0]               doutb
);

    wire                       wea_reg;
    wire [1:0]                 slot_in_reg;
    wire [1:0]                 slot_out_reg;
    wire [DATA_ADDR_WIDTH-1:0] addra_reg;
    wire [DATA_ADDR_WIDTH-1:0] addrb_reg;
    wire [BUS_WIDTH-1:0]       dina_reg;

    register #(
        .DATA_WIDTH(1)
    ) reg_wea (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(wea),
        .q(wea_reg)
    );

    register #(
        .DATA_WIDTH(2)
    ) reg_slot_in (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(slot_in),
        .q(slot_in_reg)
    );

    register #(
        .DATA_WIDTH(2)
    ) reg_slot_out (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(slot_out),
        .q(slot_out_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_addra (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(addra),
        .q(addra_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_addrb (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(addrb),
        .q(addrb_reg)
    );

    register #(
        .DATA_WIDTH(BUS_WIDTH)
    ) reg_dina (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(dina),
        .q(dina_reg)
    );

    wire [DATA_ADDR_WIDTH-1:0] base_addr_in;
    wire [DATA_ADDR_WIDTH-1:0] base_addr_out;
    wire [DATA_ADDR_WIDTH-1:0] addra_t;
    wire [DATA_ADDR_WIDTH-1:0] addrb_t;

    wire [DATA_ADDR_WIDTH-1:0] base_e;
    wire [DATA_ADDR_WIDTH-1:0] base_1;
    wire [DATA_ADDR_WIDTH-1:0] base_0;

    assign base_e = cfg_size_i * cfg_size_i * (cfg_channel_i >> 1);

    generate
        if (BUF_LEVEL == 2) begin : BASE_LEVEL2
            assign base_1 = base_e;
            assign base_0 = base_e + (base_e >> 2);

            
        end else begin : BASE
            assign base_1 = base_e;
            assign base_0 = base_e << 1;
            
        end
    endgenerate

    assign base_addr_in = (slot_in_reg == 2'b10) ? {DATA_ADDR_WIDTH{1'b0}}:
                            (slot_in_reg == 2'b01) ? base_1:
                            base_0;  
    assign base_addr_out = (slot_out_reg == 2'b10) ? {DATA_ADDR_WIDTH{1'b0}}:
                            (slot_out_reg == 2'b01) ? base_1:
                            base_0;  

    assign addra_t = base_addr_in + addra_reg;

    assign addrb_t = base_addr_out + addrb_reg;

    generate
        if (BUF_LEVEL == 2) begin : GEN_X_BUF_LEVEL2
            X2_BUF_RAM x2_buf_ram_inst (
                .clka(clk),
                .clkb(clk),
                .wea(wea_reg),
                .addra(addra_t),
                .dina(dina_reg),
                .addrb(addrb_t),   
                .doutb(doutb)       
            );      
        end else if (BUF_LEVEL == 1) begin : GEN_X_BUF_LEVEL1
            X1_BUF_RAM x1_buf_ram_inst (
                .clka(clk),
                .clkb(clk),
                .wea(wea_reg),
                .addra(addra_t),
                .dina(dina_reg),
                .addrb(addrb_t),   
                .doutb(doutb)       
            );
        end else begin : GEN_X_BUF_LEVEL0
            X0_BUF_RAM x0_buf_ram_inst (
                .clka(clk),
                .clkb(clk),
                .wea(wea_reg),
                .addra(addra_t),
                .dina(dina_reg),
                .addrb(addrb_t),   
                .doutb(doutb)       
            );
        end
    endgenerate

    

endmodule