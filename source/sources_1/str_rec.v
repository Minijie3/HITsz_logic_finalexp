`timescale 1ns / 1ps

module str_rec(
    input  clk,
    input  rst,
    input  recv_valid,
    input  [7:0] recv_data,
    output is_start,
    output is_stop,
    output other
    );

    localparam [3:0] IDLE = 4'b0000;
    localparam [3:0] S    = 4'b0001;
    localparam [3:0] T1   = 4'b0010;
    localparam [3:0] A    = 4'b0011;
    localparam [3:0] R    = 4'b0100;
    localparam [3:0] T2   = 4'b0101;
    localparam [3:0] O    = 4'b0110;
    localparam [3:0] P    = 4'b0111;
    localparam [3:0] OVER = 4'b1000;

    reg [1:0]  rec_result;
    reg [3:0]  current_state;
    reg [3:0]  next_state;
    reg [31:0] flag;
    wire o,r;

    always @(posedge clk or posedge rst) begin
        if (rst) current_state <= IDLE;
        else     current_state <= next_state;
    end

    // 各状态下只有接收到特定字符才能进入到下一状态，只要接收到的字符不对立马 OVER
    always @(posedge clk or posedge rst) begin
        if (rst) next_state <= IDLE;
        else begin case (current_state)
                IDLE: begin
                    if (recv_valid)
                        if (recv_data == 115) next_state <= S;
                        else                  next_state <= OVER; 
                    else next_state <= next_state;
                end
                S: begin
                    if (recv_valid)
                        if (recv_data == 116) next_state <= T1;
                        else                  next_state <= OVER; 
                    else next_state <= next_state;
                end
                T1: begin
                    if (recv_valid)
                        if (recv_data == 97)       next_state <= A;
                        else if (recv_data == 111) next_state <= O;
                        else                       next_state <= OVER;
                    else next_state <= next_state;
                end
                A: begin
                    if (recv_valid)
                        if (recv_data == 114) next_state <= R;
                        else                  next_state <= OVER;
                    else next_state <= next_state;
                end
                R: begin
                    if (recv_valid)
                        if (recv_data == 116) next_state <= T2;
                        else                  next_state <= OVER;
                    else next_state <= next_state;
                end
                T2: begin
                    if (recv_valid) next_state <= OVER;
                    else            next_state <= next_state;
                end
                O: begin
                    if (recv_valid)
                        if (recv_data == 112) next_state <= P;
                        else                  next_state <= OVER;
                    else next_state <= next_state;
                end
                P: begin
                    if (recv_valid) next_state <= OVER;
                    else            next_state <= next_state;
                end
                OVER: next_state <= IDLE;
                default: ;
            endcase
        end
    end


    always @(posedge clk or posedge rst) begin
        if (rst)                    rec_result <= 3;
        else if (~recv_valid)       rec_result <= 3;
        else begin case (current_state) // recv_valid = 1
                T2: begin
                    if (flag == 1)  rec_result <= 1;
                    else            rec_result <= 3;
                end
                P: begin
                    if (flag == 1)  rec_result <= 2;
                    else            rec_result <= 3;
                end
                default: begin
                    if (recv_data == 13) begin
                        if (flag)   rec_result <= 3;
                        else        rec_result <= 0;
                    end
                    else            rec_result <= 3;
                end
            endcase
        end
    end

    assign {o,r} = {current_state == O && recv_data == 112, current_state == R && recv_data == 116};

    always @(posedge clk or posedge rst) begin
        if (rst)                                flag <= 0; 
        else if (recv_valid && recv_data == 13) flag <= 0;
        else if (recv_valid && (o || r))        flag <= flag + 1;
        else                                    flag <= flag;
    end

    // 三个识别信号的高电平只会持续一个周期，适合与 send 模块中的 valid 作与运算来做真正的 valid.
    assign is_start = (rec_result == 1);
    assign is_stop  = (rec_result == 2);
    assign other    = (rec_result == 0);

endmodule