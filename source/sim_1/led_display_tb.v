`timescale 1ns / 1ps

module led_display_tb();

reg clk, rst, recv_valid;
reg [7:0] recv_data;
wire [7:0] EN;
wire [7:0] SEGS;


led_display led_display_test(
    .clk(clk),
    .rst(rst),
    .recv_data(recv_data),
    .recv_valid(recv_valid),
    .EN(EN),
    .SEGS(SEGS)
);

always @ * begin
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    clk = 0; rst = 1; recv_valid = 0; recv_data = 8'b00000000;
    #10 rst = 0; recv_valid = 1; recv_data = 49; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 50; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 51; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 52; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 53; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 54; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 55; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 56; #10 recv_valid = 0;
    #1000000 recv_valid = 1; recv_data = 57; #10 recv_valid = 0;
    #1000000000 $finish;
end
endmodule
