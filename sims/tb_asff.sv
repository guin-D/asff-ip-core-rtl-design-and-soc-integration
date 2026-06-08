`timescale 1ns / 1ps

import definition::*;

module tb_asff_top;

    
    parameter MEM_DEPTH   = 7978; 
    parameter GOL_DEPTH   = 7168; 

    reg  clk;
    reg  rst_n;
    reg  axi_rst_n;

    // Control & Config signals
    reg                                  start_i;
    reg  [$clog2(MAX_SIZE+1)-1:0]        cfg_size_i;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_i;
    reg  [$clog2(MAX_CHANNEL+1)-1:0]     cfg_channel_com_i;

    // AXI4-Stream Slave (Inputs to DUT)
    reg                  s_axis_valid_i;
    reg  [BUS_WIDTH-1:0] s_axis_data_i;
    wire                 s_axis_ready_o;

    // AXI4-Stream Master (Outputs from DUT)
    wire                 m_axis_valid_o;
    wire [BUS_WIDTH-1:0] m_axis_data_o;
    reg                  m_axis_ready_i;

    // Status
    wire                 done_o;

    reg [BUS_WIDTH-1:0] mem_data [0:MEM_DEPTH-1];
    
    reg [BUS_WIDTH-1:0] golden_data [0:GOL_DEPTH-1];
    
    integer gold_idx = 0;
    integer error_count = 0;
    integer i;

    asff_system_wrapper uut (
        .axi_clk          (clk),
        .axi_rst_n        (axi_rst_n),
        .rst_n            (rst_n),
        .start_i          (start_i),
        .cfg_size_i       (cfg_size_i),
        .cfg_channel_i    (cfg_channel_i),
        .cfg_channel_com_i(cfg_channel_com_i),
        .s_axis_valid_i   (s_axis_valid_i),
        .s_axis_data_i    (s_axis_data_i),
        .s_axis_ready_o   (s_axis_ready_o),
        .m_axis_valid_o   (m_axis_valid_o),
        .m_axis_data_o    (m_axis_data_o),
        .m_axis_ready_i   (m_axis_ready_i),
        .done_o           (done_o)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $readmemh("D:/usually_used/ic/Vivado/HLx/ASFF/ASFF_2/python/memory.hex", mem_data);
        $readmemh("D:/usually_used/ic/Vivado/HLx/ASFF/ASFF_2/python/golden.hex", golden_data);
    end

    // Direct Test
    initial begin
    
        rst_n             = 0;
        axi_rst_n         = 0;
        start_i           = 0;
        cfg_size_i        = 0;
        cfg_channel_i     = 0;
        cfg_channel_com_i = 0;
        
        s_axis_valid_i    = 0;
        s_axis_data_i     = 0;
        
        @(posedge clk);
        m_axis_ready_i    <= 1; 
        
        
        #20;
        rst_n = 1;
        axi_rst_n = 1;
        #20;

        @(posedge clk);
        cfg_size_i        <= 8;  
        cfg_channel_i     <= 4;  
        cfg_channel_com_i <= 2;   
        
        @(posedge clk);
        start_i           <= 1'b1; 
        
        s_axis_valid_i <= 1'b0;
        
        for (i = 0; i < MEM_DEPTH; i = i + 1) begin
            
            s_axis_valid_i <= 1'b1;
            s_axis_data_i  <= mem_data[i];
            
            @(posedge clk);
            
            while (s_axis_ready_o == 1'b0) begin
                @(posedge clk);
            end
        end
        
        s_axis_valid_i <= 1'b0;
        s_axis_data_i  <= 0;

        wait (done_o == 1'b1);
        #100; 
        if (error_count == 0) begin
            $display("---------------------------------------");
            $display("SUCCESS: Tat ca ket qua deu trung khop!");
            $display("---------------------------------------");
        end else begin
            $display("---------------------------------------");
            $display("FAILURE: Co %d loi duoc tim thay!", error_count);
            $display("---------------------------------------");
        end
        $display("Mo phong thanh cong!");
        
        #100;
        
        @(posedge clk);
        rst_n <= 0;
        
        #100;
        
        @(posedge clk);
        rst_n <= 1;
        
        $finish;
    end
    
    always @(posedge clk) begin
        if (rst_n && m_axis_valid_o && m_axis_ready_i) begin
            if (m_axis_data_o !== golden_data[gold_idx]) begin
                $display("[ERROR] Tai index %d: DUT = %h | Golden = %h", 
                          gold_idx, m_axis_data_o, golden_data[gold_idx]);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] Tai index %d: Data = %h", gold_idx, m_axis_data_o);
            end
            
            gold_idx = gold_idx + 1;
        end
    end

endmodule