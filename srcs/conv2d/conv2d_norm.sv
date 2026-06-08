import definition::*;

module conv2d_norm (
    input  wire                      clk,
    input  wire                      rst_n,

    // Data signals
    input  wire [DATA_WIDTH_BUF-1:0] data_i,
    input  wire                      valid_i,
    input  wire [DATA_WIDTH-1:0]     weight_i,
    input  wire                      nw_valid_i,
    input  wire                      bw_valid_i,

    // Config signals
    input  wire                      norm_en_i,

    // Control signals
    input  wire                      norm_ld_i,

    // Output signals
    output wire [DATA_WIDTH-1:0]     data_o,
    output reg                       valid_o
);

    localparam ADD_WIDTH = DATA_WIDTH_BUF + DATA_WIDTH - DATA_FRAC - WEIGHT_FRAC;

    localparam signed [DATA_WIDTH-1:0] RELU6_LIMIT = (6 << DATA_FRAC); 
    localparam signed [ADD_WIDTH-1:0] RELU6_LIMIT_EXT = (6 << DATA_FRAC); 
    localparam signed [DATA_WIDTH-1:0] ZERO_VAL    = 0;

    wire signed [DATA_WIDTH-1:0] norm_w_reg;
    wire signed [DATA_WIDTH-1:0] bias_w_reg;   
    wire signed [DATA_WIDTH-1:0] norm_w_cal;
    wire signed [DATA_WIDTH-1:0] bias_w_cal;   
    wire signed [DATA_WIDTH_BUF-1:0] data_i_reg; 
    
    wire signed [DATA_WIDTH_BUF+DATA_WIDTH-1:0] mul_val;   
    wire signed [DATA_WIDTH_BUF+DATA_WIDTH-1:0] mul_val_reg;        
    wire signed [ADD_WIDTH-1:0] mul_val_aligned;
    wire signed [ADD_WIDTH:0] add_val;
    wire signed [ADD_WIDTH:0] add_val_reg;
    wire [DATA_WIDTH-1:0] relu6_data;

    reg  valid_in_d1, valid_in_d2, valid_in_d3;
    wire mux_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_in_d1 <= 1'b0;
            valid_in_d2 <= 1'b0;
            valid_in_d3 <= 1'b0;
            valid_o     <= 1'b0;
        end else begin
            valid_in_d1 <= valid_i;      
            valid_in_d2 <= valid_in_d1;  
            valid_in_d3 <= valid_in_d2;  
            valid_o     <= mux_valid;  
        end
    end

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_norm_w (
        .clk(clk),
        .rst_n(rst_n),
        .en(nw_valid_i),
        .d(weight_i),
        .q(norm_w_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)             
    ) reg_bias_w (
        .clk(clk),
        .rst_n(rst_n),
        .en(bw_valid_i),
        .d(weight_i),
        .q(bias_w_reg)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_norm_w_cal (
        .clk(clk),
        .rst_n(rst_n),
        .en(norm_ld_i),
        .d(norm_w_reg),
        .q(norm_w_cal)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH)             
    ) reg_bias_w_cal (
        .clk(clk),
        .rst_n(rst_n),
        .en(norm_ld_i),
        .d(bias_w_reg),
        .q(bias_w_cal)
    );

    register #(
        .DATA_WIDTH(DATA_WIDTH_BUF)
    ) reg_data (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_i),
        .d(data_i),
        .q(data_i_reg)
    );

    assign mul_val = data_i_reg * norm_w_cal;

    register #(
        .DATA_WIDTH(DATA_WIDTH_BUF+DATA_WIDTH)
    ) reg_mul_val (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_in_d1),
        .d(mul_val),
        .q(mul_val_reg)
    );

    assign mul_val_aligned = mul_val_reg [DATA_WIDTH_BUF+DATA_WIDTH-1:DATA_FRAC+WEIGHT_FRAC];
    assign add_val = bias_w_cal + mul_val_aligned;

    register #(
        .DATA_WIDTH(ADD_WIDTH+1)
    ) reg_add_val (
        .clk(clk),
        .rst_n(rst_n),
        .en(valid_in_d2),
        .d(add_val),
        .q(add_val_reg)
    );

    assign relu6_data = (add_val_reg[ADD_WIDTH]) ? ZERO_VAL : 
                   (add_val_reg > RELU6_LIMIT_EXT) ? RELU6_LIMIT : 
                    add_val_reg[DATA_WIDTH-1:0];


    localparam INPUT_FRAC   = DATA_FRAC + WEIGHT_FRAC;  
    localparam SHIFT_AMOUNT = INPUT_FRAC - SIW_FRAC; 

    localparam CHECK_BIT_TOP = DATA_WIDTH_BUF - 1; 
    localparam CHECK_BIT_BOT = DATA_WIDTH + SHIFT_AMOUNT - 1; 

    localparam signed [DATA_WIDTH-1:0] MAX_SAT = {1'b0, {(DATA_WIDTH-1){1'b1}}}; 
    localparam signed [DATA_WIDTH-1:0] MIN_SAT = {1'b1, {(DATA_WIDTH-1){1'b0}}};

    wire                                 is_safe;
    wire [CHECK_BIT_TOP : CHECK_BIT_BOT] sign_bits;
    wire [DATA_WIDTH-1:0]                n_norm_data;
    wire [DATA_WIDTH-1:0]                mux_data;

    assign sign_bits = data_i_reg[CHECK_BIT_TOP : CHECK_BIT_BOT]; 
    assign is_safe = (sign_bits == '0) || (sign_bits == '1);

    assign n_norm_data = 
        is_safe                      ? data_i_reg[CHECK_BIT_BOT : SHIFT_AMOUNT] : 
        data_i_reg[DATA_WIDTH_BUF-1] ? MIN_SAT :                                  
                                       MAX_SAT;

    assign mux_data = (norm_en_i == 1'b1) ? relu6_data : n_norm_data;
    assign mux_valid = (norm_en_i == 1'b1) ? valid_in_d3 : valid_in_d1;

    register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) reg_out (
        .clk(clk),
        .rst_n(rst_n),
        .en(mux_valid),
        .d(mux_data),
        .q(data_o)
    );

endmodule

// import definition::*;

// module conv2d_norm (
//     input  wire                      clk,
//     input  wire                      rst_n,

//     // Data signals
//     input  wire [DATA_WIDTH_BUF-1:0] data_i,
//     input  wire                      valid_i,
//     input  wire [DATA_WIDTH-1:0]     weight_i,
//     input  wire                      nw_valid_i,
//     input  wire                      bw_valid_i,

//     // Config signals
//     input  wire                      norm_en_i,

//     // Control signals
//     input  wire                      norm_ld_i,

//     // Output signals
//     output wire [DATA_WIDTH-1:0]     data_o,
//     output reg                       valid_o
// );

//     localparam ADD_WIDTH = DATA_WIDTH_BUF + DATA_WIDTH - DATA_FRAC - WEIGHT_FRAC;

//     localparam signed [DATA_WIDTH-1:0] RELU6_LIMIT = (6 << DATA_FRAC); 
//     localparam signed [DATA_WIDTH_BUF+DATA_WIDTH+1-1:0] RELU6_LIMIT_EXT = (6 << (DATA_FRAC+DATA_FRAC+WEIGHT_FRAC)); 
//     localparam signed [DATA_WIDTH-1:0] ZERO_VAL    = 0;

//     wire signed [DATA_WIDTH-1:0] norm_w_reg;
//     wire signed [DATA_WIDTH-1:0] bias_w_reg;   
//     wire signed [DATA_WIDTH-1:0] norm_w_cal;
//     wire signed [DATA_WIDTH-1:0] bias_w_cal;   
//     wire signed [DATA_WIDTH+DATA_FRAC+WEIGHT_FRAC-1:0] bias_w_cal_aligned;
//     reg signed [DATA_WIDTH+DATA_FRAC+WEIGHT_FRAC-1:0] bias_w_cal_aligned_reg;
//     wire signed [DATA_WIDTH_BUF-1:0] data_i_reg; 
    
//     wire signed [DATA_WIDTH_BUF+DATA_WIDTH-1:0] mul_val;   
//     // reg  signed [DATA_WIDTH_BUF+DATA_WIDTH-1:0] mul_val_reg;        
//     wire signed [ADD_WIDTH-1:0] mul_val_aligned;
//     wire signed [DATA_WIDTH_BUF+DATA_WIDTH:0] add_val;
//     // reg  signed [DATA_WIDTH_BUF+DATA_WIDTH:0] add_val_reg;
//     wire        [DATA_WIDTH-1:0] relu6_data;

//     reg  valid_in_d1, valid_in_d2, valid_in_d3;
//     wire mux_valid;

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             valid_in_d1 <= 1'b0;
//             valid_in_d2 <= 1'b0;
//             valid_in_d3 <= 1'b0;
//             valid_o     <= 1'b0;
//         end else begin
//             valid_in_d1 <= valid_i;      
//             valid_in_d2 <= valid_in_d1;  
//             valid_in_d3 <= valid_in_d2;  
//             valid_o     <= mux_valid;  
//         end
//     end

//     register #(
//         .DATA_WIDTH(DATA_WIDTH)
//     ) reg_norm_w (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(nw_valid_i),
//         .d(weight_i),
//         .q(norm_w_reg)
//     );

//     register #(
//         .DATA_WIDTH(DATA_WIDTH)             
//     ) reg_bias_w (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(bw_valid_i),
//         .d(weight_i),
//         .q(bias_w_reg)
//     );

//     register #(
//         .DATA_WIDTH(DATA_WIDTH)
//     ) reg_norm_w_cal (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(norm_ld_i),
//         .d(norm_w_reg),
//         .q(norm_w_cal)
//     );

//     register #(
//         .DATA_WIDTH(DATA_WIDTH)             
//     ) reg_bias_w_cal (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(norm_ld_i),
//         .d(bias_w_reg),
//         .q(bias_w_cal)
//     );

//     register #(
//         .DATA_WIDTH(DATA_WIDTH_BUF)
//     ) reg_data (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(valid_i),
//         .d(data_i),
//         .q(data_i_reg)
//     );

//     // assign mul_val = data_i_reg * norm_w_cal;

//     // // register #(
//     // //     .DATA_WIDTH(DATA_WIDTH_BUF+DATA_WIDTH)
//     // // ) reg_mul_val (
//     // //     .clk(clk),
//     // //     .rst_n(rst_n),
//     // //     .en(valid_in_d1),
//     // //     .d(mul_val),
//     // //     .q(mul_val_reg)
//     // // );

//     // always @(posedge clk) begin
//     //     if(rst_n == 0) begin
//     //         mul_val_reg <= 0;
//     //     end
//     //     else if (valid_in_d1 == 1'b1) begin
//     //         mul_val_reg <=  mul_val;
//     //     end
//     // end

//     assign bias_w_cal_aligned = $signed(bias_w_cal) <<< (DATA_FRAC+WEIGHT_FRAC);
//     // assign add_val = bias_w_cal_aligned + mul_val_reg;

//     // register #(
//     //     .DATA_WIDTH(DATA_WIDTH_BUF+DATA_WIDTH+1)
//     // ) reg_add_val (
//     //     .clk(clk),
//     //     .rst_n(rst_n),
//     //     .en(valid_in_d2),
//     //     .d(add_val),
//     //     .q(add_val_reg)
//     // );

//     (* use_dsp = "yes" *) reg signed [DATA_WIDTH_BUF+DATA_WIDTH-1:0] mul_val_reg;        
//     (* use_dsp = "yes" *) reg signed [DATA_WIDTH_BUF+DATA_WIDTH:0]   add_val_reg;

//     always @(posedge clk) begin
//         // Tầng MREG (Thanh ghi sau bộ nhân)
//         // Không dùng Reset ở đây để đảm bảo Vivado map đúng vào MREG
//         if (valid_in_d1) begin
//             mul_val_reg <= data_i_reg * norm_w_cal; 
//             bias_w_cal_aligned_reg <= bias_w_cal_aligned;
//         end

//         // Tầng PREG (Thanh ghi sau bộ cộng)
//         if (valid_in_d2) begin
//             add_val_reg <= bias_w_cal_aligned_reg + mul_val_reg;
//         end
//     end

//     assign relu6_data = (add_val_reg[DATA_WIDTH_BUF+DATA_WIDTH]) ? ZERO_VAL : 
//                    (add_val_reg > RELU6_LIMIT_EXT) ? RELU6_LIMIT : 
//                     add_val_reg[DATA_WIDTH+WEIGHT_FRAC+DATA_FRAC-1:WEIGHT_FRAC+DATA_FRAC];


//     localparam INPUT_FRAC   = DATA_FRAC + WEIGHT_FRAC;  
//     localparam SHIFT_AMOUNT = INPUT_FRAC - SIW_FRAC; 

//     localparam CHECK_BIT_TOP = DATA_WIDTH_BUF - 1; 
//     localparam CHECK_BIT_BOT = DATA_WIDTH + SHIFT_AMOUNT - 1; 

//     localparam signed [DATA_WIDTH-1:0] MAX_SAT = {1'b0, {(DATA_WIDTH-1){1'b1}}}; 
//     localparam signed [DATA_WIDTH-1:0] MIN_SAT = {1'b1, {(DATA_WIDTH-1){1'b0}}};

//     wire                                 is_safe;
//     wire [CHECK_BIT_TOP : CHECK_BIT_BOT] sign_bits;
//     wire [DATA_WIDTH-1:0]                n_norm_data;
//     wire [DATA_WIDTH-1:0]                mux_data;

//     assign sign_bits = data_i_reg[CHECK_BIT_TOP : CHECK_BIT_BOT]; 
//     assign is_safe = (sign_bits == '0) || (sign_bits == '1);

//     assign n_norm_data = 
//         is_safe                      ? data_i_reg[CHECK_BIT_BOT : SHIFT_AMOUNT] : 
//         data_i_reg[DATA_WIDTH_BUF-1] ? MIN_SAT :                                  
//                                        MAX_SAT;

//     assign mux_data = (norm_en_i == 1'b1) ? relu6_data : n_norm_data;
//     assign mux_valid = (norm_en_i == 1'b1) ? valid_in_d3 : valid_in_d1;

//     register #(
//         .DATA_WIDTH(DATA_WIDTH)
//     ) reg_out (
//         .clk(clk),
//         .rst_n(rst_n),
//         .en(valid_in_d1),
//         .d(mux_data),
//         .q(data_o)
//     );

// endmodule