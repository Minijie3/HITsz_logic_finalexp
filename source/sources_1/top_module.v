`timescale 1ns / 1ps

module top_module(
    input  clk,
    input  rst,
    input  button_s3,
    input  [7:0] data,
    input  din,
    output [7:0] SEGS,
    output [7:0] EN,
    output dout
    );

    wire deb_s3, s3_pos_edge, s3_neg_edge;
    wire recv_valid;
    wire [7:0] recv_data;

    // S3消抖
    button_debounce button_debounce_s3(
        .clk(clk),
        .rst(rst),
        .button(button_s3),
        .button_valid(deb_s3)
    );

    // S3上升沿检测做send的valid
    edge_detect edge_detect_s3(
        .clk(clk),
        .rst(rst),
        .signal(deb_s3),
        .pos_edge(s3_pos_edge),
        .neg_edge(s3_neg_edge)
    );

    // receive
    uart_recv uart_recv_inst(
        .clk(clk),
        .rst(rst),
        .din(din),
        .valid(recv_valid),
        .data(recv_data)
    );

    // send，与字符串识别在一起
    // s3_pos_edge 只会有一个周期，用作发送 data 的使能
    uart_send uart_send_inst(
        .clk(clk),
        .rst(rst),
        .valid(s3_pos_edge),
        .data(data),
        .recv_valid(recv_valid),
        .recv_data(recv_data),
        .dout(dout)
    );

    // receive 得到的数据和 valid 给到 led_display 模块
    led_display led_display_inst(
        .clk(clk),
        .rst(rst),
        .recv_data(recv_data),
        .recv_valid(recv_valid),
        .EN(EN),
        .SEGS(SEGS)
    );
endmodule