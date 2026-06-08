import definition::*;

module exponential_unit (
    input  wire [DATA_WIDTH-1:0] data_i,  // UQ8.8 
    output wire [DATA_WIDTH-1:0] data_o  // UQ1.15
);

    //======================================================
    // data_i * log2(e) ~ 1.0111_2)
    // E = A + B + F + 1 (with B = A>>1, D = A>>4, F = ~D)
    //======================================================
    
    wire [DATA_WIDTH:0] A_ext;            
    wire [DATA_WIDTH:0] B_ext;     
    wire [DATA_WIDTH:0] D_ext;  
    wire [DATA_WIDTH:0] F_ext;               

    wire [DATA_WIDTH:0] E;   // UQ9.8

    assign A_ext = {1'b0, data_i}; 
    assign B_ext = {2'b0, data_i[DATA_WIDTH-1:1]}; 
    assign D_ext = {5'b0, data_i[DATA_WIDTH-1:4]};    
    assign F_ext = ~D_ext;    
    
    assign E = A_ext + B_ext + F_ext + 17'd1; 

    //======================================================
    // e^(-x) -> 2^(-v_i) >> u_i
    //======================================================

    wire [8:0] u_i;
    wire [7:0] v_i;

    assign u_i = E[16:8];  
    assign v_i = E[7:0];   

    //=============================================================================
    // 2^(-v_i) (with P = 0) ~~ f(v_i) = b - k*v_i 
    //                                 = 1 - (v_i >> 1)  (Piecewise linear fitting)
    //=============================================================================
    
    wire [8:0]  v_fitted;     //UQ1.8
    wire [15:0] v_base;       //UQ1.15

    assign v_fitted = 9'h100 - {1'b0, v_i[7:1]};
    assign v_base = {v_fitted, 7'b0}; 

    //=====================
    // 2^(-v_i) >> u_i
    //=====================
    
    assign data_o = (u_i > 9'd15) ? 16'd0 : (v_base >> u_i);

endmodule