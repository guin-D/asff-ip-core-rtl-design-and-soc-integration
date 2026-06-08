import definition::*;

module ew_mac_fsm (
    input  wire clk,
    input  wire rst_n,

    // Control signals
    input  wire start_i,
    input  wire rd_pack_done_i,
    input  wire rd_pixel_done_i,
    input  wire rd_done_i,
    input  wire wr_done_i,

    // Output control signals
    output reg  siw_rd_o,
    output reg  ifm_rd_o,
    
    // Status signals
    output reg  done_o
);

    typedef enum reg [2:0] { 
        IDLE,
        LOAD_SIW,
        LOAD_PIXEL,
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
                    next_state = LOAD_SIW;
                end
            end

            LOAD_SIW: begin
                if (rd_pack_done_i) begin
                    next_state = LOAD_PIXEL;
                end
            end
                            
            LOAD_PIXEL: begin
                if (rd_done_i) begin
                    next_state = WAIT;
                end else if (rd_pixel_done_i) begin
                    next_state = LOAD_SIW;
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
            siw_rd_o <= 0;
            ifm_rd_o <= 0;
            done_o   <= 0;

        end else begin
            siw_rd_o <= 0;
            ifm_rd_o <= 0;
            done_o   <= 0;

            case (next_state)
                LOAD_SIW: begin
                    siw_rd_o <= 1;
                end
                LOAD_PIXEL: begin
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