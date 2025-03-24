`timescale 1ns / 1ps

module button_debounce(          
   input clk,
   input rst,  
   input button,
   output reg  button_valid
);

    localparam IDLE = 0;
    localparam POS_DEBOUNCE = 1;
    localparam WAIT = 2;
    localparam NEG_DEBOUNCE = 3;
    localparam OVER = 5;
    parameter DELAY = 1500000 - 1; // 15ms
    reg [32:0]button_cnt;
    reg [2:0]next_state, current_state;
    wire pos_edge, neg_edge;

    edge_detect edge_detect_debounce(
        .clk(clk),
        .rst(rst),
        .signal(button),
        .pos_edge(pos_edge),
        .neg_edge(neg_edge)
    );

    // 状态机消抖
    always @(posedge clk or negedge rst) begin
        if (rst) current_state <= 0;
        else     current_state <= next_state;
    end

    always @(posedge clk or negedge rst) begin
        if (rst)
            next_state <= 0;
        else
            case (next_state)
                IDLE:         if (pos_edge)            next_state <= POS_DEBOUNCE;
                              else                     next_state <= IDLE;
                POS_DEBOUNCE: if (button_cnt == DELAY) next_state <= WAIT;
                              else                     next_state <= POS_DEBOUNCE;
                WAIT:         if (neg_edge)            next_state <= NEG_DEBOUNCE;
                              else                     next_state <= WAIT;
                NEG_DEBOUNCE: if (button_cnt == DELAY) next_state <= OVER;
                              else                     next_state <= NEG_DEBOUNCE;
                OVER:                                  next_state <= IDLE;
                default: next_state <= 0;
            endcase
    end

    always @(posedge clk or negedge rst) begin
        if (rst)   button_valid <= 0;
        else
            case (current_state)
                WAIT:           button_valid <= 1;
                NEG_DEBOUNCE:   button_valid <= 0;
                default:        button_valid <= button_valid;
            endcase
    end

    // button_cnt 赋值
    always @(posedge clk or negedge rst) begin
        if (rst)                           button_cnt <= 0;
        else
            case (next_state)
                POS_DEBOUNCE: if (button_cnt < DELAY) button_cnt <= button_cnt + 1;
                NEG_DEBOUNCE: if (button_cnt < DELAY) button_cnt <= button_cnt + 1;
                default:                              button_cnt <= 0;
            endcase
    end

endmodule