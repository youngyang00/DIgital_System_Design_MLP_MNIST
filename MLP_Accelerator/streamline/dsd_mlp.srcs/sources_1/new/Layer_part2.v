module Layer_part2(
    input               CLK,
    input               RSTN,
    input               LAYER_PART2_START,
    input   [7:0]       LAYER2_INPUT,
    input               BUF_32_RD,
    
    output              BUF_RD,
    output              LAYER2_DONE,
    output  [31:0]      LAYER2_OUT
);    

localparam COEFF2 = 18'h0_00DC;
localparam COEFF3 = 18'h0_01A1;
localparam COEFF4 = 18'h0_0160;

wire                    pu_start;
wire                    pu1_done;
wire                    pu2_done;
wire                    pu_all_done;
wire                    pu_clr;
wire        [6:0]       acc_num;
wire        [32*32-1:0] pu1_out,pu2_out;
wire        [32*32-1:0] pu_add_out;
wire        [64*32-1:0] pu_concatened;

wire        [64*32-1:0] buf_32_in;
wire                    buf_32_in_sel;
wire                    buf_32_rd;
wire                    buf_32_rd2;
wire                    buf_32_wr;
wire        [31:0]      buf_32_out;
wire        [31:0]      buf_32_out2;
wire        [49:0]      wr_buf_quant;
wire        [49:0]      wr_buf_quant2;
wire        [7:0]       result;
wire        [7:0]       result2;
wire        [1:0]       pu_sel1;
wire        [1:0]       pu_sel2;
wire                    pu_prevent_clr;

reg         [17:0]      coeff;
wire        [1:0]       coeff_sel;

reg         [7:0]       pu1_in;
reg         [7:0]       pu2_in;
reg         [31:0]      buf_32_relu;
reg         [31:0]      buf_32_relu2;
reg         [31:0]      buf_32_quant;
reg         [31:0]      buf_32_quant2;

assign pu_concatened = {pu2_out,pu1_out};
assign pu_all_done = pu1_done & pu2_done;
assign buf_32_in = buf_32_in_sel ? {{1024{1'b0}},{pu_add_out}} : pu_concatened;
assign LAYER2_OUT = buf_32_out;

//PU1 input selection logic
always @(*) begin
    case (pu_sel1)
        2'd0:pu1_in = LAYER2_INPUT; 
        2'd1:pu1_in = result;
        2'd2:pu1_in = result;
        default:pu1_in = 8'dx; 
    endcase
end

//PU2 input selection logic
always @(*) begin
    case (pu_sel2)
        2'd0:pu2_in = LAYER2_INPUT; 
        2'd1:pu2_in = result;
        2'd2:pu2_in = result2;
        default:pu2_in = 8'dx;
    endcase
end

//RELU logic
always @(posedge CLK) begin
    if(buf_32_out[31]==1'b0) buf_32_relu <= buf_32_out;
    else buf_32_relu <= 32'b0; 

    if(buf_32_out2[31]==1'b0) buf_32_relu2 <= buf_32_out2;
    else buf_32_relu2 <= 32'b0; 
end



always @(posedge CLK)begin
    buf_32_quant  <= wr_buf_quant;
    buf_32_quant2 <= wr_buf_quant2;
end

// round Logic
assign result  = (buf_32_quant[15] ? buf_32_quant[23:16] + 1'b1 : buf_32_quant[23:16]);
assign result2 = (buf_32_quant2[15] ? buf_32_quant2[23:16] + 1'b1 : buf_32_quant2[23:16]);


//COEEF SEL MUX
always @(*) begin
    case (coeff_sel)
    2'd0:coeff = COEFF2;
    2'd1:coeff = COEFF3;
    2'd2:coeff = COEFF4;
    default:coeff = 18'h0;
    endcase
end

adder32 adder(
    .A(pu1_out),
    .B(pu2_out),
    .C(pu_add_out)
);

multiplier_32x18 multiplier1(
    .A(buf_32_relu),  // 32-bit input
    .B(coeff),  // 18-bit input
    .P(wr_buf_quant)  // 50-bit output (32 + 18 bits)
);

multiplier_32x18 multiplier2(
    .A(buf_32_relu2),  // 32-bit input
    .B(coeff),  // 18-bit input
    .P(wr_buf_quant2)  // 50-bit output (32 + 18 bits)
);

Layer_part2_controller layer2_part2_controller(
    .CLK(CLK),
    .RSTN(RSTN),
    .LAYER_PART2_START(LAYER_PART2_START),
    .PU_DONE(pu_all_done),
    
    .BUF_RD(BUF_RD),
    .PU_START(pu_start),
    .PU_CLR(pu_clr),
    .PU_PREVENT_CLR(pu_prevent_clr),
    .ACC_NUM(acc_num),
    .BUF_32_IN_SEL(buf_32_in_sel),
    .BUF_32_RD(buf_32_rd),
    .BUF_32_RD2(buf_32_rd2),
    .BUF_32_WR(buf_32_wr),
    .PU_SEL1(pu_sel1),
    .PU_SEL2(pu_sel2),
    .COEFF_SEL(coeff_sel),
    .LAYER2_DONE(LAYER2_DONE)
);

Layer_part2_buffer_32bit_port buffer_32bit_port(
    .CLK(CLK),
    .BUF_RD(buf_32_rd | BUF_32_RD),
    .BUF_RD2(buf_32_rd2),
    .BUF_WR(buf_32_wr),
    .BUF_IN_DATA(buf_32_in),
    .BUF_OUT_DATA1(buf_32_out),
    .BUF_OUT_DATA2(buf_32_out2)
);

PU_RowMatrix #(
    .OP1_COL(32),
    .OP1_WIDTH(8),
    .WEIGHT_ROW(128),
    .WEIGHT_COL(32),
    .WEIGHT_WIDTH(8),
    .DSPOUT_WIDTH(32),
    .BRAM_WIDTH(256),
    .BRAM_DEPTH(256),
    .BRAM_FILE_NAME("C:/Users/sjh00/00_RTL_Skeleton/dsd_mlp.srcs/sources_1/data/bram2_1.txt")

) Layer_part2_PU1 (
    .CLK(CLK),
    .RSTN(RSTN & ~pu_clr),
    .START(pu_start),
    .OP1(pu1_in),
    .ACC_NUM(acc_num),
    .PREVENT_ADR_CLR(pu_prevent_clr),
    .DONE(pu1_done),
    .OUT(pu1_out)
);    

PU_RowMatrix #(
    .OP1_COL(32),
    .OP1_WIDTH(8),
    .WEIGHT_ROW(128),
    .WEIGHT_COL(32),
    .WEIGHT_WIDTH(8),
    .DSPOUT_WIDTH(32),
    .BRAM_WIDTH(256),
    .BRAM_DEPTH(256),
    .BRAM_FILE_NAME("C:/Users/sjh00/00_RTL_Skeleton/dsd_mlp.srcs/sources_1/data/bram2_2.txt")

) Layer_part2_PU2 (
    .CLK(CLK),
    .RSTN(RSTN & ~pu_clr),
    .START(pu_start),
    .OP1(pu2_in),
    .ACC_NUM(acc_num),
    .PREVENT_ADR_CLR(pu_prevent_clr),
    .DONE(pu2_done),
    .OUT(pu2_out)
);    


endmodule

module Layer_part2_controller(
    input CLK,
    input RSTN,
    input LAYER_PART2_START,
    input PU_DONE,

    output          reg         BUF_RD,
    output          reg         PU_START,
    output          reg         PU_CLR,
    output          reg         PU_PREVENT_CLR,
    output          reg  [1:0]  PU_SEL1,
    output          reg  [1:0]  PU_SEL2,
    output          reg  [6:0]  ACC_NUM,
    output          reg         BUF_32_IN_SEL,
    output          reg         BUF_32_RD,
    output          reg         BUF_32_RD2,
    output          reg         BUF_32_WR,
    output          reg  [1:0]  COEFF_SEL,
    output          reg         LAYER2_DONE
);


wire    clr;
reg [3:0] current_state, next_state;

assign clr = ~RSTN;

always @(posedge CLK) begin
    if(clr) current_state <= 4'b0;
    else current_state <= next_state;
end

always @(*) begin
    case (current_state)
    4'd0:if(LAYER_PART2_START)next_state = 4'd1; else next_state = 4'd0;
    4'd1:if(PU_DONE)next_state = 4'd2; else next_state = 4'd1;
    4'd2:next_state = 4'd3;
    4'd3:next_state = 4'd4;
    4'd4:if(PU_DONE) next_state = 4'd5; else next_state = 4'd4;
    4'd5:next_state = 4'd6;
    4'd6:next_state = 4'd7;
    4'd7:if(PU_DONE) next_state = 4'd8; else next_state = 4'd7;
    4'd8:next_state = 4'd9;
    4'd9:next_state = 4'd10;
    4'd10:if(PU_DONE) next_state = 4'd11; else next_state = 4'd10;
    4'd11:next_state = 4'd12;
    4'd12:next_state = 4'd12;
    default: next_state = 4'dx;
    endcase

end

always @(*) begin
    case (current_state)
    4'd0:begin //IDLE
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd0;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd0;
        PU_SEL2 = 2'd0;
        PU_PREVENT_CLR=1'b0;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end
    4'd1:begin // Calcuation layer2
        BUF_RD = 1'b1;
        PU_START = 1'b1;
        ACC_NUM = 7'd127;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd0;
        PU_SEL2 = 2'd0; 
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end
    4'd2:begin // Buffer writing & PU_Clear
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd64;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b1;
        PU_CLR = 1'b1;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end
    4'd3:begin // PU start & buffer read
        BUF_RD = 1'b0;
        PU_START = 1'b1;
        ACC_NUM = 7'd64;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b1;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end
    4'd4:begin // Calculation layer3
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd64;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b1;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end
    4'd5:begin //buffer writing & PU_Clear
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd64;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b1;
        PU_CLR = 1'b1;
        PU_SEL1 = 2'd2;
        PU_SEL2 = 2'd2;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd1;
        LAYER2_DONE= 1'b0;
    end
    4'd6:begin //PU start & buffer read
        BUF_RD = 1'b0;
        PU_START = 1'b1;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b1;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd2;
        PU_SEL2 = 2'd2;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd1;
        LAYER2_DONE= 1'b0;
    end
    4'd7:begin // Calculation layer4
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b1;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b1;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd2;
        PU_SEL2 = 2'd2;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd1;
        LAYER2_DONE= 1'b0;
    end
    4'd8:begin // buffer writing & PU clear
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b1;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b1;
        PU_CLR = 1'b1;
        PU_SEL1 = 2'd2;
        PU_SEL2 = 2'd2;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd2;
        LAYER2_DONE= 1'b0;
    end
    4'd9:begin //PU start & buffer read
        BUF_RD = 1'b0;
        PU_START = 1'b1;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b1;
        BUF_32_RD = 1'b1;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd2;
        LAYER2_DONE= 1'b0;
    end
    4'd10:begin //Calculation layer5
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b1;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b1;
        COEFF_SEL = 2'd2;
        LAYER2_DONE= 1'b0;
    end
    4'd11:begin // buffer writing & PU clear
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b1;
        PU_CLR = 1'b1;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b0;
        COEFF_SEL = 2'd2;
        LAYER2_DONE= 1'b0;
    end
    4'd12:begin // Layer2 done 
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd32;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd1;
        PU_SEL2 = 2'd1;
        PU_PREVENT_CLR=1'b0;
        COEFF_SEL = 2'd2;
        LAYER2_DONE= 1'b1;
    end
    default:begin
        BUF_RD = 1'b0;
        PU_START = 1'b0;
        ACC_NUM = 7'd0;
        BUF_32_IN_SEL = 1'b0;
        BUF_32_RD = 1'b0;
        BUF_32_RD2 = 1'b0;
        BUF_32_WR = 1'b0;
        PU_CLR = 1'b0;
        PU_SEL1 = 2'd0;
        PU_SEL2 = 2'd0;
        PU_PREVENT_CLR=1'b0;
        COEFF_SEL = 2'd0;
        LAYER2_DONE= 1'b0;
    end


    endcase
end
    
endmodule

module Layer_part2_buffer_32bit_port(
    input CLK,
    input BUF_RD,
    input BUF_RD2,
    input BUF_WR,
    input [64*32-1:0] BUF_IN_DATA,
    output [31:0] BUF_OUT_DATA1,
    output [31:0] BUF_OUT_DATA2
);

    integer i;
    reg [31:0] buffer [63:0];

    assign BUF_OUT_DATA1 = buffer[0];
    assign BUF_OUT_DATA2 = buffer[1];
    
    always @(posedge CLK) begin
        if(BUF_WR) begin
            for (i = 0; i < 64; i = i + 1) begin
                buffer[i] <= BUF_IN_DATA[32*i +: 32];
            end
        end
        else if(BUF_RD2) begin
            for (i = 0; i < 62; i = i + 1) begin
                buffer[i] <= buffer[i+2];
            end
            buffer[62] <= 32'b0; // ?ï¿½ï¿½?? ?ï¿½ï¿½ ?ï¿½ï¿½ì¹˜ëŠ” 0?ï¿½ï¿½ï¿??????? ì±„ìš°ï¿???????
            buffer[63] <= 32'b0;
        end
        else if(BUF_RD) begin
            for (i = 0; i < 63; i = i + 1) begin
                buffer[i] <= buffer[i+1];
            end
            buffer[63] <= 32'b0; // ë§ˆï¿½?ï¿??????? ?ï¿½ï¿½ì¹˜ëŠ” 0?ï¿½ï¿½ï¿??????? ì±„ìš°ï¿???????
        end
    end
    
endmodule

module adder32(
    input       [1023:0] A,
    input       [1023:0] B,
    output reg  [1023:0] C
);

integer i;

always @(*) begin
    for (i = 0; i < 32; i = i + 1) begin
        C[32*i +: 32] = A[32*i +: 32] + B[32*i +: 32];
    end    
end
    
endmodule
