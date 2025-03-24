`timescale 1ns / 1ps

module led_display(
    input  clk,
    input  rst,
    input  [7:0] recv_data,
    input  recv_valid,
    output reg [7:0] EN,
    output reg [7:0] SEGS
    );

    reg [7:0] seg_data [7:0];
    reg [2:0] read;
    reg [7:0] data_flag;
    wire clk_out, out_edge, unvalid_edge;
    wire [7:0] SEGS_index [7:0];

    // 动态显示逻辑（2ms）
    freq_div #(100000 - 1) freq_div_inst(
        .clk(clk),
        .rst(rst),
        .clk_out(clk_out)
    );

    edge_detect edge_detect_led_clkout(
        .clk(clk),
        .rst(rst),
        .signal(clk_out),
        .pos_edge(out_edge),
        .neg_edge(unvalid_edge)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) EN <= 8'b11111110;
        else if(out_edge) EN <= {EN[6:0], EN[7]};
    end


    // 读取数据，如果 rst，全部清零；如果传进一个有效信号，所有数据左移一位，新数据存在最低位
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[0] <= 8'b0;
        else if (recv_valid)  seg_data[0] <= recv_data;
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[1] <= 8'b0;
        else if (recv_valid)  seg_data[1] <= seg_data[0];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[2] <= 8'b0;
        else if (recv_valid)  seg_data[2] <= seg_data[1];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[3] <= 8'b0;
        else if (recv_valid)  seg_data[3] <= seg_data[2];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[4] <= 8'b0;
        else if (recv_valid)  seg_data[4] <= seg_data[3];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[5] <= 8'b0;
        else if (recv_valid)  seg_data[5] <= seg_data[4];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[6] <= 8'b0;
        else if (recv_valid)  seg_data[6] <= seg_data[5];
    end
    always @(posedge clk or posedge rst) begin
        if (rst)              seg_data[7] <= 8'b0;
        else if (recv_valid)  seg_data[7] <= seg_data[6];
    end

    // 是否读够八个数据
    always @(posedge clk or posedge rst) begin
        if (rst)                         read <= 0;
        else if (recv_valid && read < 7) read <= read + 1'b1;
        else if (read == 7)              read <= read;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)             data_flag <= 8'b00000000;
        else if (recv_valid) begin
            case (read)
                0: data_flag <= 8'b00000001;
                1: data_flag <= 8'b00000011;
                2: data_flag <= 8'b00000111;
                3: data_flag <= 8'b00001111;
                4: data_flag <= 8'b00011111;
                5: data_flag <= 8'b00111111;
                6: data_flag <= 8'b01111111;
                7: data_flag <= 8'b11111111;
                default: data_flag <= 8'b0;
            endcase
        end
    end

    // 显示数据
    led_list led0(
        .num(seg_data[0]),
        .SEGS(SEGS_index[0])
    );
    led_list led1(
        .num(seg_data[1]),
        .SEGS(SEGS_index[1])
    );
    led_list led2(
        .num(seg_data[2]),
        .SEGS(SEGS_index[2])
    );
    led_list led3(
        .num(seg_data[3]),
        .SEGS(SEGS_index[3])
    );
    led_list led4(
        .num(seg_data[4]),
        .SEGS(SEGS_index[4])
    );
    led_list led5(
        .num(seg_data[5]),
        .SEGS(SEGS_index[5])
    );
    led_list led6(
        .num(seg_data[6]),
        .SEGS(SEGS_index[6])
    );
    led_list led7(
        .num(seg_data[7]),
        .SEGS(SEGS_index[7])
    );

    // 没读满八位时，没读到的位数不显示
    always @(posedge clk or posedge rst) begin
        if (rst) SEGS <= 8'b11111111;
        else begin
            case(EN)
                8'b11111110: if (data_flag[0]) SEGS <= SEGS_index[0];
                             else              SEGS <= 8'b11111111;
                8'b11111101: if (data_flag[1]) SEGS <= SEGS_index[1]; 
                             else              SEGS <= 8'b11111111;
                8'b11111011: if (data_flag[2]) SEGS <= SEGS_index[2];
                             else              SEGS <= 8'b11111111;
                8'b11110111: if (data_flag[3]) SEGS <= SEGS_index[3];
                             else              SEGS <= 8'b11111111;
                8'b11101111: if (data_flag[4]) SEGS <= SEGS_index[4];
                             else              SEGS <= 8'b11111111;
                8'b11011111: if (data_flag[5]) SEGS <= SEGS_index[5];
                             else              SEGS <= 8'b11111111;
                8'b10111111: if (data_flag[6]) SEGS <= SEGS_index[6];
                             else              SEGS <= 8'b11111111;
                8'b01111111: if (data_flag[7]) SEGS <= SEGS_index[7];
                             else              SEGS <= 8'b11111111;
                default: SEGS <= 8'b11111111;
            endcase        
        end
    end

endmodule