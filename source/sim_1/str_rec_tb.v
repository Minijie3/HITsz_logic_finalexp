`timescale 1ns / 1ps

module str_rec_tb();

    reg  clk;
    reg  rst;
    reg  recv_valid;
    reg  [7:0] recv_data;
    wire is_start;
    wire is_stop;
    wire other;

    str_rec str_rec_test(
        .clk(clk),
        .rst(rst),
        .recv_valid(recv_valid),
        .recv_data(recv_data),
        .is_start(is_start),
        .is_stop(is_stop),
        .other(other)
    );

    always @ * begin
        forever begin
            #5 clk = ~clk;
        end
    end

    initial begin
        clk = 0; rst = 1; recv_valid = 0; recv_data = 8'b0;
        #10 rst = 0; recv_valid = 1; recv_data = 115; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 116; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 111; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 112; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 49; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 50; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 115; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 116; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 111; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 112; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 13; #10 recv_valid = 0;
        #100000 recv_valid = 1; recv_data = 10; #10 recv_valid = 0;
        #10 $finish;
    end
endmodule
