import definition::*;

module maxpool2d_dtp #(
    parameter MAX_SIZE_OUT     = MAX_SIZE
)(
    input  wire                          clk,
    input  wire                          rst_n,

    // Data signals
    input  wire [DATA_WIDTH-1:0]         data_i,
    input  wire                          valid_i,

    // Config signals
    input  wire [$clog2(MAX_SIZE+1)-1:0] size_out_i,
    
    // Control signals
    input  wire                          c_en_i,
    input  wire                          mp_en_i,
    input  wire                          final_col_i,
    input  wire                          final_row_i,

    // Output signals
    output wire [DATA_WIDTH-1:0]         data_o,
    output wire                          valid_o
);

    //===============================
    // Delay control signals
    //===============================

    wire valid_d1, valid_d2;
    wire c_en_d1, c_en_d2;
    wire final_col_d1, final_col_d2;
    wire mp_en_d2, mp_en_d3;
    wire final_row_d;

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
    ) reg_c_en_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(c_en_i),
        .q(c_en_d1)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_c_en_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(c_en_d1),
        .q(c_en_d2)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_final_col_d1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(final_col_i),
        .q(final_col_d1)
    );

    register #(
        .DATA_WIDTH(1)
    ) reg_final_col_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(final_col_d1),
        .q(final_col_d2)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_mp_en_d2 (
        .clk(clk),
        .rst_n(rst_n),
        .din(mp_en_i),
        .dout(mp_en_d2)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(1)
    ) delay_mp_en_d3 (
        .clk(clk),
        .rst_n(rst_n),
        .din(mp_en_d2),
        .dout(mp_en_d3)
    );

    delay_buffer #(
        .DATA_WIDTH(1),
        .DELAY(2)
    ) delay_final_row (
        .clk(clk),
        .rst_n(rst_n),
        .din(final_row_i),
        .dout(final_row_d)
    );

    //===============================
    // Compare column
    //===============================

    wire [DATA_WIDTH-1:0] data_sp_sr_0;
    wire [DATA_WIDTH-1:0] data_sp_sr_1;
    wire [DATA_WIDTH-1:0] data_sp_sr_2;
    wire [DATA_WIDTH-1:0] data_ss_sr;
    wire [DATA_WIDTH-1:0] data_ss_sr_reg;


    sipo_shift_reg #(
        .DATA_WIDTH(DATA_WIDTH)
    ) sp_sr_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rst_local_n(~final_col_d1),
        .en(valid_i),
        .data_in(data_i),
        .data_out_0(data_sp_sr_0),
        .data_out_1(data_sp_sr_1),
        .data_out_2(data_sp_sr_2)
    );

    max_of_3 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) compare_col_inst (
        .data_in_0(data_sp_sr_0),
        .data_in_1(data_sp_sr_1),
        .data_in_2(data_sp_sr_2),
        .data_out(data_ss_sr)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_data_ss_sr (
        .clk(clk),
        .rst_n(rst_n),
        .en(c_en_d1),
        .d(data_ss_sr),
        .q(data_ss_sr_reg)
    );    

    //===============================
    // Compare row
    //===============================

    wire [DATA_WIDTH-1:0] sr_out_0;
    wire [DATA_WIDTH-1:0] sr_out_1;
    wire [DATA_WIDTH-1:0] sr_out_2;
    wire [DATA_WIDTH-1:0] sr_out_max;
    wire [DATA_WIDTH-1:0] r_out_0;
    wire [DATA_WIDTH-1:0] r_out_1;
    wire [DATA_WIDTH-1:0] r_out_2;
    wire [DATA_WIDTH-1:0] mux_out_0;
    wire [DATA_WIDTH-1:0] mux_out_1;
    wire [DATA_WIDTH-1:0] mux_out_2;

    reg  [1:0] phase;
    reg  [2:0] select_mux;
    wire [2:0] select_mux_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            phase <= 0;
        else if (final_col_d2) begin
            if (phase == 2)
                phase <= 0;
            else
                phase <= phase + 1;
        end
    end

    always @(*) begin
        case (phase)
            0: select_mux = 3'b010;
            1: select_mux = 3'b100;
            2: select_mux = 3'b001;
            default: select_mux = 3'b000;
        endcase
    end

    delay_buffer #(
        .DATA_WIDTH(3),
        .DELAY(1)
    ) delay_select_mux (
        .clk(clk),
        .rst_n(rst_n),
        .din(select_mux),
        .dout(select_mux_d1)
    );

    circular_rmw_buffer #(
        .N(MAX_SIZE_OUT),
        // .START_READ_PTR(1),
        .NEG_INF_INIT(1)
    ) ss_sr_0_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rst_local_n(~final_row_d),
        .wrap_limit(size_out_i),
        .w_en(c_en_d2 && select_mux[0]),
        .data_in(data_ss_sr_reg),
        .r_en(mp_en_d2 && !select_mux[0]),
        .data_out(sr_out_0)
    );

    circular_rmw_buffer #(
        .N(MAX_SIZE_OUT),
        // .START_READ_PTR(1),
        .NEG_INF_INIT(1)
    ) ss_sr_1_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rst_local_n(~final_row_d),
        .wrap_limit(size_out_i),
        .w_en(c_en_d2 && select_mux[1]),
        .data_in(data_ss_sr_reg),
        .r_en(mp_en_d2 && !select_mux[1]),
        .data_out(sr_out_1)
    );

    circular_rmw_buffer #(
        .N(MAX_SIZE_OUT),
        // .START_READ_PTR(1),
        .NEG_INF_INIT(1)
    ) ss_sr_2_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rst_local_n(~final_row_d),
        .wrap_limit(size_out_i),
        .w_en(c_en_d2 && select_mux[2]),
        .data_in(data_ss_sr_reg),
        .r_en(mp_en_d2 && !select_mux[2]),
        .data_out(sr_out_2)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_strait_0 (
        .clk(clk),
        .rst_n(rst_n),
        .en(mp_en_d2 && select_mux[0]),
        .d(data_ss_sr_reg),
        .q(r_out_0)
    ); 

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_strait_1 (
        .clk(clk),
        .rst_n(rst_n),
        .en(mp_en_d2 && select_mux[1]),
        .d(data_ss_sr_reg),
        .q(r_out_1)
    ); 

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_strait_2 (
        .clk(clk),
        .rst_n(rst_n),
        .en(mp_en_d2 && select_mux[2]),
        .d(data_ss_sr_reg),
        .q(r_out_2)
    );

    assign mux_out_0 = (select_mux_d1[0] == 1'b1) ? r_out_0 : sr_out_0;
    assign mux_out_1 = (select_mux_d1[1] == 1'b1) ? r_out_1 : sr_out_1;
    assign mux_out_2 = (select_mux_d1[2] == 1'b1) ? r_out_2 : sr_out_2;

    max_of_3 #(
        .DATA_WIDTH(DATA_WIDTH)
    ) compare_row_inst (
        .data_in_0(mux_out_0),
        .data_in_1(mux_out_1),
        .data_in_2(mux_out_2),
        .data_out(sr_out_max)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_data_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(mp_en_d3),
        .d(sr_out_max),
        .q(data_o)
    ); 

    register #(
        .DATA_WIDTH(1)
    ) reg_valid_o (
        .clk(clk),
        .rst_n(rst_n),
        .en(1'b1),
        .d(mp_en_d3),
        .q(valid_o)
    );

endmodule