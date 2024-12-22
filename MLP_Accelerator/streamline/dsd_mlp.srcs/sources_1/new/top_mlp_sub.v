`timescale 1ns / 1ps

module top_mlp_sub(
    input           CLK,
    input           RSTN,
    input           START,

    output          DONE_INTR,
    output          DONE_LED,
    output          Y_BUF_EN,
    output  [31:0]  Y_BUF_ADDR,
    output  [31:0]  Y_BUF_DATA
);
parameter INPUT_BRAM_FILE = "C:/Users/sjh00/streamline/dsd_mlp.srcs/sources_1/data/IMAGE.txt";



wire [$clog2(8192)-1:0] img_addr;
wire img_rd_en;                   
wire [7:0] img_out;
wire [7:0] layer1_out;

wire Layer_part1_done;
wire Layer_part1_start;
wire Layer_part2_start;
wire layer_part2_clr;
wire buf_rd;
wire buf_32_rd;
wire          LAYER2_DONE;
wire [31:0]   LAYER2_OUT; 

MLP_Controller MLP_Controller(
    .CLK(CLK),
    .RSTN(RSTN),
    .START(START),
    .LAYER_PART1_DONE(Layer_part1_done),
    .LAYER2_DONE(LAYER2_DONE),
    .BUF_32_RD(buf_32_rd),
    .IMG_ADDR(img_addr),
    .IMG_RD_EN(img_rd_en),
    .LAYER_PART1_START(Layer_part1_start),
    .LAYER_PART2_START(Layer_part2_start),
    .LAYER_PART2_CLR(layer_part2_clr),
    .Y_BUF_EN(Y_BUF_EN),
    .Y_BUF_ADDR(Y_BUF_ADDR),
    .DONE_LED(DONE_LED),
    .DONE_INTR(DONE_INTR)
);

xilinx_simple_dual_port_1_clock_ram #(
  .RAM_WIDTH(8),                       // Specify RAM data width
  .RAM_DEPTH(8192),                     // Specify RAM depth (number of entries)
  .RAM_PERFORMANCE("LOW_LATENCY"), // Select "HIGH_PERFORMANCE" or "LOW_LATENCY" 
  .INIT_FILE(INPUT_BRAM_FILE)                        // Specify name/location of RAM initialization file if using one (leave blank if not)
)IMAGE_BRAM(
  .addra(),   // Write address bus, width determined from RAM_DEPTH
  .addrb(img_addr),   // Read address bus, width determined from RAM_DEPTH
  .dina(),     // RAM input data, width determined from RAM_WIDTH
  .clka(CLK),     // Clock
  .wea(1'b0),       // Write enable
  .enb(img_rd_en),	     // Read Enable, for additional power savings, disable when not in use
  .rstb(),     // Output reset (does not affect memory contents)
  .regceb(), // Output register enable
  .doutb(img_out)    // RAM output data, width determined from RAM_WIDTH
);

Layer_part1 Layer1_Processing_Unit(
  .CLK(CLK),
  .RSTN(RSTN),
  .START(Layer_part1_start),
  .IMAGE(img_out),
  .BUF_RD(buf_rd),

  .LAYER_PART1_DONE(Layer_part1_done),
  .LAYER1_OUT(layer1_out)
  );

Layer_part2 Layer2_Processing_Unit(
    .CLK(CLK),
    .RSTN(RSTN & ~layer_part2_clr),
    .LAYER_PART2_START(Layer_part2_start),
    .LAYER2_INPUT(layer1_out),
    .BUF_32_RD(buf_32_rd),
    .BUF_RD(buf_rd),
    .LAYER2_DONE(LAYER2_DONE),
    .LAYER2_OUT(Y_BUF_DATA)
);    

ila_0 ILA(
	.clk(CLK), // input wire clk
	.probe0(Y_BUF_ADDR), // input wire [31:0]  probe0  
	.probe1(Y_BUF_DATA), // input wire [31:0]  probe1 
	.probe2(Y_BUF_EN), // input wire [0:0]  probe2 
	.probe3(DONE_INTR), // input wire [0:0]  probe3 
	.probe4(DONE_LED), // input wire [0:0]  probe4 
	.probe5(), // input wire [0:0]  probe5 
	.probe6(), // input wire [0:0]  probe6 
	.probe7(), // input wire [0:0]  probe7 
	.probe8(), // input wire [0:0]  probe8 
	.probe9() // input wire [0:0]  probe9
);



endmodule