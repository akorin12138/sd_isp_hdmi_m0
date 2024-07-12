module Keyboard(
        input  wire          HCLK,
        input  wire          HRESETn,
        input  wire  [3:0]   key_col,    //键盘列
        output reg   [3:0]   key_row,    //键盘行
        output reg   [3:0]   key_val,
        output wire          key_it
    );

    //++++++++++++++++++++++++++++++++++++++
    // 分频部分 开始
    //++++++++++++++++++++++++++++++++++++++
    reg [19:0] cnt;                         // 去抖动计数器

    always @ (posedge HCLK, negedge HRESETn)
        if (!HRESETn)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;

    wire key_clk = cnt[19];                 //T =(2^20/50M = 20.97152)ms
    //--------------------------------------
    // 分频部分 结束
    //--------------------------------------


    //++++++++++++++++++++++++++++++++++++++
    // 状态机部分 开始
    //++++++++++++++++++++++++++++++++++++++
    // 状态数较少，独热码编码
    parameter NO_KEY_PRESSED = 6'b000_001;  // 没有按键按下
    parameter SCAN_COL0      = 6'b000_010;  // 扫描第0列
    parameter SCAN_COL1      = 6'b000_100;  // 扫描第1列
    parameter SCAN_COL2      = 6'b001_000;  // 扫描第2列
    parameter SCAN_COL3      = 6'b010_000;  // 扫描第3列
    parameter KEY_PRESSED    = 6'b100_000;  // 有按键按下

    reg [5:0] current_state, next_state;    // 现态、次态
    reg [3:0] key_col_val;
    always @ (posedge key_clk, negedge HRESETn)
        if (!HRESETn)
            current_state <= NO_KEY_PRESSED;
        else
            current_state <= next_state;

    always @ (posedge key_clk, negedge HRESETn)
        if (!HRESETn)
            current_state <= NO_KEY_PRESSED;
        else
            current_state <= next_state;

    // 根据条件转移状态
    always @(*)
    case (current_state)
        NO_KEY_PRESSED :                    // 没有按键按下
            if (key_col != 4'hF)
                next_state = SCAN_COL0;
            else
                next_state = NO_KEY_PRESSED;
        SCAN_COL0 :                         // 扫描第0列
            if (key_col != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL1;
        SCAN_COL1 :                         // 扫描第1列
            if (key_col != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL2;
        SCAN_COL2 :                         // 扫描第2列
            if (key_col != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = SCAN_COL3;
        SCAN_COL3 :                         // 扫描第3列
            if (key_col != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = NO_KEY_PRESSED;
        KEY_PRESSED :                       // 有按键按下
            if (key_col != 4'hF)
                next_state = KEY_PRESSED;
            else
                next_state = NO_KEY_PRESSED;
    endcase

    reg       key_pressed_flag;             // 键盘按下标志
    reg       key_pressed_flag_r;             // 键盘按下标志
    reg [3:0] col_val, row_val;             // 列值、行值

    // 根据次态，给相应寄存器赋值
    always @ (posedge key_clk, negedge HRESETn)
        if (!HRESETn) begin
            key_row              <= 4'h0;
            key_pressed_flag <=    0;
        end
        else
        case (next_state)
            NO_KEY_PRESSED :                  // 没有按键按下
            begin
                key_row              <= 4'h0;
                key_pressed_flag <=    0;       // 清键盘按下标志
            end
            SCAN_COL0 :                       // 扫描第0列
                key_row <= 4'b1110;
            SCAN_COL1 :                       // 扫描第1列
                key_row <= 4'b1101;
            SCAN_COL2 :                       // 扫描第2列
                key_row <= 4'b1011;
            SCAN_COL3 :                       // 扫描第3列
                key_row <= 4'b0111;
            KEY_PRESSED :                     // 有按键按下
            begin
                col_val          <= key_col;        // 锁存列值
                row_val          <= key_row;        // 锁存行值
                key_pressed_flag <= 1;          // 置键盘按下标志
            end
        endcase
    //--------------------------------------
    // 状态机部分 结束
    //--------------------------------------
    always @ (posedge HCLK, negedge HRESETn)
        if(~HRESETn)
            key_pressed_flag_r <= 1'b0;
        else
            key_pressed_flag_r <= key_pressed_flag;
    //++++++++++++++++++++++++++++++++++++++
    // 扫描行列值部分 开始
    //++++++++++++++++++++++++++++++++++++++
    always @ (posedge HCLK, negedge HRESETn)
        if (!HRESETn)
            key_val <= 4'h0;
        else
            if (key_pressed_flag)
            case ({col_val, row_val})
                8'b1110_1110 :
                    key_val <= 4'h0;
                8'b1110_1101 :
                    key_val <= 4'h4;
                8'b1110_1011 :
                    key_val <= 4'h8;
                8'b1110_0111 :
                    key_val <= 4'hC;

                8'b1101_1110 :
                    key_val <= 4'h1;
                8'b1101_1101 :
                    key_val <= 4'h5;
                8'b1101_1011 :
                    key_val <= 4'h9;
                8'b1101_0111 :
                    key_val <= 4'hD;

                8'b1011_1110 :
                    key_val <= 4'h2;
                8'b1011_1101 :
                    key_val <= 4'h6;
                8'b1011_1011 :
                    key_val <= 4'hA;
                8'b1011_0111 :
                    key_val <= 4'hE;

                8'b0111_1110 :
                    key_val <= 4'h3;
                8'b0111_1101 :
                    key_val <= 4'h7;
                8'b0111_1011 :
                    key_val <= 4'hB;
                8'b0111_0111 :
                    key_val <= 4'hF;
            endcase
    assign key_it = ~key_pressed_flag_r&key_pressed_flag;//按下标志的上升沿作为中断
endmodule //Keyboard

