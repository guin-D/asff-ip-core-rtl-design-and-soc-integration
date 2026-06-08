import definition::*;

module ew_mac_pe (
    input  wire                          clk,
    input  wire                          rst_n,

    // Data signals
    input  wire [DATA_WIDTH-1:0]         data_i,
    input  wire                          valid_i,
    input  wire [DATA_WIDTH-1:0]         siw_i,
    
    // Control signals
    input  wire                          final_siw_i,

    // Output control signals
    output wire                          ofm_addr_valid_o,

    // Output signals
    output [DATA_WIDTH-1:0]              data_o,
    output                               valid_o
);

    //===============================
    // Delay control signals
    //===============================

    wire valid_d1, valid_d2;
    wire final_siw_d1, final_siw_d2;
    
    register #(
        .DATA_WIDTH(1)
    ) reg_valid_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_i),
        .q(valid_d1)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_d1),
        .q(valid_d2)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_final_siw_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(final_siw_i),
        .q(final_siw_d1)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_final_siw_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(final_siw_d1),
        .q(final_siw_d2)
    ); 

    //===============================
    // Calculation
    //===============================

    wire [DATA_WIDTH-1:0] data_ifm_to_m;
    wire [DATA_WIDTH*2-1:0] data_m_to_a;
    wire [DATA_WIDTH*2-1:0] data_m_to_a_reg;
    wire [DATA_WIDTH*2:0] data_a_to;
    wire [DATA_WIDTH*2:0] data_reg_to_a;
    wire [DATA_WIDTH*2:0] data_m_to_a_norm;
    wire [DATA_WIDTH*2:0] mux_data_to_reg_acc;
    wire [DATA_WIDTH-1:0] data_a_to_norm;   

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_input (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(data_i),
        .q(data_ifm_to_m)
    );

    q_uq_multiplier mul_inst (
        .a_q(data_ifm_to_m),
        .b_uq(siw_i),
        .p_q(data_m_to_a)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH*2)
    ) reg_data_m_to_a (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_d1),
        .d(data_m_to_a),
        .q(data_m_to_a_reg)
    );

    assign data_m_to_a_norm = {1'b0, data_m_to_a_reg};

    signed_adder #(
        .DATA_WIDTH(DATA_WIDTH*2+1)
    ) adder_inst (
        .a(data_m_to_a_norm),
        .b(data_reg_to_a),
        .sum(data_a_to)
    );

    assign mux_data_to_reg_acc = (final_siw_d2 == 1'b1) ? {(DATA_WIDTH*2+1){1'b0}} : data_a_to;

    register #(
        .DATA_WIDTH(DATA_WIDTH*2+1)
    ) reg_acc (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_d2),
        .d(mux_data_to_reg_acc),
        .q(data_reg_to_a)
    );


    assign data_a_to_norm = (data_a_to[DATA_WIDTH*2] == 1'b0 && data_a_to[DATA_WIDTH*2 : DATA_WIDTH*2-2] != 3'b000) ?
                            {1'b0, {(DATA_WIDTH-1){1'b1}}} :    // MIN
                            (data_a_to[DATA_WIDTH*2] == 1'b1 && data_a_to[DATA_WIDTH*2 : DATA_WIDTH*2-2] != 3'b111) ?
                            {1'b1, {(DATA_WIDTH-1){1'b0}}} :    // MAX
                            data_a_to[DATA_WIDTH*2-2 -: DATA_WIDTH];
    
    //===============================
    // Data & Valid out
    //===============================

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_data_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(final_siw_d2),
        .d(data_a_to_norm),
        .q(data_o)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(1),
        .d(final_siw_d2),
        .q(valid_o)
    );

    assign ofm_addr_valid_o = final_siw_d1;
    
endmodule