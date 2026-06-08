module dynamic_counter #(
    parameter START_VALUE = 0,
    parameter COUNT_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    
    input  wire [COUNT_WIDTH-1:0] max_value, 
    
    output wire max_tick,
    output wire at_max,
    output wire at_max_pulse,
    output wire [COUNT_WIDTH-1:0] value
);

    reg [COUNT_WIDTH-1:0] out_tmp;
    reg at_max_d1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_tmp <= START_VALUE;
            at_max_d1 <= 1'b0;
        end
        else begin
            if (inc) begin
                if (out_tmp == max_value)
                    out_tmp <= START_VALUE;   
                else
                    out_tmp <= out_tmp + 1;
            end
            at_max_d1 <= at_max;
        end       
    end

    assign value = out_tmp;
    assign at_max = out_tmp == max_value;
    assign max_tick = at_max && inc;
    assign at_max_pulse = at_max && (!at_max_d1);
endmodule