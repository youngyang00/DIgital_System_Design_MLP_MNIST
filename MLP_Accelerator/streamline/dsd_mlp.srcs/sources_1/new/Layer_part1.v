`timescale 1ns / 1ps

module Layer_part1(
    input                   CLK,
    input                   RSTN,
    input                   START,
    input   [7:0]           IMAGE,
    input                   BUF_RD,
    
    output                  LAYER_PART1_DONE,
    output  [7:0]           LAYER1_OUT
    );

localparam COEFF1 = 18'h0_0026;

wire                        rst;
wire                        pu_start;
wire                        pu_clr;
wire                        pu_done;
wire       [128*32-1:0]     pu_out;

wire                        buf_wr;
wire       [31:0]           buf_out;   
wire       [49:0]           wr_buf_quant;         

reg        [7:0]            input_intermediate;     
reg        [7:0]            input_intermediate_delay1;

reg        [31:0]           buf_relu;
reg        [49:0]           buf_quant;

assign  rst = ~RSTN; 

always @(posedge CLK) begin
    if(rst) input_intermediate <= 8'b0;
    else input_intermediate <= {1'b0,IMAGE[7:1]};
    input_intermediate_delay1 <= input_intermediate;
end

// RELU logic
always @(posedge CLK) begin
    if(buf_out[31]==1'b0) buf_relu <= buf_out;
    else buf_relu <= 32'b0; 
end

always @(posedge CLK)begin
    buf_quant <= wr_buf_quant;
end

// round Logic
assign LAYER1_OUT = (buf_quant[15] ? buf_quant[23:16] + 1'b1 : buf_quant[23:16]);

multiplier_32x18 multiplier(
    .A(buf_relu),  // 32-bit input
    .B(COEFF1),  // 18-bit input
    .P(wr_buf_quant)  // 50-bit output (32 + 18 bits)
);

Layer_part1_controller Layer_part1_controller(
    .CLK(CLK),
    .RSTN(RSTN),
    .START(START),
    .PU_DONE(pu_done),
    .BUF_RD(BUF_RD),

    .PU_START(pu_start),
    .LAYER_PART1_DONE(LAYER_PART1_DONE),
    .PU_CLR(pu_clr),
    .BUF_WR(buf_wr)
);

    
PU_RowMatrix #(
    .OP1_COL(128),
    .OP1_WIDTH(8),
    .WEIGHT_ROW(784),
    .WEIGHT_COL(128),
    .WEIGHT_WIDTH(8),
    .DSPOUT_WIDTH(32),
    .BRAM_WIDTH(1024),
    .BRAM_DEPTH(1024),
    .BRAM_FILE_NAME("C:/Users/sjh00/00_RTL_Skeleton/dsd_mlp.srcs/sources_1/data/bram1.txt")

) Layer_part1_PU (
    .CLK(CLK),
    .RSTN(RSTN & ~pu_clr),
    .START(pu_start),
    .OP1(input_intermediate_delay1),
    .ACC_NUM(10'd783),
    .PREVENT_ADR_CLR(1'b0),
    .DONE(pu_done),
    .OUT(pu_out)
);    

Layer_part1_buffer layer1_part1_buffer(
    .CLK(CLK),
    .BUF_RD(BUF_RD),
    .BUF_WR(buf_wr),
    .BUF_IN_DATA(pu_out),
    .BUF_OUT_DATA(buf_out)
);

endmodule

module Layer_part1_controller(
    input CLK,
    input RSTN,
    input START,
    input PU_DONE,
    input BUF_RD,

    output reg PU_START,
    output reg LAYER_PART1_DONE,
    output reg PU_CLR,
    output reg BUF_WR
);

wire clr;

assign clr = ~RSTN;

reg [2:0] current_state, next_state;

always @(posedge CLK) begin
    if(clr) current_state <= 3'b0;
    else current_state <= next_state;
end

always @(*) begin
    case (current_state)
        3'd0:if(START) next_state = 3'd1;else next_state = 3'd0;
        3'd1:next_state = 3'd2;
        3'd2:if(PU_DONE) next_state = 3'd3;else next_state = 3'd2;
        3'd3:next_state = 3'd4;
        3'd4:if(START) next_state = 3'd1; else next_state = 3'd4;
        default: next_state = 3'd0;
    endcase
end

always @(*) begin
    case (current_state)
    3'd0: begin
        PU_START=1'b0;
        LAYER_PART1_DONE=1'b0;
        PU_CLR=1'b0;
        BUF_WR=1'b0;
    end
    3'd1:begin
        PU_START=1'b1;
        LAYER_PART1_DONE=1'b0;
        PU_CLR=1'b0;
        BUF_WR=1'b0;
    end
    3'd2:begin 
        PU_START=1'b0;
        LAYER_PART1_DONE=1'b0;
        PU_CLR=1'b0;
        BUF_WR=1'b0;
    end
    3'd3:begin
        PU_START=1'b0;
        LAYER_PART1_DONE=1'b0;
        PU_CLR=1'b0;
        BUF_WR=1'b1;
    end
    3'd4:begin
        PU_START=1'b0;
        LAYER_PART1_DONE=1'b1;
        PU_CLR=1'b1;
        BUF_WR=1'b0;
    end
    default:begin
        PU_START=1'b0;
        LAYER_PART1_DONE=1'b0;
        PU_CLR=1'b1;
        BUF_WR=1'b0;
    end
    endcase
end
    
endmodule

module Layer_part1_buffer(
    input CLK,
    input BUF_RD,
    input BUF_WR,
    input [128*32-1:0] BUF_IN_DATA,
    output [31:0] BUF_OUT_DATA
);

    integer i;
    reg [31:0] buffer [127:0];

    assign BUF_OUT_DATA = buffer[0];
    
    always @(posedge CLK) begin
        if(BUF_WR) begin
            for (i = 0; i < 128; i= i +1) begin
                buffer[i] <= BUF_IN_DATA[32*i +: 32];
            end
        end
        else if(BUF_RD)
            for (i = 0 ; i < 127; i=i + 1) begin
                buffer[i] <= buffer[i+1];   
            end
    end
    
endmodule

module multiplier_32x18 (
    input [31:0] A,  // 32-bit input
    input [17:0] B,  // 18-bit input
    output [49:0] P  // 50-bit output (32 + 18 bits)
);

    wire [49:0] partial_products [0:17];  // Array to hold partial products

    // Generate partial products
    genvar i;
    generate
        for (i = 0; i < 18; i = i + 1) begin : partial_product_gen
            assign partial_products[i] = B[i] ? (A << i) : 50'b0;
        end
    endgenerate

    // Stage 1: Sum the partial products in pairs using adders
    wire [49:0] sum_stage1 [0:8];
    wire [49:0] carry_stage1 [0:8];
    generate
        for (i = 0; i < 9; i = i + 1) begin : stage1
            assign {carry_stage1[i], sum_stage1[i]} = partial_products[2*i] + partial_products[2*i + 1];
        end
    endgenerate

    // Stage 2: Sum the results of stage 1
    wire [49:0] sum_stage2 [0:3];
    wire [49:0] carry_stage2 [0:3];
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage2
            assign {carry_stage2[i], sum_stage2[i]} = sum_stage1[2*i] + sum_stage1[2*i + 1] + carry_stage1[2*i + 1];
        end
    endgenerate

    // Stage 3: Sum the results of stage 2
    wire [49:0] sum_stage3 [0:1];
    wire [49:0] carry_stage3 [0:1];
    generate
        for (i = 0; i < 2; i = i + 1) begin : stage3
            assign {carry_stage3[i], sum_stage3[i]} = sum_stage2[2*i] + sum_stage2[2*i + 1] + carry_stage2[2*i + 1];
        end
    endgenerate

    // Final stage: Sum the results of stage 3
    wire [49:0] final_sum;
    wire [49:0] final_carry;
    assign {final_carry, final_sum} = sum_stage3[0] + sum_stage3[1] + carry_stage3[1];

    // Combine final sum and carry to produce the final product
    assign P = final_sum + final_carry;

endmodule


