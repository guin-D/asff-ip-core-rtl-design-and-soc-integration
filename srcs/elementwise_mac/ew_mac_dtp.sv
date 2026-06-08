import definition::*;

module ew_mac_dtp (
    input  wire                          clk,
    input  wire                          rst_n,

    // Data signals
    input  wire [BUS_WIDTH-1:0]          data_i,
    input  wire                          valid_i,
    input  wire [BUS_WIDTH-1:0]          siw_i,
    input  wire                          w_valid_i,
    
    // Control signals
    input  wire                          final_siw_i,

    // Output control signals
    output wire                          ofm_addr_valid_o,

    // Output signals
    output wire [BUS_WIDTH-1:0]          data_o,
    output wire                          valid_o
);

    wire [DATA_WIDTH-1:0] data_siw_to_buf;
    wire [DATA_WIDTH-1:0] data_buf_to_m;
    
    wire [NUM_LANE-1:0] valid_pe;

    wire  wr_buf;

    siw_serializer siw_serializer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_i(siw_i),
        .valid_i(w_valid_i),
        .data_serial_o(data_siw_to_buf),
        .valid_o(wr_buf)
    );

    circular_rmw_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .N(3)
    ) siw_buffer_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wrap_limit(3),
        .w_en(wr_buf),
        .data_in(data_siw_to_buf),
        .r_en(valid_i),
        .data_out(data_buf_to_m)
    );

    genvar i;
    generate
        for (i = 0; i < NUM_LANE; i++) begin : gen_ew_mac_pe
            
            ew_mac_pe pe_inst (
                .clk          (clk),
                .rst_n        (rst_n),

                // Data signals
                .data_i       (data_i[i*DATA_WIDTH +: DATA_WIDTH]),
                .valid_i      (valid_i),
                .siw_i        (data_buf_to_m),
                
                // Control signals
                .final_siw_i  (final_siw_i),

                // Output control signals
                .ofm_addr_valid_o (ofm_addr_valid_o),

                // Output signals
                .data_o       (data_o[i*DATA_WIDTH +: DATA_WIDTH]),
                .valid_o      (valid_pe[i])
            );

        end
    endgenerate

    assign valid_o = &valid_pe;

endmodule