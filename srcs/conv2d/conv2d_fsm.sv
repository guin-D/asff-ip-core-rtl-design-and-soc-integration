import definition::*;

module conv2d_fsm (
    input  wire clk,
    input  wire rst_n,

    // Control signals
    input  wire start_i,
    input  wire norm_en_i,
    input  wire ld_w_done_i,
    input  wire thread_done_i,
    input  wire process_done_i,
    input  wire ifm_w_agu_done_i,
    input  wire ofm_agu_done_i,
    input  wire ack_i,

    // Output control signals
    output reg  bus_spr_o,
    output reg  nw_rd_o,
    output reg  bw_rd_o,
    output reg  cw_rd_o,
    output reg  ifm_rd_o,

    // Status signals
    output reg  done_o
);

    typedef enum reg [2:0] { 
        IDLE,
        LOAD_NORM_W,
        LOAD_BIAS_W,
        LOAD_CONV_W,
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
                    if (norm_en_i)
                        next_state = LOAD_NORM_W;
                    else
                        next_state = LOAD_CONV_W;
                end else begin
                    next_state = IDLE;
                end
            end

            LOAD_NORM_W: 
                    next_state = LOAD_BIAS_W;
            
            LOAD_BIAS_W: 
                    next_state = LOAD_CONV_W;
                
            LOAD_CONV_W: begin
                if (ld_w_done_i)
                    next_state = LOAD_INPUT;
            end

            LOAD_INPUT: begin
                if (ifm_w_agu_done_i)
                    next_state = WAIT;
                else if (process_done_i) begin
                    if (norm_en_i)
                        next_state = LOAD_NORM_W;
                    else
                        next_state = LOAD_CONV_W;
                end
                else if (thread_done_i)
                    next_state = LOAD_CONV_W;
            end

            WAIT: begin
                if (ofm_agu_done_i) begin
                    next_state = DONE;
                end
            end

            DONE: begin
                if (ack_i || !start_i) begin
                    next_state = IDLE;
                end
            end

            default: next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            nw_rd_o <= 0;
            bw_rd_o <= 0;
            cw_rd_o <= 0;
            ifm_rd_o <= 0;
            done_o <= 0;
            bus_spr_o <= 0;

        end else begin
            nw_rd_o <= 0;
            bw_rd_o <= 0;
            cw_rd_o <= 0;
            ifm_rd_o <= 0;
            done_o <= 0;
            bus_spr_o <= 0;

            case (next_state)
                LOAD_NORM_W: begin 
                    nw_rd_o <= 1;
                    bus_spr_o <= 1;
                end
                LOAD_BIAS_W: begin
                    bw_rd_o <= 1;
                    bus_spr_o <= 1;
                end
                LOAD_CONV_W: begin
                    cw_rd_o <= 1;
                end
                LOAD_INPUT: begin
                    ifm_rd_o <= 1;
                end
                DONE: begin
                    done_o <= 1;
                end
                default: ;
            endcase
        end
    end

endmodule
