`timescale 1ns / 1ps

module top_mlp #(
    parameter IN_IMG_NUM = 10,
	parameter FP_BW = 32,
	parameter INT_BW = 8,
    parameter X_BUF_DATA_WIDTH = INT_BW*IN_IMG_NUM,  	// add in 2024-04-17 / if you try INT8 Streamline , you should change X_BUF_DATA_WIDTH to this line
//	parameter X_BUF_DATA_WIDTH = FP_BW*IN_IMG_NUM,
	parameter X_BUF_DEPTH = 784*IN_IMG_NUM,
    parameter W_BUF_DATA_WIDTH = INT_BW *IN_IMG_NUM,		// add in 2024-04-17 / if you try INT8 Streamline , you should change W_BUF_DATA_WIDTH to this line
//	parameter W_BUF_DATA_WIDTH = FP_BW *IN_IMG_NUM, 	
	parameter W_BUF_DEPTH = 784*IN_IMG_NUM,
    parameter Y_BUF_DATA_WIDTH = 32,
	parameter Y_BUF_ADDR_WIDTH = 32,  							// add in 2023-05-10
    parameter Y_BUF_DEPTH = 10*IN_IMG_NUM * 4 					// modify in 2024-04-17, y_buf_addr has to increase +4 -> 0 - 396
)(
    // system interface
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire                            start_i,
    output  wire                            done_intr_o,
    output  wire                            done_led_o,
    // output buffer interface
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [$clog2(Y_BUF_DEPTH)-1:0]  y_buf_addr,			// modify in 2023-05-10, [$clog2(Y_BUF_DEPTH)-1:0] -> [Y_BUF_ADDR_WIDTH-1:0]
    output  wire [Y_BUF_DATA_WIDTH-1:0]     y_buf_data
);

assign y_buf_wr_en = y_buf_en;

top_mlp_sub top_mlp_sub(
        .CLK(clk),
        .RSTN(rst_n),
        .START(start_i),
        .DONE_INTR(done_intr_o),
        .DONE_LED(done_led_o),
        .Y_BUF_EN(y_buf_en),
        .Y_BUF_ADDR(y_buf_addr),
        .Y_BUF_DATA(y_buf_data)
);
    
    
endmodule
