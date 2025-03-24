`timescale 1ns / 1ps

module edge_detect(
    input clk,
    input rst,
    input signal,
    output reg pos_edge,
    output reg neg_edge
);

    reg signal_prev;

    always @ (posedge clk or posedge rst) begin
        if (rst) signal_prev <= 0;
        else     signal_prev <= signal;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) pos_edge <= 1'b0;
        else     pos_edge <= ~signal_prev & signal;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst) neg_edge <= 1'b0;
        else     neg_edge <= signal_prev & ~signal;
    end
    
endmodule
