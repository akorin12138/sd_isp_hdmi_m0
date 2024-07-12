`timescale 1ps/1ps
module sdram_init (
	input 					sys_clk		,    	//	系统时钟   167MHZ,period = 5.98ns
	input 					sys_rst_n	,  		// 	系统复位信号	
	output	reg	[3:0]		init_cmd	,		//	初始化命令 cs_n ras_n cas_n we_n
	output 	reg [12:0]		init_addr	,		//	初始化地址总线
	output  reg [1:0] 		init_ba		,		//  初始化bank地址
	output  reg  			init_end			//  初始化结束标志
	
);

//parameter  define
//sdram命令
localparam  	NOP 	= 	 4'b0111		,		//空操作命令
				PRE  	= 	 4'b0010		,		//预充电命令，用于关闭当前的行
				AREF 	=	 4'b0001		,		//自动刷新命令，用于维持当前数据
				LMR 	= 	 4'b0000		,		//设置模式寄存器命令，初始化阶段需要配置模式寄存器， 设置突发类型、突发长度、读写方式、列选通潜伏期
				ACT 	=	 4'b0011		,		//激活命令，用于打开行，和行地址一起发送
				RD		=	 4'b0101		,		//读命令，发送读或写命令前必须激活
				WR 		=	 4'b0100		,		//写命令，写命令和列地址一起发出，存在列选通潜伏期，就是写命令发出到数据出现在总线上的需要等待的时间，一般设为2或3
				BR_T	=	 4'b0110		;		//突发终止命令

//计数器
 localparam		cnt_pow		=		'd33445	,	 	//200MHZ				'd40000		,		//200us
 				cnt_rp 		=		'd4 	, 		//200MHZ				'd4			,		//20ns
 				cnt_rfc 	=		'd12	, 		//200MHZ				'd14		,		//70ns
 				cnt_mrd 	=		'd6 	;		//200MHZ				'd6			;		//30ns

//状态机 初始化过程的8个状态，格雷码定义，相邻两位只有一位发生变化，避免产生亚稳态
localparam 		INIT_IDLE	=	3'b000		,		//初始状态
				INIT_PRE 	=	3'b001		,		//预充电状态
				INIT_TRP 	=	3'b011		,		//预充电等待状态 trp	
				INIT_AREF 	=	3'b010		,		//自动刷新状态		
				INIT_TRFC 	=	3'b110		,		//自动刷新等待状态	trfc	
				INIT_LMR 	=	3'b111		,		//模式寄存器设置状态	
				INIT_TMRD 	=	3'b101		,		//模式寄存器设置等待状态	tmrd
				INIT_END 	=	3'b100		;		//初始化结束状态	
//刷新次数，适配不同器件，至少刷新2次
localparam				aref_num  =     6;

//地址辅助模式寄存器，参数不同，配置的模式不同
localparam 		init_lmrset = {	3'b000		,		//A12-A10: 预留的模式寄存器
								1'b0		,		//A9     : 读写方式，0:突发读&突发写，1:突发读&单写
								2'b00		,		//{A8，A7}: 标准模式，默认
								3'b011		,		//{A6，A5，A4} CAS潜伏期； 010: 2  011: 3 ,其他:保留
								1'b0		,		//A3   突发传输方式； 0:顺序， 1: 隔行
								3'b111				//{A2,A1,A0}=111:突发长度,000:单字节,001:2字节
													//010:4字节,011:8字节,111:整页,其他:保留
							  };
//reg define

reg 	[15:0]	cnt_200us			;			//启动计数器

//状态机相关  三段式
reg		[2:0]	init_state_cs		;			//初始化状态机  当前状态
reg		[2:0]	init_state_ns		;			//初始化状态机  下一个状态

reg				pow_end			;			//上电结束标志
reg				pre_end			;			//预充电结束标志
reg				aref_end		;			//刷新结束标志
reg				mrd_end			;			//模式寄存器设置结束标志

reg 	[3:0]	cnt_clk			;			//各状态记录时间
//reg 			cnt_clk_rst_n	;			//时钟周期复位信号 取消这个标志信号，直接判断是否复位

reg 	[3:0]	cnt_init_aref	;			//初始阶段刷新次数


//上电检测：SDRAM上电后计时200us
always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
		 cnt_200us	<= 0;
		 pow_end	<= 0;
	end 
	else if(cnt_200us == cnt_pow) begin
		 cnt_200us	<= 	0 	;
		 pow_end	<=	1 	;
	end
	else	begin
		cnt_200us	<=	cnt_200us + 1'b1	;
		pow_end		<=	0 					;
	end
end

//cnt_clk:时钟周期计数，记录初始化各状态的等待时间
always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
		cnt_clk <= 0 	;
	end 
	else if(pow_end == 1 || pre_end == 1 || aref_end == 1 ) begin
		 cnt_clk <=	0  	;
	end
	else
		cnt_clk 	<=	cnt_clk + 1;
end


//cnt_init_aref:初始化阶段的刷新次数
always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
		 cnt_init_aref 		<= 	0 	;
	end 
	else if(init_state_cs == INIT_IDLE) begin		//这里为什么设置两次清零
		 cnt_init_aref 		<= 	0 	;
	end
	else if (init_state_cs == INIT_AREF) begin
		cnt_init_aref		<=	cnt_init_aref	+ 1'b1	;
	end
	else
		cnt_init_aref 		<=	cnt_init_aref			;
end

//预充电结束标志
//pre_end
always@(*)	begin
	if(init_state_cs == INIT_TRP && cnt_clk == cnt_rp)
				pre_end 		= 			1 	;
	else
				pre_end			=			0 	;
end

//刷新结束标志
//aref_end
always@(*)	begin
	if(init_state_cs == INIT_TRFC && cnt_clk == cnt_rfc)
				aref_end 		= 			1 	;
	else
				aref_end			=			0 	;
end


//模式寄存器结束标志
//mrd_end
always@(*)	begin
	if(init_state_cs == INIT_TMRD && cnt_clk == cnt_mrd)
				mrd_end	 	 		= 			1 	;
	else
				mrd_end				=			0 	;
end

//初始化状态机 三段式
//同步时序描述状态转移
always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
		 init_state_cs <= INIT_IDLE;
	end 
	else begin
		 init_state_cs <= init_state_ns ;
	end
end


//组合逻辑描述状态转移条件
always@(*) begin
	case(init_state_cs)
		INIT_IDLE	:
						if(pow_end == 1)
							init_state_ns	=	INIT_PRE	;
						else
							init_state_ns	=	INIT_IDLE	;

		INIT_PRE	:
							init_state_ns	=	INIT_TRP	;
							
		INIT_TRP	:
						if(pre_end == 1)
							init_state_ns	=	INIT_AREF	;
						else
							init_state_ns	=	INIT_TRP	;

		INIT_AREF:  	 	init_state_ns 	= 	INIT_TRFC	; 

		INIT_TRFC	://自动刷新等待状态，等待结束，自动跳转到模式寄存器，记录刷新次数
						if(aref_end == 1)	//	刷新结束，需要判断刷新次数
							if(cnt_init_aref == aref_num)
							 		init_state_ns	=	INIT_LMR	;
							else
									init_state_ns   = 	INIT_AREF 	;
						else
							init_state_ns	=	INIT_TRFC	;

		INIT_LMR 	: 		init_state_ns	=	INIT_TMRD 	;

		INIT_TMRD	:
						if(mrd_end == 1)
							init_state_ns	=	INIT_END	;
						else
							init_state_ns	=	INIT_TMRD	;
		INIT_END	:
							init_state_ns   =   INIT_IDLE	;
		default:
							init_state_ns 	= 	INIT_IDLE	;
	endcase // init_state_cs

end


//时序逻辑描述状态输出
always @(posedge sys_clk or negedge sys_rst_n) begin 
	if(~sys_rst_n) begin
				init_cmd	 <= NOP				;
			    init_ba		 <= 2'b11			;
			    init_addr 	 <= 13'h1fff		;
		 		init_end 	<= 1'b0 	;	
	end 
	else begin
		 case (init_state_cs)
		 	INIT_IDLE,INIT_TRP,INIT_TRFC,INIT_TMRD: begin
		 		 			init_cmd	 <= NOP				;
			     			init_ba		 <= 2'b11			;
			     			init_addr 	 <= 13'h1fff		;
		 	end
				
			INIT_PRE	: begin
						  	init_cmd	 <= PRE				;
			     			init_ba		 <= 2'b11			;
			     			init_addr 	 <= 13'h1fff		;
			end

			INIT_AREF 	:	begin
							init_cmd	 <= AREF			;
			     			init_ba		 <= 2'b11			;
			     			init_addr 	 <= 13'h1fff		;
			end			
							
			INIT_LMR	: 	begin
							init_cmd	 <= LMR				;
			     			init_ba		 <= 2'b00			;	//这里11和00有什么区别吗
			     			init_addr 	 <= init_lmrset		;
			end
			

			INIT_END	: begin
		 		 			init_cmd	 <= NOP				;
			     			init_ba		 <= 2'b11			;
			     			init_addr 	 <= 13'h1fff		;
			     			init_end	 <=	1'b1 			;
		 	end
		 	default : /* default */begin
		 					init_cmd	 <= NOP				;
			     			init_ba		 <= 2'b11			;
			     			init_addr 	 <= 13'h1fff		;
		 	end
		 endcase
	end
end




endmodule 

