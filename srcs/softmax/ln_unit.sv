import definition::*;

module ln_unit (
    input  wire [DATA_WIDTH:0]   data_i,  // UQ2.15
    output wire [DATA_WIDTH-1:0] data_o   // UQ8.8 
);

    //=========================================================================
    // F = 2^w * m (1 <= m < 2)
    // lnF = = ln2 * log2F = ln2 * (w + log2m)
    // (1 <= m < 2) => log2m ~~ m - 1
    // => lnF = ln2 * (m - 1 + w)
    // LOD: data_i[16]: w = 1, data_i[15]: w = 0   (1 <= F <= 3)
    //=========================================================================
    
    wire w = data_i[16]; 

    // X = (m - 1 + w)
    wire [15:0] X;     // UQ1.15

    assign X = w ? {1'b1, data_i[15:1]} : {1'b0, data_i[14:0]};

    // =========================================================================
    // X * ln(2) ~ 0.1011_2
    // lnF = X * (0.1_2 + 0.01_2 - 0.0001_2)
    // lnF = (X >> 1) + (X >> 2) - (X >> 4)
    // lnF = A + B + F_inv + 1
    // =========================================================================
    
    wire [16:0] A_val;
    wire [16:0] B_val;
    wire [16:0] D_val;
    wire [16:0] F_inv;     
    wire [16:0] lnF;      // UQ2.15

    assign A_val = {2'b0, X[15:1]};  
    assign B_val = {3'b0, X[15:2]};  
    assign D_val = {5'b0, X[15:4]}; 
    assign F_inv = ~D_val;   

    
    assign lnF = A_val + B_val + F_inv + 17'd1;

    // ==================
    // UQ2.15 -> UQ8.8
    // ==================
    
    assign data_o = {6'b0, lnF[16:15], lnF[14:7]};

endmodule