import definition::*;

module siw_serializer (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [BUS_WIDTH-1:0]    data_i,
    input  logic                    valid_i,
    output logic [DATA_WIDTH-1:0]   data_serial_o,
    output logic                    valid_o
);

    logic [DATA_WIDTH-1:0] beta_saved;
    logic [DATA_WIDTH-1:0] gamma_saved;
    logic [1:0] seq_cnt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            seq_cnt       <= 2'd0;
            beta_saved    <= 0;
            gamma_saved   <= 0;
            data_serial_o <= 0;
            valid_o       <= 1'b0;
        end else begin
            case (seq_cnt)
                2'd0: begin
                    if (valid_i) begin 
                        data_serial_o <= data_i[DATA_WIDTH-1:0];      
                        beta_saved    <= data_i[DATA_WIDTH*2-1:DATA_WIDTH]; 
                        valid_o       <= 1'b1; 
                        seq_cnt       <= 2'd1; 
                    end else begin
                        valid_o       <= 1'b0;
                    end
                end

                2'd1: begin
                    if (valid_i) begin 
                        data_serial_o <= beta_saved;                  
                        gamma_saved   <= data_i[DATA_WIDTH-1:0];      
                        valid_o       <= 1'b1; 
                        seq_cnt       <= 2'd2; 
                    end else begin
                        valid_o       <= 1'b0; 
                    end
                end

                2'd2: begin
                    data_serial_o <= gamma_saved; 
                    valid_o       <= 1'b1; 
                    seq_cnt       <= 2'd0; 
                end

                default: begin
                    seq_cnt <= 2'd0;
                    valid_o <= 1'b0;
                end
            endcase
        end
    end

endmodule