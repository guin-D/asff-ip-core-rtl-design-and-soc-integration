// module circular_rmw_buffer #(
//     parameter DATA_WIDTH = 16,
//     parameter N          = 64,
//     parameter START_READ_PTR = 0,
//     parameter NEG_INF_INIT = 0
// )(
//     input  wire                  clk,
//     input  wire                  rst_n,
//     input  wire                  rst_local_n,
    
//     input  wire [$clog2(N+1)-1:0]  wrap_limit, 
    
//     input  wire                  w_en,
//     input  wire [DATA_WIDTH-1:0] data_in,
    
//     input  wire                  r_en,
//     output reg  [DATA_WIDTH-1:0] data_out
// );

//     localparam PTR_WIDTH = $clog2(N);

//     reg [DATA_WIDTH-1:0] mem [0:N-1];
    
//     reg [PTR_WIDTH-1:0]  w_ptr;
//     reg [PTR_WIDTH-1:0]  r_ptr;
    
//     integer i;

//     wire [DATA_WIDTH-1:0] NEG_INF;
//     assign NEG_INF = {1'b1, {(DATA_WIDTH-1){1'b0}}};

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             w_ptr <= 0;
//             for (i = 0; i < N; i = i + 1) begin
//                 mem[i] <= (NEG_INF_INIT == 0) ? {DATA_WIDTH{1'b0}} : NEG_INF;
//             end
//         end else if (!rst_local_n) begin
//             w_ptr <= 0;
//             for (i = 0; i < N; i = i + 1) begin
//                 mem[i] <= NEG_INF;
//             end
//         end else if (w_en) begin
//             mem[w_ptr] <= data_in;
//             if (w_ptr == wrap_limit - 1)
//                 w_ptr <= 0;
//             else
//                 w_ptr <= w_ptr + 1;
//         end
//     end

//     always @(posedge clk or negedge rst_n) begin
//         if (!rst_n) begin
//             r_ptr <= START_READ_PTR;
//             data_out <= {DATA_WIDTH{1'b0}};
//         end else if (r_en) begin
//             data_out <= mem[r_ptr];
//             if (r_ptr == wrap_limit - 1)
//                 r_ptr <= 0;
//             else
//                 r_ptr <= r_ptr + 1;
//         end
//     end

// endmodule


module circular_rmw_buffer #(
    parameter DATA_WIDTH = 16,
    parameter N          = 64,
    parameter START_READ_PTR = 0,
    parameter NEG_INF_INIT = 0,
    parameter USE_BRAM   = 0
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  rst_local_n,
    
    input  wire [$clog2(N+1)-1:0]  wrap_limit, 
    
    input  wire                  w_en,
    input  wire [DATA_WIDTH-1:0] data_in,
    
    input  wire                  r_en,
    output reg  [DATA_WIDTH-1:0] data_out
);

    localparam PTR_WIDTH = $clog2(N);

    
    
    reg [PTR_WIDTH-1:0]  w_ptr;
    reg [PTR_WIDTH-1:0]  r_ptr;
    
    integer i;

    wire [DATA_WIDTH-1:0] NEG_INF;
    assign NEG_INF = {1'b1, {(DATA_WIDTH-1){1'b0}}};

    // =========================================================================
    // SỬ DỤNG GENERATE �?Ể TẠO PHẦN CỨNG THEO PARAMETER
    // =========================================================================
    generate
        if (USE_BRAM == 0 && NEG_INF_INIT == 0) begin : gen_ff_logic
            // ----------------------------------------------------
            // LOGIC CŨ: SỬ DỤNG FLIP-FLOP (CÓ RESET TOÀN BỘ MẢNG)
            // ----------------------------------------------------

            reg [DATA_WIDTH-1:0] mem [0:N-1];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    w_ptr <= 0;
                    for (i = 0; i < N; i = i + 1) begin
                        mem[i] <= (NEG_INF_INIT == 0) ? {DATA_WIDTH{1'b0}} : NEG_INF;
                    end
                end else if (w_en) begin
                    mem[w_ptr] <= data_in;
                    if (w_ptr == wrap_limit - 1)
                        w_ptr <= 0;
                    else
                        w_ptr <= w_ptr + 1;
                end
            end

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_ptr <= START_READ_PTR;
                    data_out <= {DATA_WIDTH{1'b0}};
                end else if (r_en) begin
                    data_out <= mem[r_ptr];
                    if (r_ptr == wrap_limit - 1)
                        r_ptr <= 0;
                    else
                        r_ptr <= r_ptr + 1;
                end
            end

        end else if (NEG_INF_INIT == 1) begin

            reg [DATA_WIDTH-1:0] mem [0:N-1];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    w_ptr <= 0;
                    for (i = 0; i < N; i = i + 1) begin
                        mem[i] <= (NEG_INF_INIT == 0) ? {DATA_WIDTH{1'b0}} : NEG_INF;
                    end
                end else if (!rst_local_n) begin
                    w_ptr <= 0;
                    for (i = 0; i < N; i = i + 1) begin
                        mem[i] <= NEG_INF;
                    end
                end else if (w_en) begin
                    mem[w_ptr] <= data_in;
                    if (w_ptr == wrap_limit - 1)
                        w_ptr <= 0;
                    else
                        w_ptr <= w_ptr + 1;
                end
            end

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    r_ptr <= START_READ_PTR;
                    data_out <= {DATA_WIDTH{1'b0}};
                end else if (r_en) begin
                    data_out <= mem[r_ptr];
                    if (r_ptr == wrap_limit - 1)
                        r_ptr <= 0;
                    else
                        r_ptr <= r_ptr + 1;
                end
            end

        end else begin : gen_bram_logic
            // ----------------------------------------------------
            // LOGIC MỚI: SỬ DỤNG BRAM (KHÔNG RESET MẢNG)
            // ----------------------------------------------------
            
            // 1. Khối quản lý Con tr�? (Pointers) - Có Reset

            (* ram_style = "block" *) reg [DATA_WIDTH-1:0] mem [0:N-1];

            integer i;
            initial begin
                for (i = 0; i < N; i = i + 1) begin
                    mem[i] = {DATA_WIDTH{1'b0}};
                end
            end

            always @(posedge clk) begin
                if (!rst_n) begin
                    w_ptr <= 0;
                    r_ptr <= START_READ_PTR;
                end else begin
                    if (w_en) begin
                        if (w_ptr == wrap_limit - 1) w_ptr <= 0;
                        else                         w_ptr <= w_ptr + 1;
                    end
                    
                    if (r_en) begin
                        if (r_ptr == wrap_limit - 1) r_ptr <= 0;
                        else                         r_ptr <= r_ptr + 1;
                    end
                end
            end

            // 2. Khối Bộ nhớ BRAM - KHÔNG RESET
            always @(posedge clk) begin
                if (w_en) begin
                    mem[w_ptr] <= data_in;
                end
            end

            
            always @(posedge clk) begin
                if (r_en) begin
                    data_out <= mem[r_ptr];
                end
            end

        end
    endgenerate

endmodule