`timescale 1ns / 1ps

module uart_recv(
    input                   clk,   
    input                   rst,   
    input                   din,   // connect to usb_uart rx pin
    output reg              valid, // indicates data is valid （logic high (1)）, last one clock
    output reg [7:0]        data   
);

    localparam    IDLE =  3'b000;
    localparam    START = 3'b001;
    localparam    DATA = 3'b010;
    localparam    STOP = 3'b011;

    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [3:0] bit_index;
    localparam BAUD_DIVIDER = 10416 - 1;
    localparam BAUD_MID = 5208 - 1;
    reg cnt_inc;
    reg [31:0] baud_cnt;
    wire cnt_end = (baud_cnt == BAUD_DIVIDER);
    wire cnt_mid = (baud_cnt == BAUD_MID);

    // 第1个always块，描述状态迁移
    always @(posedge clk or posedge rst) begin
        if (rst) current_state <= IDLE;
        else     current_state <= next_state;
    end

    // 第2个always块，描述状态转移条件判断
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (~din) next_state = START;
                else      next_state = IDLE;
            end
            START: begin
                if (cnt_mid) next_state = DATA;
                else         next_state = START;
            end
            DATA: begin
                if (bit_index < 8) next_state = DATA; // 发送8位数据
                else               next_state = STOP; // 8位数据发送完后，进入STOP
            end
            STOP: begin
                if (cnt_mid) next_state = IDLE;
                else         next_state = STOP;
            end
            default: next_state = IDLE;
        endcase
    end

    // 第3个always块，描述输出逻辑（data）
    // data
    always @(posedge clk or posedge rst) begin
        if (rst) data <= 8'h00;
        else begin
            case (current_state)
                DATA: begin
                        if (cnt_mid) data <= {din, data[7:1]};
                        else         data <= data;
                    end
                default: data <= data;
            endcase
        end
    end

    // valid
    always @(posedge clk or posedge rst) begin
        if (rst) valid <= 0;
        else begin
            case (current_state)
                STOP: begin 
                    if (cnt_mid) valid <= 1;
                    else         valid <= 0;
                end
                default: valid <= 0;
            endcase
        end
    end

    // bit_index 更新
    always @(posedge clk or posedge rst) begin
        if (rst) bit_index <= 0; 
        else begin
            case (current_state)
                START: bit_index <= 0; 
                DATA: begin
                    if (bit_index < 8 && cnt_mid) bit_index <= bit_index + 1'b1; 
                    else                          bit_index <= bit_index; 
                end
                default: bit_index <= 0;
            endcase
        end
    end

    // 波特率计数器
    always @(posedge clk or posedge rst) begin
        if (rst)     cnt_inc <= 1'b0;
        else         cnt_inc <= 1'b1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst)                        baud_cnt <= 0;
        else if (current_state == IDLE) baud_cnt <= 0;
        else if (~cnt_end)              baud_cnt <= baud_cnt + 1'b1;
        else                            baud_cnt <= 0;
    end

endmodule