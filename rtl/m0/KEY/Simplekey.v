module Simplekey#
    (
       parameter	CLK_FRQ			= 50_000_000,				    // 主晶振频率50MHz
	   parameter	DELAY_TIME		= 10						    // 消抖延时时间（单位：ms）
)(
    input wire  HCLK,
    input wire  HRESETn,
    input wire  key,
    output reg  key_output,
    output wire key_interrupt
);

	parameter	DELAY_CNT		= (CLK_FRQ*DELAY_TIME)/1000; 	// 消抖计数器溢出值
	
//
	// 按键消抖状态机（格雷码）
	localparam	KEY_IDLE		= 4'b0000;			// key IDLE
	localparam	KEY_DELAY_1		= 4'b0001;			// 按键下降沿延时
	localparam	KEY_DECIDE_1	= 4'b0011;			// 判决延时后I/O是否为低电平
	localparam	KEY_WAIT_POSE	= 4'b0010;			// 等待按键释放，即等待上升沿出现
	localparam	KEY_DELAY_2		= 4'b0110;			// 按键下降沿延时
	localparam	KEY_DECIDE_2	= 4'b0111;			// 判决延时后I/O是否为高电平
	localparam	KEY_FINISH		= 4'b0101;			// 消抖完毕，输出一个时钟周期的高电平
	
//
	reg[3:0]	state;				// 状态寄存器
	reg[23:0]	cnt;				// 消抖延时24位计数器
	reg			delay_en;			// 延时计数器使能
	reg			delay_done;			// 延时结束标志寄存器
	reg			ff_a;				// 同步寄存器A
	reg			ff_b;				// 同步寄存器B
	
	wire		key_pose;			// 按键上升沿：1为上升沿
	wire		key_nege;			// 按键下降沿：1为下降沿
	
//
	// 消抖延时定时器
	always@(posedge HCLK or negedge HRESETn)begin
		if(!HRESETn)begin
			cnt			<= 24'b0;
			delay_done  <= 1'b0;
		end
		else if(delay_en)begin
			if(cnt == DELAY_CNT)begin
				cnt			<= 24'b0;
				delay_done  <= 1'b1;
			end
			else begin
				cnt <= cnt + 24'b1;
				delay_done  <= 1'b0;
			end	
		end
		else begin
			cnt			<= 24'b0;
			delay_done  <= 1'b0;
		end
	end
	
	
	// 两拍跨时钟域同步寄存器
	always@(posedge HCLK or negedge HRESETn)begin
		if(!HRESETn)begin
			ff_a <= 1'b0;
			ff_b <= 1'b0;
		end
		else begin
			ff_a <= key;
			ff_b <= ff_a;
		end
	end
	
	
	// 按键边沿检测
	assign	key_nege  =  ff_b && (~ff_a);		// 高电平为下降沿
	assign	key_pose  =  ff_a && (~ff_b);		// 高电平为上升沿
	
//	
	// 按键消抖主状态机
	always@(posedge HCLK or negedge HRESETn)begin
		if(!HRESETn)begin
			state <= KEY_IDLE;								// 状态寄存器清零
			delay_en <= 1'b0;								// 定时器失能
			key_output <= 1'b0;								// 按键输出脉冲清零
		end
		else begin
			case(state)
				// key IDLE
				KEY_IDLE: begin
					if(key_nege)begin						// 按键出现下降沿跳转，使能定时器
						delay_en <= 1'b1;					// 定时器使能
						state	 <= KEY_DELAY_1;			// 跳转到 KEY_DELAY_1
					end
					else begin
						delay_en <= 1'b0;
						key_output <= 1'b0;					// 按键输出脉冲清零
						state <= KEY_IDLE;
					end	
				end
				
				// 消抖延时
				KEY_DELAY_1: begin
					if(delay_done)begin
						delay_en <= 1'b0;					// 延时结束失能定时器
						state	 <= KEY_DECIDE_1;			// 跳转到 KEY_DECIDE_1
					end
					else begin
						delay_en <= 1'b1;
						state	 <= KEY_DELAY_1;
					end
				end
				
				// 判断I/O是否为低电平
				KEY_DECIDE_1: begin
					if(~key)
						state	 <= KEY_WAIT_POSE;			// 跳转到 KEY_WAIT_POSE
					else
						state	 <= KEY_IDLE;
				end
				
				// 等待按键松开，出现上升沿
				KEY_WAIT_POSE: begin
					if(key_pose)begin						// 按键出现上升沿跳转，使能定时器
						delay_en <= 1'b1;					// 定时器使能
						state	 <= KEY_DELAY_2;			// 跳转到 KEY_DELAY_2
					end
					else begin
						delay_en <= 1'b0;
						state	 <= KEY_WAIT_POSE;
					end
				end
				
				// 消抖延时
				KEY_DELAY_2: begin
					if(delay_done)begin
						delay_en <= 1'b0;					// 延时结束失能定时器
						state	 <= KEY_DECIDE_2;			// 跳转到 KEY_DECIDE_2
					end
					else begin
						delay_en <= 1'b1;
						state	 <= KEY_DELAY_2;
					end
				end
				
				// 判断I/O是否为高电平
				KEY_DECIDE_2: begin
					if(key)
						state	 <= KEY_FINISH;			// 跳转到 KEY_FINISH
					else
						state	 <= KEY_IDLE;
				end
				
				// 消抖结束，输出脉冲
				KEY_FINISH: begin
					key_output	<= 1'b1;				// 按键已经按下，输出高电平脉冲
					state	 	<= KEY_IDLE;			// 跳转回 KEY_IDLE
					
				end	
			endcase		
		end
	end

    assign key_interrupt = key_nege;
endmodule //key

