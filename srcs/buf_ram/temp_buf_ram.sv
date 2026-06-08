import definition::*;

module temp_buf_ram #(
    parameter MAX_SIZE    = MAX_SIZE,
    parameter BUF_LEVEL   = 0
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire [$clog2(MAX_SIZE+1)-1:0]      cfg_size_i,
    input  wire                               we,
    input  wire [1:0]                         slot,
    input  wire [DATA_ADDR_WIDTH-1:0]         addr,
    input  wire [BUS_WIDTH-1:0]               din,
    output wire [BUS_WIDTH-1:0]               dout
);

    wire                       we_reg;
    wire [1:0]                 slot_reg;
    wire [DATA_ADDR_WIDTH-1:0] addr_reg;
    wire [BUS_WIDTH-1:0]       din_reg;

    register #(
        .DATA_WIDTH(1)
    ) reg_we (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(we),
        .q(we_reg)
    );

    register #(
        .DATA_WIDTH(2)
    ) reg_slot (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(slot),
        .q(slot_reg)
    );

    register #(
        .DATA_WIDTH(DATA_ADDR_WIDTH)
    ) reg_addr (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(addr),
        .q(addr_reg)
    );

    register #(
        .DATA_WIDTH(BUS_WIDTH)
    ) reg_din (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(din),
        .q(din_reg)
    );

    wire [DATA_ADDR_WIDTH-1:0] base_addr;
    wire [DATA_ADDR_WIDTH-1:0] addr_t;

    wire [DATA_ADDR_WIDTH-1:0] base_e;

    assign base_e = cfg_size_i * cfg_size_i;

    assign base_addr = (slot_reg == 2'b00) ? {DATA_ADDR_WIDTH{1'b0}}:
                       (slot_reg == 2'b01) ? base_e:
                                base_e << 1;  

    assign addr_t = base_addr + addr_reg;

    generate
        if (BUF_LEVEL == 2) begin : GEN_T_BUF_LEVEL2
            T2_BUF_RAM t2_buf_ram_inst (
                .clka(clk),
                .wea(we_reg),
                .addra(addr_t),
                .dina(din_reg),
                .douta(dout)       
            );      
        end else if (BUF_LEVEL == 1) begin : GEN_T_BUF_LEVEL1
            T1_BUF_RAM t1_buf_ram_inst (
                .clka(clk),
                .wea(we_reg),
                .addra(addr_t),
                .dina(din_reg),
                .douta(dout)       
            );
        end else begin : GEN_T_BUF_LEVEL0
            T0_BUF_RAM t0_buf_ram_inst (
                .clka(clk),
                .wea(we_reg),
                .addra(addr_t),
                .dina(din_reg), 
                .douta(dout)       
            );
        end
    endgenerate

    

endmodule