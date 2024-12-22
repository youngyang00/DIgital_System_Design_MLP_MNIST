module MLP_Controller(
    input                               CLK,
    input                               RSTN,
    input                               START,
    input                               LAYER_PART1_DONE,
    input                               LAYER2_DONE,

    output reg                          BUF_32_RD,
    output reg [$clog2(8192)-1:0]       IMG_ADDR,
    output reg                          IMG_RD_EN,
    output reg                          LAYER_PART1_START,
    output reg                          LAYER_PART2_START,
    output reg                          LAYER_PART2_CLR,
    output reg                          Y_BUF_EN,
    output reg [31:0]                   Y_BUF_ADDR,
    output reg                          DONE_LED,
    output reg                          DONE_INTR
);

wire n_rst = ~RSTN;

reg [2:0]   current_state,next_state;
reg [9:0]   addr_cnt;
reg [3:0]   buf_cnt;
reg         addr_cnt_en;

always @(posedge CLK) begin
    if(n_rst)begin
        buf_cnt <= 4'd0;
        BUF_32_RD <= 1'b0;
        LAYER_PART2_CLR <=1'b0;
        Y_BUF_EN <= 1'b0;
        Y_BUF_ADDR <= 32'b0;
    end 
    else begin
        if(LAYER2_DONE)begin
            if(buf_cnt < 10) begin
                buf_cnt <= buf_cnt + 1;
                BUF_32_RD <= 1'b1;
                LAYER_PART2_CLR <=1'b0;
                Y_BUF_EN<= 1'b1;
                if(buf_cnt > 0)Y_BUF_ADDR <= Y_BUF_ADDR + 3'd4;
            end
            else begin
                LAYER_PART2_CLR <=1'b1;
                BUF_32_RD <= 1'b0;
                Y_BUF_EN <= 1'b0;
            end
        end
        else begin
            if((buf_cnt==10) && (LAYER_PART2_CLR==1)) Y_BUF_ADDR <= Y_BUF_ADDR + 3'd4;
            buf_cnt <= 4'd0;
            LAYER_PART2_CLR <=1'b0; 
            BUF_32_RD <= 1'b0;
            Y_BUF_EN <= 1'b0;
        end
    end
end

always @(posedge CLK) begin
    if(n_rst) begin
        IMG_ADDR <= {$clog2(8192){1'b0}};    
        addr_cnt <= {10{1'b0}};
    end
    else begin
        if(addr_cnt_en)begin
            IMG_ADDR <= IMG_ADDR + 1'b1;
            if(addr_cnt < 783) addr_cnt <= addr_cnt + 1'b1;
            else addr_cnt <= 10'd0; 
        end
    end
end

always @(posedge CLK) begin
    if(n_rst) current_state <= 3'd0;
    else current_state <= next_state;
end

always @(*) begin
    case (current_state)
    3'd0: if(START) next_state = 3'd1; else next_state = 3'd0;
    3'd1:begin
            if(addr_cnt==10'd783) next_state = 3'd2;
            else if(Y_BUF_ADDR == 32'd400) next_state = 3'd4;
            else next_state =3'd1;
         end
    3'd2: if(LAYER_PART1_DONE) next_state = 3'd3; else next_state = 3'd2;
    3'd3: next_state = 3'd1;
    3'd4: next_state = 3'd4;
    endcase
end

always @(*) begin
    case (current_state)
    3'd0: begin
        IMG_RD_EN = 1'b0;
        addr_cnt_en = 1'b0;
        LAYER_PART1_START = 1'b0;
        LAYER_PART2_START = 1'b0;
        DONE_LED = 1'b0;
        DONE_INTR = 1'b0;
    end
    3'd1:begin
        IMG_RD_EN = 1'b1;
        addr_cnt_en = 1'b1;
        LAYER_PART1_START = 1'b1;
        LAYER_PART2_START = 1'b0;
        DONE_LED = 1'b0;
        DONE_INTR = 1'b0;
    end
    3'd2:begin
        IMG_RD_EN = 1'b0;
        addr_cnt_en = 1'b0;
        LAYER_PART1_START = 1'b0;    
        LAYER_PART2_START = 1'b0;    
        DONE_LED = 1'b0;
        DONE_INTR = 1'b0;
    end
    3'd3:begin
        IMG_RD_EN = 1'b0;
        addr_cnt_en = 1'b0;
        LAYER_PART1_START = 1'b0;    
        LAYER_PART2_START = 1'b1;   
        DONE_LED = 1'b0;
        DONE_INTR = 1'b0;
    end
    3'd4:begin
        IMG_RD_EN = 1'b0;
        addr_cnt_en = 1'b0;
        LAYER_PART1_START = 1'b0;    
        LAYER_PART2_START = 1'b0;   
        DONE_LED = 1'b1;
        DONE_INTR = 1'b1;
    end
    endcase
end

    
endmodule