import definition::*;

module softmax_fsm (
    input  wire clk,
    input  wire rst_n,

    // Control signals
    input  wire start_i,
    input  wire rd_done_i,
    input  wire wr_done_i,

    // Output control signals
    output reg  rd_o,
    
    // Status signals
    output reg  done_o
);

    typedef enum reg [2:0] { 
        IDLE,
        LOAD_INPUT,
        WAIT,
        DONE
    } state_t;

    state_t state;
    state_t next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (start_i) begin
                    next_state = LOAD_INPUT;
                end
            end

            LOAD_INPUT: begin
                if (rd_done_i) begin
                    next_state = WAIT;
                end
            end

            WAIT: begin
                if (wr_done_i) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                if (!start_i) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            rd_o <= 0;
            done_o <= 0;

        end else begin
            rd_o <= 0;
            done_o <= 0;

            case (next_state)
                LOAD_INPUT: begin
                    rd_o <= 1;
                end
                DONE: begin
                    done_o <= 1;
                end
                default: ;
            endcase
        end
    end

endmodule