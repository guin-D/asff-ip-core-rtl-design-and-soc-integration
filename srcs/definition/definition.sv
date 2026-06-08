package definition;
	
	parameter DATA_WIDTH = 16;
    parameter BUS_WIDTH = 32;
    parameter DATA_WIDTH_BUF = 48;                         // accum buf of conv2d
    parameter NUM_LANE = BUS_WIDTH / DATA_WIDTH;
    parameter WEIGHT_ADDR_WIDTH = 12;
    parameter DATA_ADDR_WIDTH = 12;
    parameter GLOBAL_ADDR_WIDTH = 12;

    parameter KERNEL_SIZE = 3;

    parameter MAX_CHANNEL_L2 = 4;
    parameter MAX_CHANNEL_L1 = MAX_CHANNEL_L2 * 2;
    parameter MAX_CHANNEL_L0 = MAX_CHANNEL_L1 * 2;
    parameter MAX_CHANNEL = MAX_CHANNEL_L0 * 2;

    parameter SOFTMAX_CHANNEL = 4;  // alpha, beta, gamma, zero

    parameter MAX_HW_L0 = 8;
    parameter MAX_HW_L1 = MAX_HW_L0 * 2;
    parameter MAX_HW_L2 = MAX_HW_L1 * 2;
    parameter MAX_SIZE = MAX_HW_L2;

    // int và frac
    parameter DATA_INT = 4;
    parameter DATA_FRAC = 12;
    parameter WEIGHT_INT = 2;
    parameter WEIGHT_FRAC = 14;
    parameter SIW_INT   = 8;            // Spatial importance weight
    parameter SIW_FRAC  = 8;
endpackage