`timescale 1ns / 1ps

module freq_div #(
    parameter freq_num = 100000 - 1
)(
    input clk,
    input rst,
    output reg clk_out
);

    reg [31:0] cnt;
    reg cnt_inc;
    wire cnt_end = (cnt == freq_num);

    always @ (posedge clk or posedge rst) begin
        if(rst)  cnt_inc <= 1'b0;     
        else  cnt_inc <= 1'b1;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)          cnt <= 0;
        else if (cnt_end) cnt <= 0;
        else if (cnt_inc) cnt <= cnt + 1;
    end

    always @ (posedge clk or posedge rst) begin
        if (rst)          clk_out <= 1'b0;
        else if (cnt_end) clk_out <= ~clk_out;
    end
endmodule