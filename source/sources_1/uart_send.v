module uart_send (
    input        clk,        // 系统时钟
    input        rst,        // 复位信号
    input        valid,      // 数据有效信号
    input [7:0]  data,
    input        recv_valid,
    input [7:0]  recv_data,
    output reg   dout        // 连接到USB-UART的TX引脚
);

localparam IDLE  = 2'b00; // 空闲态，发送高电平
localparam START = 2'b01; // 起始态，发送起始位
localparam DATA  = 2'b10; // 数据态，发送8位数据位
localparam STOP  = 2'b11; // 停止态，发送停止位

reg [1:0] current_state;  // 当前状态
reg [1:0] next_state;     // 下一个状态
reg [3:0] bit_index;      // 数据位的索引
reg [7:0] shift_data;     // 要发送的数据，通过移位发送
localparam BAUD_DIVIDER = 10416 - 1;
reg cnt_inc;
reg [31:0] baud_cnt;
wire cnt_end = (baud_cnt == BAUD_DIVIDER);
wire is_start, is_stop, other;
wire imp_valid;

str_rec str_rec_inst(
    .clk(clk),
    .rst(rst),
    .recv_valid(recv_valid),
    .recv_data(recv_data),
    .is_start(is_start),
    .is_stop(is_stop),
    .other(other)
);

assign imp_valid = (is_start | is_stop | other | valid);

// 第1个always块，描述状态迁移
always @(posedge clk or posedge rst) begin
    if (rst) current_state <= IDLE;
    else     current_state <= next_state;
end

// 第2个always块，描述状态转移条件判断
always @(*) begin
    case (current_state)
        IDLE: begin
            if (imp_valid) next_state = START;
            else next_state = IDLE;
        end
        START: begin
            if (cnt_end) next_state = DATA;
            else         next_state = START;
        end
        DATA: begin
            if (bit_index < 8) next_state = DATA; // 发送8位数据
            else               next_state = STOP; // 8位数据发送完后，进入STOP
        end
        STOP: begin
            if (cnt_end) next_state = IDLE;
            else         next_state = STOP;
        end
        default: next_state = IDLE;
    endcase
end

// 第3个always块，描述输出逻辑（dout）
always @(posedge clk or posedge rst) begin
    if (rst) dout <= 1'b1; // 复位时，dout保持高电平
    else begin
        case (current_state)
            IDLE: dout <= 1'b1;
            START: dout <= 1'b0;
            DATA: dout <= shift_data[0];
            STOP: dout <= 1'b1;
            default: dout <= 1'b1; // 默认状态
        endcase
    end
end

// 数据移位逻辑和位索引更新
always @(posedge clk or posedge rst) begin
    if (rst) bit_index <= 0; // 复位时位索引清零
    else begin
        case (current_state)
            START: bit_index <= 0; // 初始化位索引
            DATA: begin
                if (bit_index < 8 && cnt_end) bit_index <= bit_index + 1; // 更新位索引
                else bit_index <= bit_index; // 保持原值
            end
            default: ;
        endcase
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) shift_data <= 0; // 复位时，数据清零
    else begin
        case (current_state)
            IDLE: begin
                if (valid)         shift_data <= data; // 按下s3，发送传进来的 data
                else if (is_start) shift_data <= 8'b00110001;   // 检测到 ‘start’，发送字符1
                else if (is_stop)  shift_data <= 8'b00110010;   // 检测到 ‘stop’，发送字符2
                else if (other)    shift_data <= 8'b00110000;   // 检测到其它字符，发送字符0
                else               shift_data <= shift_data;
            end
            DATA: begin
                if (bit_index < 7 && cnt_end) shift_data <= {1'b0, shift_data[7:1]}; // 移一位，准备发送下一个数据位，bit_index = 7 时不移
                else shift_data <= shift_data;
            end
            default: ;
        endcase
    end
end

// 波特率计数器
always @(posedge clk or posedge rst) begin
    if (rst)     cnt_inc <= 1'b0;
    else         cnt_inc <= 1'b1;
end

always @(posedge clk or posedge rst) begin
    if (rst)            baud_cnt <= 0;
    else if (imp_valid) baud_cnt <= 0;
    else if (~cnt_end)  baud_cnt <= baud_cnt + 1'b1;
    else                baud_cnt <= 0;
end

endmodule