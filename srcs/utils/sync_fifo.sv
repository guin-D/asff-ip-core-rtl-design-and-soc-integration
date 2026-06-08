module sync_fifo(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  wr_en,
    input  wire [BUS_WIDTH-1:0] din,
    output wire                  full,

    input  wire                  rd_en,
    output wire [BUS_WIDTH-1:0] dout,
    output wire                  empty
);

    reg [BUS_WIDTH-1:0] mem [0:3];
    
    reg [2:0] wr_ptr;
    reg [2:0] rd_ptr;

    wire [1:0] wr_idx = wr_ptr[1:0];
    wire [1:0] rd_idx = rd_ptr[1:0];

    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[2] != rd_ptr[2]) && (wr_idx == rd_idx);

    assign dout = mem[rd_idx];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 3'b0;
            rd_ptr <= 3'b0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_idx] <= din;
                wr_ptr      <= wr_ptr + 1'b1;
            end
            
            if (rd_en && !empty) begin
                rd_ptr      <= rd_ptr + 1'b1;
            end
        end
    end

endmodule