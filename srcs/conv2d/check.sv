`timescale 1ns / 1ps

module window_mul #(
    parameter DATA_WIDTH = 16
)(
    input  wire clk,
    input  wire rst_n,
    
    // Tín hiệu điều khiển tĩnh (Static Control)
    input  wire mode,          // 0: Conv 1x1, 1: Conv 3x3
    
    // Tín hiệu đồng bộ luồng dữ liệu
    input  wire valid_in,      // Dữ liệu ngõ vào hợp lệ (từ Line Buffer / Window)
    input  wire addr_en,       // Tín hiệu lọc stride (1: Cập nhật, 0: Data Hold)
    
    // Dữ liệu đầu vào (Cửa sổ 3x3 = 9 phần tử)
    // Lưu ý: Cú pháp mảng 1 chiều giúp code cực kỳ gọn và dễ scale
    input  wire signed [DATA_WIDTH-1:0] window_data [0:8],
    input  wire signed [DATA_WIDTH-1:0] weight_data [0:8],

    // Dữ liệu đầu ra
    output reg  signed [2*DATA_WIDTH-1:0] final_mac_out,
    output wire                           out_valid
);

    // =================================================================
    // 1. CONTROL PATH: PIPELINE ĐIỀU KHIỂN (FIXED LATENCY = 4)
    // =================================================================
    
    // Tín hiệu Enable gốc (Cho Stage 1)
    wire en_0;       // Luôn chạy cho pixel trung tâm (Conv 1x1 & 3x3)
    wire en_1_to_8;  // Chỉ chạy cho 8 pixel xung quanh khi mode = 1

    assign en_0      = valid_in & addr_en;
    assign en_1_to_8 = valid_in & addr_en & (mode == 1'b1);

    // Thanh ghi dịch (Shift Registers) để đồng bộ tín hiệu Enable/Valid qua 4 Stages
    reg en_d1_0, en_d1_1_to_8; // Enable cho Stage 2 (DSP P_reg)
    reg valid_d2;              // Enable cho Stage 3 (Adder Tree L1)
    reg valid_d3;              // Enable cho Stage 4 (Adder Tree L2)
    reg valid_d4;              // Tín hiệu out_valid cuối cùng

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_d1_0      <= 1'b0;
            en_d1_1_to_8 <= 1'b0;
            valid_d2     <= 1'b0;
            valid_d3     <= 1'b0;
            valid_d4     <= 1'b0;
        end else begin
            en_d1_0      <= en_0;
            en_d1_1_to_8 <= en_1_to_8;
            valid_d2     <= en_d1_0;  // Lấy nhánh chính (pixel 0) làm chuẩn valid
            valid_d3     <= valid_d2;
            valid_d4     <= valid_d3;
        end
    end

    // Xuất tín hiệu Valid ra ngoài (Trễ đúng 4 nhịp clock)
    assign out_valid = valid_d4;


    // =================================================================
    // 2. DATAPATH STAGE 1 & 2: KHỐI DSP MUL (Sử dụng internal registers)
    // =================================================================
    
    // Khai báo các thanh ghi sẽ được Vivado nhúng vào bên trong khối DSP48E1
    reg signed [DATA_WIDTH-1:0]   a_reg [0:8];
    reg signed [DATA_WIDTH-1:0]   b_reg [0:8];
    reg signed [2*DATA_WIDTH-1:0] p_reg [0:8];

    integer i, j;

    always @(posedge clk) begin
        // --- STAGE 1: Nạp toán hạng (A_reg, B_reg) ---
        if (en_0) begin
            a_reg[0] <= window_data[0];
            b_reg[0] <= weight_data[0];
        end
        if (en_1_to_8) begin
            for (i = 1; i < 9; i = i + 1) begin
                a_reg[i] <= window_data[i];
                b_reg[i] <= weight_data[i];
            end
        end

        // --- STAGE 2: Tính tích (P_reg) ---
        // Ghi chú: Sử dụng enable d1 để DSP nghỉ ngơi (Hold data) nếu nhịp trước đó bị ngắt
        if (en_d1_0) begin
            p_reg[0] <= a_reg[0] * b_reg[0];
        end
        if (en_d1_1_to_8) begin
            for (j = 1; j < 9; j = j + 1) begin
                p_reg[j] <= a_reg[j] * b_reg[j];
            end
        end
    end


    // =================================================================
    // 3. MASKING LOGIC (Bảo vệ Cây Cộng khi ở mode Conv 1x1)
    // =================================================================
    
    wire signed [2*DATA_WIDTH-1:0] p_eff [0:8];
    
    // Pixel số 0 (trung tâm) luôn đi qua
    assign p_eff[0] = p_reg[0];
    
    // Pixel 1-8: Nếu mode = 0 (Conv 1x1), ép toàn bộ ngõ ra của 8 DSP về 0.
    // Điều này chặn nhiễu Toggling đi vào Cây cộng, tiết kiệm công suất động.
    genvar g;
    generate
        for(g = 1; g < 9; g = g + 1) begin : mask_logic
            assign p_eff[g] = (mode == 1'b1) ? p_reg[g] : {(2*DATA_WIDTH){1'b0}};
        end
    endgenerate


    // =================================================================
    // 4. DATAPATH STAGE 3 & 4: CÂY CỘNG DỒN (ADDER TREE)
    // =================================================================
    
    reg signed [2*DATA_WIDTH-1:0] sum_stage1 [0:2];

    always @(posedge clk) begin
        // --- STAGE 3: Nhóm 3 nhánh (Gom 9 xuống còn 3) ---
        // Dùng valid_d2 làm Clock Enable cho thanh ghi Cây cộng
        if (valid_d2) begin
            sum_stage1[0] <= p_eff[0] + p_eff[1] + p_eff[2];
            sum_stage1[1] <= p_eff[3] + p_eff[4] + p_eff[5];
            sum_stage1[2] <= p_eff[6] + p_eff[7] + p_eff[8];
        end

        // --- STAGE 4: Tổng cuối cùng (Gom 3 xuống 1) ---
        if (valid_d3) begin
            final_mac_out <= sum_stage1[0] + sum_stage1[1] + sum_stage1[2];
        end
    end

endmodule