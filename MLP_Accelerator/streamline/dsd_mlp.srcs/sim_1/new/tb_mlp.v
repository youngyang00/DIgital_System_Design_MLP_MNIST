`timescale 1ns / 1ps
module tb_top_mlp;

    reg CLK;
    reg RSTN;
    reg START;
    wire DONE_INTR;
    wire DONE_LED;
    wire Y_BUF_EN;
    wire [31:0] Y_BUF_ADDR;
    wire [31:0] Y_BUF_DATA;

    top_mlp_sub uut (
        .CLK(CLK),
        .RSTN(RSTN),
        .START(START),
        .DONE_INTR(DONE_INTR),
        .DONE_LED(DONE_LED),
        .Y_BUF_EN(Y_BUF_EN),
        .Y_BUF_ADDR(Y_BUF_ADDR),
        .Y_BUF_DATA(Y_BUF_DATA)
    );


    always begin
        #5 CLK = ~CLK; 
    end


    initial begin
        // 초기 신호 설정
        CLK = 0;
        RSTN = 0;
        START = 0;


        #20;
        RSTN = 1;
        #10;
        
        START = 1;
        #10;
        START = 0;
        
        wait (DONE_LED == 1);


        // 시뮬레이션 종료
        #20;
        $finish;
    end

endmodule
