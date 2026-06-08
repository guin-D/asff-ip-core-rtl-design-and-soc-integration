import definition::*;

module softmax_dtp (
    input  wire                          clk,
    input  wire                          rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]          data_i,
    input  wire                          valid_i,
    
    // Control signals
    input  wire                          thread_cnt_i,

    // Output control signals
    output wire                          siw_addr_valid_o,

    // Output signals
    output wire [BUS_WIDTH-1:0]          data_o,
    output wire                          valid_o
);

    //========================
    // Stage 1.1: Compare
    //========================

    wire [DATA_WIDTH-1:0] x_0;
    wire [DATA_WIDTH-1:0] x_1;
    wire [DATA_WIDTH-1:0] x_2;
    wire [DATA_WIDTH-1:0] x_max;

    wire                  valid_s1;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i && (thread_cnt_i == 1'b0)),
        .d(data_i[DATA_WIDTH-1:0]),
        .q(x_0)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i && (thread_cnt_i == 1'b0)),
        .d(data_i[BUS_WIDTH-1:DATA_WIDTH]),
        .q(x_1)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i && (thread_cnt_i == 1'b1)),
        .d(data_i[DATA_WIDTH-1:0]),
        .q(x_2)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_i && (thread_cnt_i == 1'b1)),
        .q(valid_s1)
    );

    max_of_3 max_x (
        .data_in_0(x_0),
        .data_in_1(x_1),
        .data_in_2(x_2),
        .data_out(x_max)
    );

    //========================
    // Stage 1.2: Subtract
    //========================

    wire [DATA_WIDTH-1:0] x_0_reg;
    wire [DATA_WIDTH-1:0] x_1_reg;
    wire [DATA_WIDTH-1:0] x_2_reg;
    wire [DATA_WIDTH-1:0] x_max_reg;
    wire [DATA_WIDTH-1:0] z_0;
    wire [DATA_WIDTH-1:0] z_1;
    wire [DATA_WIDTH-1:0] z_2;

    wire                  valid_s1_d1;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_0_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1),
        .d(x_0),
        .q(x_0_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_1_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1),
        .d(x_1),
        .q(x_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_2_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1),
        .d(x_2),
        .q(x_2_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_x_max_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1),
        .d(x_max),
        .q(x_max_reg)
    );

    q_to_uq_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) z_0_sub (
        .a(x_max_reg),
        .b(x_0_reg),
        .diff(z_0)
    );

    q_to_uq_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) z_1_sub (
        .a(x_max_reg),
        .b(x_1_reg),
        .diff(z_1)
    );

    q_to_uq_subtractor #(
        .DATA_WIDTH(DATA_WIDTH)
    ) z_2_sub (
        .a(x_max_reg),
        .b(x_2_reg),
        .diff(z_2)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s1_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s1),
        .q(valid_s1_d1)
    );

    //========================
    // Stage 2.1: Exponential
    //========================

    wire [DATA_WIDTH-1:0] z_0_reg;
    wire [DATA_WIDTH-1:0] z_1_reg;
    wire [DATA_WIDTH-1:0] z_2_reg;
    wire [DATA_WIDTH-1:0] e_nz_0;
    wire [DATA_WIDTH-1:0] e_nz_1;
    wire [DATA_WIDTH-1:0] e_nz_2;

    wire                  valid_s2;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_0_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1_d1),
        .d(z_0),
        .q(z_0_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_1_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1_d1),
        .d(z_1),
        .q(z_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_2_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s1_d1),
        .d(z_2),
        .q(z_2_reg)
    );

    exponential_unit eu_0 (
        .data_i(z_0_reg),
        .data_o(e_nz_0)
    );

    exponential_unit eu_1 (
        .data_i(z_1_reg),
        .data_o(e_nz_1)
    );

    exponential_unit eu_2 (
        .data_i(z_2_reg),
        .data_o(e_nz_2)
    );
    
    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s1_d1),
        .q(valid_s2)
    );

    //========================
    // Stage 2.2: F Adder
    //========================

    wire [DATA_WIDTH-1:0] e_nz_0_reg;
    wire [DATA_WIDTH-1:0] e_nz_1_reg;
    wire [DATA_WIDTH-1:0] e_nz_2_reg;
    wire [DATA_WIDTH:0]   sum_01;
    wire [DATA_WIDTH:0]   F;

    wire                  valid_s2_d1;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_e_nz_0_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s2),
        .d(e_nz_0),
        .q(e_nz_0_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_e_nz_1_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s2),
        .d(e_nz_1),
        .q(e_nz_1_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_e_nz_2_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s2),
        .d(e_nz_2),
        .q(e_nz_2_reg)
    );

    assign sum_01 = {1'b0, e_nz_0_reg} + {1'b0, e_nz_1_reg};
    assign F = sum_01 + {1'b0, e_nz_2_reg};

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s2_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s2),
        .q(valid_s2_d1)
    );

    //============================
    // Stage 3: Natural Logarithm
    //============================

    wire [DATA_WIDTH:0]     F_reg;
    wire [DATA_WIDTH-1:0]   lnF;

    wire                    valid_s3;

    register #(
        .DATA_WIDTH(DATA_WIDTH+1)
    ) reg_F (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s2_d1),
        .d(F),
        .q(F_reg)
    );

    ln_unit ln_unit_F (
        .data_i(F_reg),
        .data_o(lnF)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s3 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s2_d1),
        .q(valid_s3)
    );

    //============================
    // Stage 4.1: z & lnF Adder
    //============================

    wire [DATA_WIDTH-1:0] lnF_reg;
    wire [DATA_WIDTH:0]   z_0_alnF;
    wire [DATA_WIDTH:0]   z_1_alnF;
    wire [DATA_WIDTH:0]   z_2_alnF;
    wire [DATA_WIDTH-1:0] z_0_alnF_norm;
    wire [DATA_WIDTH-1:0] z_1_alnF_norm;
    wire [DATA_WIDTH-1:0] z_2_alnF_norm;
    wire [DATA_WIDTH-1:0] z_0_d;
    wire [DATA_WIDTH-1:0] z_1_d;
    wire [DATA_WIDTH-1:0] z_2_d;

    wire                  valid_s4;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_lnF (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s3),
        .d(lnF),
        .q(lnF_reg)
    );

    // Delay S2.1, S2, S3
    delay_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .DELAY(3)
    ) delay_z_0 (
        .clk(clk),
        .rst_n(rst_n),
        .din(z_0),
        .dout(z_0_d)
    );

    delay_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .DELAY(3)
    ) delay_z_1 (
        .clk(clk),
        .rst_n(rst_n),
        .din(z_1),
        .dout(z_1_d)
    );

    delay_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .DELAY(3)
    ) delay_z_2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(z_2),
        .dout(z_2_d)
    );
    
    assign z_0_alnF = z_0_d + lnF_reg;
    assign z_1_alnF = z_1_d + lnF_reg;
    assign z_2_alnF = z_2_d + lnF_reg;

    // Saturation UQ9.8 -> UQ8.8
    assign z_0_alnF_norm = (z_0_alnF[DATA_WIDTH]) ? 16'hFFFF : z_0_alnF[DATA_WIDTH-1:0];
    assign z_1_alnF_norm = (z_1_alnF[DATA_WIDTH]) ? 16'hFFFF : z_1_alnF[DATA_WIDTH-1:0];
    assign z_2_alnF_norm = (z_2_alnF[DATA_WIDTH]) ? 16'hFFFF : z_2_alnF[DATA_WIDTH-1:0];

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s4 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s3),
        .q(valid_s4)
    );

    //============================
    // Stage 4.2: Exponential 
    //============================

    wire [DATA_WIDTH-1:0] z_0_alnF_norm_reg;
    wire [DATA_WIDTH-1:0] z_1_alnF_norm_reg;
    wire [DATA_WIDTH-1:0] z_2_alnF_norm_reg;
    wire [DATA_WIDTH-1:0] alpha;
    wire [DATA_WIDTH-1:0] beta;
    wire [DATA_WIDTH-1:0] gamma;

    wire                  valid_s4_d1;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_0_alnF_norm_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4),
        .d(z_0_alnF_norm),
        .q(z_0_alnF_norm_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_1_alnF_norm_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4),
        .d(z_1_alnF_norm),
        .q(z_1_alnF_norm_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_z_2_alnF_norm_reg (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4),
        .d(z_2_alnF_norm),
        .q(z_2_alnF_norm_reg)
    );

    exponential_unit alpha_cal (
        .data_i(z_0_alnF_norm_reg),
        .data_o(alpha)
    );

    exponential_unit beta_cal (
        .data_i(z_1_alnF_norm_reg),
        .data_o(beta)
    );

    exponential_unit gamma_cal (
        .data_i(z_2_alnF_norm_reg),
        .data_o(gamma)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s4_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s4),
        .q(valid_s4_d1)
    );

    //====================================
    // Stage 5: Mux Alpha, Beta & Gamma  
    //====================================

    wire [DATA_WIDTH-1:0] alpha_reg;
    wire [DATA_WIDTH-1:0] beta_reg;
    wire [DATA_WIDTH-1:0] gamma_reg;
    wire [DATA_WIDTH-1:0] gamma_d;
    wire [BUS_WIDTH-1:0]  mux_data;

    wire                  valid_s5;
    wire                  valid_s5_d1;
    wire                  mux_valid;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_alpha (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4_d1),
        .d(alpha),
        .q(alpha_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_beta (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4_d1),
        .d(beta),
        .q(beta_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_gamma (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s4_d1),
        .d(gamma),
        .q(gamma_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_gamma_d (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_s5),
        .d(gamma_reg),
        .q(gamma_d)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s5 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s4_d1),
        .q(valid_s5)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_s5_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(valid_s5),
        .q(valid_s5_d1)
    );

    assign mux_data = valid_s5 ? {beta_reg, alpha_reg} : {{DATA_WIDTH{1'b0}}, gamma_d};
    assign mux_valid = valid_s5 ? valid_s5 : valid_s5_d1;
    assign siw_addr_valid_o = mux_valid;

    //====================================
    // Data & Valid out  
    //====================================

    register #(
        .DATA_WIDTH(BUS_WIDTH)
    ) reg_data_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(mux_valid),
        .d(mux_data),
        .q(data_o)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(mux_valid),
        .q(valid_o)
    );

endmodule