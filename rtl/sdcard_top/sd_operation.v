//Filename:sd_opeartion.v
//Creat:2011_9_13 11am
//Author:lichenlin
//Commit:sd card operation in read or write.
module	sd_operation(

    LED_TEST,
    
	sys_clk,
    clk_200m,
	
	init_repeat_req,
	
	read_req,
	sd_ram_blockaddress,
	sd_ram_data_size,
	
    outdata_done,
	outdata_en,
	outdata,
	outdata_num,
	
	write_req,
	
	read_ram_data,
	read_ram_en,
	read_ram_address,
	
	sd_idle_flag,
	
	sd_command,
	sd_data,
	sd_clk,
    sd_cmd_dir,
    sd_dat_dir,
    sd_chg_v,
	
	crc7_outdata_en,
	crc7_outdata,
	crc7_indata,
	crc7_indata_req
	
	);

localparam  sd_crtl_speed = 100;
localparam  sd_data_speed = 100;
localparam  sd_data_8b_cycle = sd_crtl_speed/sd_data_speed*2;
localparam  sd_data_16b_cycle = sd_crtl_speed/sd_data_speed*4;
output  [7:0]   LED_TEST;
reg     [7:0]   LED_TEST;
input	sys_clk;//ϵͳʱ��50MHz
input	clk_200m;//ϵͳʱ��200MHz
input	init_repeat_req;//���³�ʼ��

input read_req;//����������

input[31:0]	sd_ram_blockaddress;//������д���ַ
input[29:0]	sd_ram_data_size;//������д���С

output outdata_done;
output	outdata_en;//������Ч
output[7:0]	outdata;//�������
output[29:0]	outdata_num;//�������������


input	write_req;//д����
input[7:0]	read_ram_data;//��д�����ȡ����
output read_ram_en;//��д�����ȡʹ��
output[31:0]	read_ram_address;//��д�����ȡ��ַ

output sd_idle_flag;//���ݿ��б�־

inout sd_command;//sd�������
inout[3:0]	sd_data;//sd����������
output	sd_clk;//sdʱ��
output  sd_cmd_dir; //sd����� 1Ϊ���
output  sd_dat_dir; //sd���ݷ��� 1Ϊ���
output  sd_chg_v; 

input	crc7_outdata_en;
input[6:0]	crc7_outdata;
output[39:0]	crc7_indata;
output	crc7_indata_req;

wire	sd_command_dir;
wire	sd_command_in;
wire	sd_command_out;


assign	sd_command_in=(sd_command_dir==1'b1)?sd_command:1'bz;
assign	sd_command=(sd_command_dir==1'b0)?sd_command_out:1'bz;

reg	sd_sddata_dir;
reg	sd_int_sddata_dir;
reg	sd_chg_sddata_dir;
wire[3:0]	sd_sddata_out;
wire[3:0]	sd_sddata_in;

assign	sd_sddata_out=4'b1111;
assign	sd_sddata_in=((sd_int_sddata_dir==1'b1)||(sd_sddata_dir==1'b1)||(sd_chg_sddata_dir==1'b1)) ? sd_data:4'bzzzz;//1Ϊ����
assign	sd_data=((sd_int_sddata_dir==1'b0)&&(sd_sddata_dir==1'b0)&&(sd_chg_sddata_dir==1'b0)) ? sd_sddata_out:4'bzzzz;//0Ϊ���

assign sd_cmd_dir = (sd_command_dir==1'b0);
assign sd_dat_dir = ((sd_int_sddata_dir==1'b0)&&(sd_sddata_dir==1'b0)&&(sd_chg_sddata_dir==1'b0));

//ʱ�ӷ�Ƶ      // ����200M
reg sd_clk_100M=0;
reg sd_clk_50M=0; 
reg sd_clk_25M=0; 
reg [2:0]   sd_clk_50M_cnt=0;
reg [3:0]   sd_clk_25M_cnt=0;
reg sd_clk_100M_pulse=0;
reg sd_clk_50M_pulse=0; 
reg sd_clk_25M_pulse=0; 
// always @(posedge	sys_clk)
// begin
	// sd_clk_100M<=~sd_clk_100M;	    
// end	
// assign  sd_clk_100M_pulse=~sd_clk_100M ;	   

// always @(posedge	sys_clk)
// begin
    // if(sd_clk_50M_cnt==3) begin
        // sd_clk_50M_cnt <= 0;
        // sd_clk_50M_pulse <= 1;
    // end
    // else begin
        // sd_clk_50M_pulse <= 0;
        // if(sd_clk_50M_cnt>1)begin
            // sd_clk_50M_cnt <= sd_clk_50M_cnt+1;
            // sd_clk_50M<=1;
        // end
        // else begin
            // sd_clk_50M_cnt <= sd_clk_50M_cnt+1;
            // sd_clk_50M<=0;
        // end
    // end
// end	
// always @(posedge	sys_clk)
// begin
    // if(sd_clk_25M_cnt==7) begin
        // sd_clk_25M_cnt <= 0;
        // sd_clk_25M_pulse <= 1;
    // end
    // else begin
        // sd_clk_25M_pulse <= 0;
        // if(sd_clk_25M_cnt>3)begin
            // sd_clk_25M_cnt <= sd_clk_25M_cnt+1;
            // sd_clk_25M<=1;
        // end
        // else begin
            // sd_clk_25M_cnt <= sd_clk_25M_cnt+1;
            // sd_clk_25M<=0;
        // end
    // end
// end	
/*����100Mʱ��*/
always @(*)
begin
	sd_clk_100M<=sys_clk;
	sd_clk_100M_pulse<=1;	    
end	
always @(posedge	sys_clk)
begin
	sd_clk_50M<=~sd_clk_50M;
	sd_clk_50M_pulse<=sd_clk_50M;	    
end	   

always @(posedge	sys_clk)
begin
    if(sd_clk_25M_cnt==3) begin
        sd_clk_25M_cnt <= 0;
        sd_clk_25M_pulse <= 1;
    end
    else begin
        sd_clk_25M_pulse <= 0;
        if(sd_clk_25M_cnt>1)begin
            sd_clk_25M_cnt <= sd_clk_25M_cnt+1;
            sd_clk_25M<=1;
        end
        else begin
            sd_clk_25M_cnt <= sd_clk_25M_cnt+1;
            sd_clk_25M<=0;
        end
    end
end	
// /*����50Mʱ��*/
// always @(*)
// begin
	// sd_clk_50M<=sys_clk;
	// sd_clk_50M_pulse<=1;	    
// end	 
// always @(posedge	sys_clk)
// begin
	// sd_clk_25M<=~sd_clk_25M;
	// sd_clk_25M_pulse<=sd_clk_25M;	    
// end	   

//��ʼ���ڼ��������ʱ�Ӳ���
parameter	counter2_5us=10'd1000;//7'd125;
reg[9:0]	id_clk_counter;
reg	id_clk_pluse;
reg	id_clk;
always @(posedge	sys_clk)
begin
	if(id_clk_counter==counter2_5us)
		begin
			id_clk_counter<=0;
			id_clk_pluse<=1'b1;
		end
	else
		begin
			id_clk_pluse<=1'b0;
			if(id_clk_counter>(counter2_5us[9:1]))
				begin
					id_clk_counter<=id_clk_counter+1'd1;
					id_clk<=1'b1;			
				end
			else
				begin
					id_clk_counter<=id_clk_counter+1'b1;
					id_clk<=1'b0;		
				end
		end
end	

//�������ݴ�������µ�ʱ�ӡ�
reg	data_clk;
always @(posedge	sys_clk)
begin
	data_clk<=~data_clk;		
end	

//ϵͳ��ʼ������
parameter	counterncc=4'd15;
parameter	wait_18v_10ms=19'd500_000;
parameter	wait_18v_1ms=16'd50_000;
parameter	sd_int_idle=5'd0,
					sd_int_sendcmd0=5'd1,
					sd_int_waitcmd0=5'd2,
					sd_int_sendcmd8=5'd3,
					sd_int_get_res_r7=5'd4,
					sd_int_send_cmd55=5'd5,
					sd_int_get_res_fisrt_r1=5'd6,
					sd_int_send_acmd41=5'd7,
					sd_int_get_first_r3=5'd8,
					sd_int_send_cmd11=5'd9,
					sd_int_get_cmd11_r1=5'd10,
					sd_int_wait_18v_over=5'd11,
					sd_int_send_cmd2=5'd12,
					sd_int_get_first_r2=5'd13,
					sd_int_send_cmd3=5'd14,
					sd_int_get_first_r6=5'd15,
					sd_int_over=5'd16,
					sd_int_errorout=5'd17;
reg[4:0]	sd_int_state;
reg[23:0]	sd_int_time_counter;

reg	sd_int_req;
reg	sd_tran_fast_req;

reg[3:0]	cmd0time_counter;
reg	sd_int_next_cmd0;
reg[37:0]	SD_ACMD41;
reg[1:0]	sd_type;
reg[15:0]	sd_rca;
reg	sd_int_overflag;

//CMD
reg[37:0] send_int_cmd;
reg	send_int_cmd_req;
reg	send_int_cmd_overflag;
//Respone
reg int_get_respone_req;
reg int_respone_long_req;
reg	int_get_respone_overflag;
reg	int_get_respone_timeout;			
reg[133:0]	int_res_longdata;
reg[45:0]	int_res_shortdata;
//ERR
reg[7:0] int_errout;
reg ACMD41_REP_S18R=0;
reg     sd_clk_stop;
reg     wait_18v_10ms_over;
reg     wait_18v_10ms_req;
reg [18:0]  wait_18v_10ms_cnt;
reg     wait_18v_1ms_over;
reg     wait_18v_1ms_req;
reg [15:0]  wait_18v_1ms_cnt;
always@(posedge	sys_clk)
begin
	case(sd_int_state)
		sd_int_idle: //0
			begin
				//sd_int_state<=sd_int_wait_insert;
				sd_int_state<=sd_int_sendcmd0;
				sd_int_req<=1'b1;//�л���intģʽ��
				sd_int_overflag<=1'b0;
			end
		sd_int_sendcmd0://��λ 1
			begin
				if(send_int_cmd_overflag==1'b1)
					begin
						sd_int_state<=sd_int_waitcmd0;
						send_int_cmd_req<=1'b0;
					end
				else
					begin
						send_int_cmd<={6'h0,32'h0};//cmd0
						send_int_cmd_req<=1'b1;
					end
			end
		sd_int_waitcmd0://cmd0�ȴ�ָ����ʱ�� 2
			begin
				if(cmd0time_counter==counterncc)
					begin
						cmd0time_counter<=0;
						if(sd_int_next_cmd0==1'b1)
							begin
								sd_int_state<=sd_int_send_cmd55;
							end
						else
							begin
								sd_int_state<=sd_int_sendcmd8;
								//sd_int_state<=sd_int_wait_insert;
							end
					end
				else
					if(id_clk_pluse==1'b1)
						begin
							cmd0time_counter<=cmd0time_counter+1'd1;
						end
			end
		sd_int_sendcmd8://����CMD8��֧��V2 3
			begin
				if(send_int_cmd_overflag==1'b1)
					begin
						sd_int_state<=sd_int_get_res_r7;
						send_int_cmd_req<=1'b0;
					end
				else
					begin
						send_int_cmd<={6'd8,20'h0,4'h1,8'haa};//cmd8 2.7V-3.6V
						send_int_cmd_req<=1'b1;
					end			
			end
		sd_int_get_res_r7://�õ�R7��Ӧ 48bit 4
			begin
				if(int_get_respone_overflag==1'b1)
					begin
						int_get_respone_req<=1'b0;
						int_respone_long_req<=1'b0;
						if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_int_state<=sd_int_sendcmd0;
								// sd_int_next_cmd0<=1'b1;//˵������һ�ε�CMD0
								SD_ACMD41<={6'd41,8'b0000_0000,8'hff,8'b0,8'b0};//��һ���汾���������� [31:0] OCR
								sd_type<=2'd1;//ver1.0 ��׼����sd��
							end
						else//��Ӧ��Ҫ���
							if((int_res_shortdata[45:40]==6'd8)
							&&(int_res_shortdata[19:16]==4'd1)
							&&(int_res_shortdata[0]==1'd1))
								begin
									sd_int_state<=sd_int_send_cmd55;
									SD_ACMD41<={6'd41,8'b0100_0001,8'hff,8'h80,8'b0};//�ڶ����汾���������� ֧��HC 
									sd_type<=2'd2;//ver2.0 ��׼�������߸�����sd��
								end
							else
								begin
									sd_int_state<=sd_int_errorout;
								end						
					end
				else
					begin
						int_get_respone_req<=1'b1;
						int_respone_long_req<=1'b0;
					end
			end
		sd_int_send_cmd55://Acmd����ͷ 5
			begin
				if(send_int_cmd_overflag==1'b1)
					begin
						sd_int_state<=sd_int_get_res_fisrt_r1;
						send_int_cmd_req<=1'b0;
					end
				else
					begin
						sd_int_next_cmd0<=1'b0;//���
						send_int_cmd_req<=1'b1;
						send_int_cmd<={6'd55,32'd0};//RCAΪ0						
					end					
			end			
		sd_int_get_res_fisrt_r1://CMD55 ��Ӧ 48bits 6
			begin
				if(int_get_respone_overflag==1'b1)
					begin
						int_get_respone_req<=1'b0;
						int_respone_long_req<=1'b0;
						if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_int_state<=sd_int_idle;//�������
								sd_int_next_cmd0<=1'b0;//����´�cmd0����
							end
						else//�л�Ӧ��Ҫ���APP_CMD,READ
							begin
								if((int_res_shortdata[45:40]==6'd55)&&(int_res_shortdata[13]==1'b1)
								&&(int_res_shortdata[0]==1'b1))
								//int_res_shortdata[13]	card status [5]
									sd_int_state<=sd_int_send_acmd41;
								else
									sd_int_state<=sd_int_errorout;
							end
					end
				else
					begin
						int_get_respone_req<=1'b1;
						int_respone_long_req<=1'b0;
					end					
			end
		sd_int_send_acmd41://acmd41 7
			begin
				if(send_int_cmd_overflag==1'b1)
					begin
						sd_int_state<=sd_int_get_first_r3;
						send_int_cmd_req<=1'b0;
					end
				else
					begin 
						send_int_cmd<=SD_ACMD41;//����ACMD41		index 41 
						send_int_cmd_req<=1'b1;						
					end				
			end
		sd_int_get_first_r3://�õ�R3Ӧ�� 48bits  8
			begin
				if(int_get_respone_overflag==1'b1)
					begin
						int_get_respone_req<=1'b0;
						int_respone_long_req<=1'b0;
						if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_int_state<=sd_int_idle;
							end
						else//���HCS��ֵ
							begin
								if((int_res_shortdata[39]==1'b1)&&(int_res_shortdata[0]==1'b1))
								//���busy�Ƿ�Ϊ1,1��ʾ����ϵ����
									begin 
                                        ACMD41_REP_S18R <= int_res_shortdata[32];
                                        LED_TEST[7] <= int_res_shortdata[32];
										sd_int_state<=sd_int_send_cmd2;
										if(int_res_shortdata[38]==1'b0)
											sd_type<=2'd2;//ver2.0 ��׼��������sd��
										else
											sd_type<=2'd3;//ver2.0 ������sd��
									end									
								else
									sd_int_state<=sd_int_send_cmd55;//��������ACMD41
							end
					end	
				else
					begin
						int_get_respone_req<=1'b1;
						int_respone_long_req<=1'b0;
					end					
			end
        sd_int_send_cmd11://SD ����cmd11 ת����ѹ 9
            begin
                if(send_int_cmd_overflag==1'b1)
                    begin
                        sd_int_state<=sd_int_get_cmd11_r1;
                        send_int_cmd_req<=1'b0;	
                    end
                else
                    begin
                        send_int_cmd<={6'd11,32'h0};//����CMD11
                        send_int_cmd_req<=1'b1;						
                    end			
            end		
		sd_int_get_cmd11_r1://CMD11 ��Ӧ 48bits 10
			begin
				if(int_get_respone_overflag==1'b1)
					begin
						int_get_respone_req<=1'b0;
						int_respone_long_req<=1'b0;
						if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_int_state<=sd_int_idle;//�������
								sd_int_next_cmd0<=1'b0;//����´�cmd0����
							end
						else//�������Ӧ
							begin
                                sd_int_state<=sd_int_wait_18v_over;
							end
					end
				else
					begin
						int_get_respone_req<=1'b1;
						int_respone_long_req<=1'b0;
					end					
			end
    sd_int_wait_18v_over: //�ȴ���ѹת����� 11
        begin
            if(sd_change_18v_ok) begin
                sd_change_18v_req<=0;
                sd_int_state<=sd_int_send_cmd2;
            end
            else
                sd_change_18v_req<=1;
        end
	sd_int_send_cmd2://SD ������Ϣ 13
		begin
			if(send_int_cmd_overflag==1'b1)
				begin
					sd_int_state<=sd_int_get_first_r2;
					send_int_cmd_req<=1'b0;	
				end
			else
				begin
					send_int_cmd<={6'h2,32'h0};//����CMD2
					send_int_cmd_req<=1'b1;						
				end			
		end
	sd_int_get_first_r2://134 bits 13
		begin
			if(int_get_respone_overflag==1'b1)
				begin
					int_get_respone_req<=1'b0;
					int_respone_long_req<=1'b0;
					if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
						begin
							sd_int_state<=sd_int_idle;
						end
					else//����л�Ӧ����Ҫ���
						if(int_res_shortdata[0]==1'b1)
							begin
								sd_int_state<=sd_int_send_cmd3;
							end
						else
							begin
								sd_int_state<=sd_int_errorout;
							end
				end	
			else
				begin
					int_get_respone_req<=1'b1;
					int_respone_long_req<=1'b1;
				end
		end
	sd_int_send_cmd3://�õ��µ�RCAֵ 14
		begin
			if(send_int_cmd_overflag==1'b1)
				begin
					sd_int_state<=sd_int_get_first_r6;
					send_int_cmd_req<=1'b0;
				end
			else
				begin
					send_int_cmd<={6'h3,32'h0};//����CMD3
					send_int_cmd_req<=1'b1;					
				end			
		end
	sd_int_get_first_r6:// 48 bits  15
		begin
			if(int_get_respone_overflag==1'b1)
				begin
					int_get_respone_req<=1'b0;
					int_respone_long_req<=1'b0;
					if(int_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
						begin
							sd_int_state<=sd_int_idle;
						end
					else//����л�Ӧ���RCA
						begin
							sd_rca<=int_res_shortdata[39:24];
							sd_int_state<=sd_int_over;
						end
				end
			else
				begin
					int_get_respone_req<=1'b1;
					int_respone_long_req<=1'b0;
				end
		end
	sd_int_over:// 16
		begin
			sd_int_overflag<=1'b1;//��ɳ�ʼ����־
			sd_int_req<=1'b0;//�˳�intģʽ��
		end
	sd_int_errorout:
		begin		
			int_errout<=8'b0;
			sd_int_state<=sd_int_idle;
		end
	endcase
end
parameter   sd_change_18v_idle              = 5'd0,
                sd_change_18v_first_1ms     = 5'd1,
                sd_change_18v_wait_pd       = 5'd2,
                sd_change_18v_first_10ms    = 5'd3,
                sd_change_18v_sec_1ms       = 5'd4,
                sd_change_18v_res           = 5'd5,
                sd_change_18v_end           = 5'd6;
reg [4:0]   sd_change_18v_state;
reg         sd_change_18v_req;
reg         sd_change_18v_ok;
reg         sd_chg_v;
always@(posedge sys_clk)
    LED_TEST[6]<=sd_chg_v;
//��ѹת������
always@(posedge sys_clk) begin
    case(sd_change_18v_state)
        sd_change_18v_idle  :
            if(sd_change_18v_req == 1'b1) begin
                sd_change_18v_state<=sd_change_18v_first_1ms; 
                sd_chg_sddata_dir <= 1;        
                LED_TEST[0] <= 1; 
                LED_TEST[1] <= sd_cmd_dir|sd_dat_dir;
            end
            else begin
                sd_change_18v_state<=sd_change_18v_state;
            end       
        sd_change_18v_first_1ms :   //�ȴ�1ms�ر�sdclkʱ��
            if(wait_18v_1ms_over==1) begin
                wait_18v_1ms_req <= 0;
                sd_change_18v_state<=sd_change_18v_wait_pd;   
            end
            else begin
                wait_18v_1ms_req <= 1;
                sd_change_18v_state<=sd_change_18v_state;
            end  
        sd_change_18v_wait_pd:
            if(sd_sddata_in == 4'b1111) begin
                sd_change_18v_state<=sd_change_18v_first_10ms;
                sd_clk_stop <= 1; 
                sd_chg_v <= 0;
                LED_TEST[2] <= 1; 
            end
            else begin
                sd_change_18v_state<=sd_change_18v_state;
            end 
        sd_change_18v_first_10ms : //�ȴ�10ms�л���ѹ���涨��min5ms��
            if(wait_18v_10ms_over==1) begin
                wait_18v_10ms_req <= 0;
                sd_clk_stop <= 0;
                sd_change_18v_state<=sd_change_18v_sec_1ms; 
            end
            else begin
                wait_18v_10ms_req <= 1; 
                sd_change_18v_state<=sd_change_18v_state;
            end 
        sd_change_18v_sec_1ms : //�ȴ�1m sd����Ӧ
            if(wait_18v_1ms_over == 1'b1) begin //�ȴ�1m sd����Ӧ
                wait_18v_1ms_req <= 0;
                sd_change_18v_state<=sd_change_18v_res; 
            end
            else begin
                wait_18v_1ms_req <= 1;
                sd_change_18v_state<=sd_change_18v_state;
            end 
        sd_change_18v_res :
            if(sd_sddata_in == 4'b1111) begin
                sd_change_18v_state<=sd_change_18v_end; 
                LED_TEST[3] <= 1;  
            end
            else begin
                sd_change_18v_state<=sd_change_18v_state;
            end 
        sd_change_18v_end : begin
            sd_change_18v_ok<=1;
            sd_chg_sddata_dir <= 0;   
            LED_TEST[5:0]<='b0;
            end
        default :
            sd_change_18v_state <= sd_change_18v_idle;
        
    endcase
end
//10ms����
always@(posedge sys_clk)
    if((wait_18v_10ms_req==1'b1)&&(wait_18v_10ms_cnt<wait_18v_10ms)) begin
        wait_18v_10ms_cnt <= wait_18v_10ms_cnt + 1'b1;
        wait_18v_10ms_over <= 1'b0;
    end
    else if(wait_18v_10ms_req==1'b1) begin
        wait_18v_10ms_cnt <= 0;
        wait_18v_10ms_over <= 1'b1;
    end

//1ms����
always@(posedge sys_clk)
    if((wait_18v_1ms_req==1'b1)&&(wait_18v_1ms_cnt<wait_18v_1ms)) begin
        wait_18v_1ms_cnt <= wait_18v_1ms_cnt + 1'b1;
        wait_18v_1ms_over <= 1'b0;
    end
    else if(wait_18v_10ms_req==1'b1) begin
        wait_18v_1ms_cnt <= 0;
        wait_18v_1ms_over <= 1'b1;
    end
wire	cmd_clk;

//���ݴ������
// parameter	sd_tran_idle=4'd0,
					// sd_tran_sync=4'd1,
					// sd_tran_send_cmd9=4'd2,
					// sd_tran_get_first_r2=4'd3,
					// sd_tran_send_cmd7=4'd4,
					// sd_tran_get_first_r1b=4'd5,
					// sd_tran_send_cmd55=4'd6,
					// sd_tran_get_res_first_r1=4'd7,
					// sd_tran_send_acmd6=4'd8,
					// sd_tran_get_res_sec_r1=4'd9,
					// sd_tran_wait_req=4'd10,
					// sd_tran_send_cmd17=4'd11,
					// sd_tran_getdata	=4'd12,
					// sd_tran_error=4'd13;
parameter	sd_tran_idle=5'd0,
					sd_tran_sync=5'd1,
					sd_tran_send_cmd9=5'd2,
					sd_tran_get_first_r2=5'd3,
					sd_tran_send_cmd7=5'd4,
					sd_tran_get_first_r1b=5'd5,
					sd_tran_send_cmd55=5'd6,
					sd_tran_get_res_first_r1=5'd7,
					sd_tran_send_acmd6=5'd8,
					sd_tran_get_res_sec_r1=5'd9,
                    sd_tran_send_cmd6_mod0=5'd10,
                    sd_tran_getcmd6data=5'd11,
                    sd_tran_to_highspeed=5'd12,
					sd_tran_wait_req=5'd13,
					sd_tran_send_cmd17=5'd14,
					sd_tran_getdata	=5'd15,
					sd_tran_send_cmd12=5'd16,
                    sd_tran_get_res_cmd12_r1=5'd17,
					sd_tran_error=5'd18;
reg[4:0]	sd_tran_state;
reg[1:0]	sd_tran_data_sync_counter;

reg[6:0]	tran_data_timout;

reg[31:0]	sd_block_address;
reg[31:0]	block_counter;			
reg[7:0]	trant_errout;

//SD_DATA
reg	get_sddata_outtime_flag;
reg	get_sddata_overflag;    
reg	get_sddata_req;
//CMD
reg[37:0] send_tran_cmd;  
reg	send_tran_cmd_req;
reg	send_tran_cmd_overflag;
//Respone
reg tran_get_respone_req;
reg tran_respone_long_req;
reg	tran_get_respone_overflag;
reg	tran_get_respone_timeout;			
reg[133:0]	tran_res_longdata;
reg[45:0]	tran_res_shortdata;

reg	sd_tran_idle_flag;
reg [29:0]  sddata_num_max;
reg [511:0]  cmd6_resp;
reg [2:0] wait_8time_cnt;
reg [20:0]  sd_ram_block_cnt;
always@(posedge	sys_clk)
begin
	case(sd_tran_state)
		sd_tran_idle:// 0
			begin
				if(sd_int_overflag==1'b1)//�ȴ���ʼ�����
					begin						 
						sd_tran_state<=sd_tran_sync;
					end
			end
		sd_tran_sync://����ͬ��25Mʱ��  1
			begin
				if(sd_tran_data_sync_counter==3)
					begin
						sd_tran_data_sync_counter<=0;
						sd_tran_state<=sd_tran_send_cmd9;	
					end
				else
					if(cmd_clk==1'b1)
						begin
							sd_tran_data_sync_counter<=sd_tran_data_sync_counter+1'd1;
						end
			end
		sd_tran_send_cmd9://����RCA����CSD����  2
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_get_first_r2;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd9,sd_rca[15:0],16'd0};//cmd9
						send_tran_cmd_req<=1'b1;
					end
			end
		sd_tran_get_first_r2://�õ�R2��Ӧ������CSD����  134bits 3
			begin
				if(tran_get_respone_overflag==1'b1)
					begin
						tran_get_respone_req<=1'b0;
						tran_respone_long_req<=1'b0;
						if(tran_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_tran_state<=sd_tran_error;
							end
						else//����л�Ӧ���㿨�ռ䣬��ȡ��ʱʱ��
							begin
								sd_tran_state<=sd_tran_send_cmd7;
								if(tran_res_longdata[127:126]==2'b00) //ver 1.0 csd
									begin
										//sd_size<=(tran_res_longdata[73:62]+1)*(
										case(tran_res_longdata[114:112])
											6:
												tran_data_timout<=8;//��ȡ���ݳ�ʱ�ж� msΪ��λ
											7:
												tran_data_timout<=80;
											default:
												tran_data_timout<=2;
										endcase
									end
								else
									if(tran_res_longdata[127:126]==2'b01)
										begin
											tran_data_timout<=2;
										end
							end
					end
				else
					begin
						tran_respone_long_req<=1'b1;//�����ݷ���
						tran_get_respone_req<=1'b1;
					end
			end			
		sd_tran_send_cmd7://����״̬���������ݴ���״̬  4
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_get_first_r1b;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd7,sd_rca[15:0],16'd0};
						send_tran_cmd_req<=1'b1;
					end
			end
		sd_tran_get_first_r1b://�õ�R1b��Ӧ  48bits 5
			begin
				if(tran_get_respone_overflag==1'b1)
					begin
						tran_get_respone_req<=1'b0;
						tran_respone_long_req<=1'b0;
						if(tran_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_tran_state<=sd_tran_error;
							end
						else//����л�Ӧ����Ҫ���
							begin
								sd_tran_state<=sd_tran_send_cmd55;
							end
					end
				else
					begin
						tran_respone_long_req<=1'b0;
						tran_get_respone_req<=1'b1;						
					end
			end	
		sd_tran_send_cmd55://Acmd����ͷ  6
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_get_res_first_r1;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd55,sd_rca[15:0],16'd0};
						send_tran_cmd_req<=1'b1;						
					end					
			end
		sd_tran_get_res_first_r1://CMD55 ��Ӧ  48bits 7
			begin
				if(tran_get_respone_overflag==1'b1)
					begin
						tran_get_respone_req<=1'b0;
						tran_respone_long_req<=1'b0;
						if(tran_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_tran_state<=sd_tran_error;
							end
						else//�л�Ӧ��Ҫ���APP_CMD,READ
							begin
								//if((tran_res_shortdata[45:40]==6'd55)
								//&&(tran_res_shortdata[13]==1'b1)
								//&&(tran_res_shortdata[0]==1'b1))
								if(tran_res_shortdata[13]==1'b1)//APP_CMD
									sd_tran_state<=sd_tran_send_acmd6;
								else
									sd_tran_state<=sd_tran_idle;
							end
					end
				else
					begin
						tran_respone_long_req<=1'b0;
						tran_get_respone_req<=1'b1;
					end			
			end
		sd_tran_send_acmd6://acmd6 �������ݿ��  8
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_get_res_sec_r1;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd6,30'd0,2'b10};//����ACMD6						
						send_tran_cmd_req<=1'b1;
					end				
			end
		sd_tran_get_res_sec_r1://�õ��ڶ���R1Ӧ��  9
			begin
				if(tran_get_respone_overflag==1'b1)
					begin
						tran_get_respone_req<=1'b0;
						tran_respone_long_req<=1'b0;
						if(tran_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_tran_state<=sd_tran_error;
							end
						else//�����
							begin
								sd_tran_state<=sd_tran_send_cmd6_mod0/* sd_tran_wait_req */ ;
							end
					end
				else
					begin
						tran_respone_long_req<=1'b0;	
						tran_get_respone_req<=1'b1;
					end					
			end
        sd_tran_send_cmd6_mod0://��ѯ����  ��ȡ����block��Ϣ 10
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
                        sddata_num_max <= 64; //512bits
						sd_tran_state<=sd_tran_getcmd6data;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd6, 8'h80, 8'hff, 8'hff, 8'hf2};
						send_tran_cmd_req<=1'b1;
					end
			end
		sd_tran_getcmd6data: //��ȡcmd6��ѯ���ܵ���Ϣ  11
			begin
				if(get_sddata_overflag==1'b1)
					begin
						get_sddata_req<=1'b0;
                        // sd_tran_state<=sd_tran_wait_req;
						if(get_sddata_outtime_flag==1'b1)//��ȡ���ݳ�ʱ
							begin							
								sd_tran_state<=sd_tran_send_cmd6_mod0;
							end
						else
							begin
                                sd_tran_state<=sd_tran_to_highspeed;
							end
					end
				else begin
					get_sddata_req<=1'b1;
                end
			end    
        sd_tran_to_highspeed: //�ȴ�8������ �л�Ϊ����ģʽ  12
            begin
                if(wait_8time_cnt == 3'd7)
                    begin
                        wait_8time_cnt <= 3'b0;
                        sd_tran_fast_req <= 1;
                        sd_tran_state<=sd_tran_wait_req;
                    end
                else 
                    begin
                        wait_8time_cnt <= wait_8time_cnt + 1'b1;
                    end
            end
		sd_tran_wait_req:// �ȴ�д����   13 
			begin
				if(read_req==1'b1)
					begin
						sd_tran_state<=sd_tran_send_cmd17;
						sd_tran_idle_flag<=1'b0;//����æ״̬
                        sddata_num_max <= sd_ram_data_size;//512bytes
						case(sd_type)
							2'd1,2'd2://V1.0 V2.0 ��׼����
								begin
									sd_block_address<={sd_ram_blockaddress[22:0],9'b0};
								end
							2'd3://������
								begin
									sd_block_address<=sd_ram_blockaddress;
								end
						endcase
					end
				else
					begin
						sd_tran_idle_flag<=1'b1;//����״̬
						sd_tran_state<=sd_tran_wait_req;
					end
			end
		sd_tran_send_cmd17://��ȡ����block��Ϣ  14
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_getdata;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd18,sd_block_address};//����cmd17
						send_tran_cmd_req<=1'b1;
					end			
			end		
		sd_tran_getdata: //getdata  15
			begin
				if(get_sddata_overflag==1'b1)
					begin
						get_sddata_req<=1'b0;
						if(get_sddata_outtime_flag==1'b1)//��ȡ���ݳ�ʱ
							begin							
								sd_tran_state<=sd_tran_wait_req;
							end
						else
							begin
								sd_tran_state<=sd_tran_send_cmd12;
							end
					end
				else
					get_sddata_req<=1'b1;
			end
		sd_tran_send_cmd12://ֹͣ������  16
			begin
				if(send_tran_cmd_overflag==1'b1)
					begin
						sd_tran_state<=sd_tran_get_res_cmd12_r1;
						send_tran_cmd_req<=1'b0;
					end
				else
					begin
						send_tran_cmd<={6'd12,32'b0};//����cmd17
						send_tran_cmd_req<=1'b1;
					end			
			end		
		sd_tran_get_res_cmd12_r1://ֹͣ������  17
			begin
				if(tran_get_respone_overflag==1'b1)
					begin
						tran_get_respone_req<=1'b0;
						tran_respone_long_req<=1'b0;
						if(tran_get_respone_timeout==1'b1)//��ʱ�޻�Ӧ
							begin
								sd_tran_state<=sd_tran_error;
							end
						else//�����
							begin
								sd_tran_state<=sd_tran_wait_req;
							end
					end
				else
					begin
						tran_respone_long_req<=1'b0;	
						tran_get_respone_req<=1'b1;
					end					
			end
		sd_tran_error:
			begin
				trant_errout<=8'b0;
                sd_tran_state<=sd_tran_sync;
			end	
	endcase
end


//����CLK
reg sd_clk_dly;
// assign	cmd_clk=(sd_int_req)?id_clk_pluse:(sd_tran_fast_req)?1'b1:data_clk;//sd_tran_fast_req==1ʱ����Ч
// assign	cmd_clk=(sd_int_req)?id_clk_pluse:(sd_tran_fast_req)?sd_clk_50M_pulse:sd_clk_25M_pulse;//sd_tran_fast_req==1ʱ����Ч
always@(posedge sys_clk) sd_clk_dly<=sd_clk;
assign cmd_clk = ((sd_tran_state!=sd_tran_idle)&&(sd_tran_fast_req==1)||(sd_clk&&~sd_clk_dly));

//���ݴ����з������� 
parameter	send_cmd_idle=2'd0,
					send_cmd_sync=2'd1,
					send_cmd_bitdata=2'd2,
					send_cmd_over=2'd3;

reg[1:0]	send_cmd_state;
//reg	send_cmd_overflag;
reg[2:0]	cmd_sync_counter;
reg[37:0]	cmd_outdata;
reg[6:0]	cmd_bit_counter;
reg[7:0]	cmd_last_data;
reg	cmd_last_data_outreq;

reg	sd_command_out_temp;

reg[39:0]	crc7_indata;
reg	crc7_indata_req;

reg[37:0] send_cmd;
reg	send_cmd_req;
reg	sd_out_command_dir;
reg send_cmd_overflag;

always @(posedge	sys_clk)
	case(send_cmd_state)
		send_cmd_idle:
			begin
				if(send_cmd_req==1'b1)
					send_cmd_state<=send_cmd_sync;
			end
		send_cmd_sync://ͬ������ʱ��
			begin
				if(cmd_sync_counter==3'd5)
					begin
						cmd_sync_counter<=0;
						crc7_indata_req<=1'b0;//��ֹcrc7�����ź�
						send_cmd_state<=send_cmd_bitdata;
					end
				else
					begin
						if(cmd_clk==1'b1)
							begin
								sd_command_out_temp<=1'b1;
								sd_out_command_dir<=1'b1;//command���
														
								cmd_outdata<=send_cmd;//�õ�cmd
								
								crc7_indata<={2'b01,send_cmd[37:0]};//���crc7������ֵ
								crc7_indata_req<=1'b1;//crc7�����ź�
								
								cmd_sync_counter<=cmd_sync_counter+1'd1;
							end
					end
			end
		send_cmd_bitdata://���͵���bitֵ
			begin
				if(cmd_clk==1'b1)
					case(cmd_bit_counter)
						0://��ʼ0
							begin
								sd_command_out_temp<=1'b0;
								cmd_bit_counter<=1;
							end
						1://����1
							begin
								sd_command_out_temp<=1'b1;
								cmd_bit_counter<=2;
							end
						39://�����40bitλ����������crcֵ
							begin
								sd_command_out_temp<=cmd_outdata[37];
								cmd_bit_counter<=40;
								if(crc7_outdata_en==1'b1)//CRC7��ֵ
									begin 
										cmd_last_data<={crc7_outdata,1'b1};
										cmd_last_data_outreq<=1'b1;
									end
								else
									begin
										cmd_last_data<=8'hff;
									end
							end
						48:
							begin
								send_cmd_state<=send_cmd_over;
								send_cmd_overflag<=1'b1;
								
								cmd_last_data_outreq<=1'b0;
								cmd_bit_counter<=0;
							end
						default:
							begin
								cmd_bit_counter<=cmd_bit_counter+1'd1;
								if(cmd_last_data_outreq==1'b1)
									begin
										sd_command_out_temp<=cmd_last_data[7];
										cmd_last_data<={cmd_last_data[6:0],1'b0};										
									end
								else
									begin
										sd_command_out_temp<=cmd_outdata[37];
										cmd_outdata<={cmd_outdata[36:0],1'b0};
									end
							end
					endcase
			end
		send_cmd_over:
			begin
				send_cmd_state<=send_cmd_idle;
				sd_out_command_dir<=1'b0;
				send_cmd_overflag<=1'b0;
			end
	endcase

//�õ����ݻ�Ӧ ��CMD����
parameter	get_respone_idle=3'd0,
					get_respone_bitstart=3'd1,
					get_respone_iddata=3'd2,
					get_respone_timeoutover=3'd3,
					get_respone_shiftdata=3'd4,
					get_respone_last=3'd5,
					get_respone_sendover=3'd6;
					
reg[2:0]	get_respone_state;
reg	sd_in_command_dir;
reg[6:0]	get_outtime_counter;
//reg	get_respone_overflag;
//reg	get_respone_timeout;			
//reg[133:0]	res_longdata;
//reg[45:0]	res_shortdata;
reg[1:0]	zero_counter;
reg[7:0]	respone_shift_counter;
reg[133:0]	sd_command_intemp;
reg[3:0]	get_last_counter;

reg get_respone_req;
reg respone_long_req;
reg get_respone_overflag;
reg	get_respone_timeout;
reg[133:0]	respone_longdata;
reg[45:0]	respone_shortdata;

always @(posedge	sys_clk)
case(get_respone_state)
	get_respone_idle:
		begin
			if(get_respone_req==1'b1)
				get_respone_state<=get_respone_bitstart;
		end
	get_respone_bitstart:
		begin
			sd_in_command_dir<=1'b1;//��������
			get_respone_state<=get_respone_iddata;
		end
	get_respone_iddata://ʶ����ʼ�ͷ�������
		begin
			if(cmd_clk==1'b1)
				begin
					if(get_outtime_counter==7'd80)
						begin
							get_outtime_counter<=0;
							
							get_respone_state<=get_respone_timeoutover;
						end
					else
						begin
							get_outtime_counter<=get_outtime_counter+1'd1;
							case(zero_counter)//��λ2��0
								0:
									begin
										if(sd_command_in==1'b0)
											zero_counter<=1;
									end
								1:
									begin
										if(sd_command_in==1'b0)
											begin
												zero_counter<=0;
												get_respone_state<=get_respone_shiftdata;
											end	
										else
											begin
												zero_counter<=0;
												get_respone_state<=get_respone_timeoutover;
											end
									end
							endcase										
						end
				end
		end
	get_respone_timeoutover:
		begin
			if(cmd_clk==1'b1)
				begin
					get_outtime_counter<=0;
					get_respone_timeout<=1'b1;
					get_respone_overflag<=1'b1;
					get_respone_state<=get_respone_sendover;
				end
		end
	get_respone_shiftdata://�������� ��ʱ����crcУ��
		begin				
			if(cmd_clk==1'b1)
				begin
					get_outtime_counter<=0;
					case(respone_shift_counter)
						46:
							begin
								if(respone_long_req==1'b1)//����ǳ����ݻ�Ӧ
									begin
										sd_command_intemp<={sd_command_intemp[132:0],sd_command_in};
										respone_shift_counter<=47;
									end
								else//�����ݻ�Ӧ
									begin
										get_respone_state<=get_respone_last;
										respone_shift_counter<=0;
									end
							end
						134://����134bit�Ļ�Ӧ
							begin
								get_respone_state<=get_respone_last;							
								respone_shift_counter<=0;
							end
						default:
							begin
								sd_command_intemp<={sd_command_intemp[132:0],sd_command_in};
								respone_shift_counter<=respone_shift_counter+1'd1;
							end
					endcase		
				end
		end
	get_respone_last://����crc��ת 16crc+8״̬��ת ��Ӧ���¸�CMD���
		begin
			if(get_last_counter==4'd10)
				begin
					get_last_counter<=0;
					get_respone_overflag<=1'b1;
					get_respone_state<=get_respone_sendover;
					if(respone_long_req==1'b1)
						respone_longdata<=sd_command_intemp[133:0];
					else
						respone_shortdata<=sd_command_intemp[45:0];				
				end
			else
				if(cmd_clk==1'b1)
					begin
						get_last_counter<=get_last_counter+1'd1;
					end
		end
	get_respone_sendover:
		begin
			get_respone_state<=get_respone_idle;
			get_respone_overflag<=1'b0;
			get_respone_timeout<=1'b0;
			sd_in_command_dir<=1'b0;
			sd_command_intemp<=0;
		end
endcase		

//��data�����ߵõ�����
parameter	get_sddata_idle=3'd0,
					get_sddat_ready=3'd1,
					get_sddata_wait_start=3'd2,
					get_sddata_shiftdata=3'd3,
					get_sddata_waitNac=3'd4,
					get_sddata_waitlast=3'd5,
					get_sddata_over=3'd6;
reg[2:0]	get_sddata_state;
//reg	get_sddata_outtime_flag;
//reg	sd_sddata_dir;
//reg	get_sddata_overflag;
reg	get_sddata_outtime_req;
reg[15:0]	get_sddata_times;
reg	half_flag;

reg[8:0]	outdata_num_delay;
reg		get_sddata_outtime_over;
reg	first_data_flag;
reg[4:0]	get_sddata_waitlast_couter;
reg[3:0]	sd_sddata_in_delay;
reg	sddata_valid_flag;
reg[29:0]	sddata_num;

always@(posedge	sys_clk)
begin
	case(get_sddata_state)	
		get_sddata_idle:
			begin
				if(get_sddata_req==1'b1)
					get_sddata_state<=get_sddat_ready;
			end
		get_sddat_ready:
			begin
				sd_sddata_dir<=1'b1;//��Ϊ����
				get_sddata_state<=get_sddata_wait_start;
			end
		get_sddata_wait_start:
			begin
				if(get_sddata_outtime_over==1'b1)
					begin
						get_sddata_outtime_req<=1'b0;// �����ʱ������
						get_sddata_outtime_flag<=1'b1;
						get_sddata_overflag<=1'b1;
						get_sddata_state<=get_sddata_over;
					end
				else				
					if((cmd_clk==1'b1)&&(sd_sddata_in==4'd0))						
						begin
							get_sddata_state<=get_sddata_shiftdata;
							get_sddata_outtime_req<=1'b0;// �����ʱ������
						end
					else
						begin
							get_sddata_outtime_req<=1'b1;// ��ʱ������
							get_sddata_times<=tran_data_timout;
							//get_sddata_times<=2000;
						end
			end
		get_sddata_shiftdata:
			begin
				if(cmd_clk==1'b1)
					begin
						sd_sddata_in_delay<=sd_sddata_in;//��ʱ����
						case(half_flag)
							0:
								begin
									half_flag<=1'b1;
									if(sddata_valid_flag==1'b1)
										sddata_num<=sddata_num+1'd1;
								end
							1:
								begin
									half_flag<=1'b0;
									if(sddata_num==sddata_num_max-1)
										begin											
											get_sddata_state<=get_sddata_waitlast;
											sddata_valid_flag<=1'b0;//���ݲ�����
										end
									else if(sddata_num[8:0] == 511)
                                        begin		
											get_sddata_state<=get_sddata_waitNac;
											sddata_valid_flag<=1'b1;//���ݲ�����
                                        end
                                    else
										begin
											sddata_valid_flag<=1'b1;//���ݿ���
										end
								end
						endcase	
					end
			end
		get_sddata_waitNac:
			if(cmd_clk==1'b1)
                begin
                    if(get_sddata_waitlast_couter==5'd20)
                        begin
                            get_sddata_waitlast_couter<=0;
                            get_sddata_state<=get_sddata_wait_start;
                        end
                    else
                        begin
                            get_sddata_waitlast_couter<=get_sddata_waitlast_couter+1'd1;
                            half_flag<=0;
                        end
                end
		get_sddata_waitlast:
			if(cmd_clk==1'b1)
                begin
                    if(get_sddata_waitlast_couter==5'd20)
                        begin
                            get_sddata_waitlast_couter<=0;
                            get_sddata_overflag<=1'b1;
                            get_sddata_state<=get_sddata_over;
                        end
                    else
                        begin
                            get_sddata_waitlast_couter<=get_sddata_waitlast_couter+1'd1;
                            half_flag<=0;
                            sddata_num<=0;
                        end
                end
		get_sddata_over:
			begin
				get_sddata_overflag<=1'b0;
                get_sddata_outtime_flag<=1'b0;      //!
				get_sddata_state<=get_sddata_idle;
				sd_sddata_dir<=1'b0;//��Ϊ���
			end
	endcase
end

assign outdata_done = get_sddata_overflag;

//������� 
reg[7:0]	outdata;
reg	outdata_en;
reg[29:0]	outdata_num;//29~9Ϊ�������8~0Ϊ���ڼ���
reg[1:0]	delay_num;
reg[7:0]	outdata_reg;
reg	outdata_en_reg;
reg[29:0]	outdata_num_reg;
wire[8:0]  sddata_num_max0;
reg [15:0]  sddata_wait_flag0;
reg         sddata_wait_flag1;
reg         sddata_wait_flag2;
reg         sddata_wait_flag3;
assign sddata_num_max0 = sddata_num_max-1;
// always @(posedge	sys_clk)
    // if(get_sddata_state==get_sddata_shiftdata) begin
        // sddata_wait_flag0 <= 1'b0;
        // sddata_wait_flag1 <= sddata_wait_flag0;
        // sddata_wait_flag2 <= sddata_wait_flag1;
        // sddata_wait_flag3 <= sddata_wait_flag2;
    // end
    // else begin
        // sddata_wait_flag0 <= 1'b1;
        // sddata_wait_flag1 <= sddata_wait_flag0;
        // sddata_wait_flag2 <= sddata_wait_flag1;
        // sddata_wait_flag3 <= sddata_wait_flag2;
    
    // end
always @(posedge	sys_clk)
    if(get_sddata_state==get_sddata_shiftdata) begin
        sddata_wait_flag0 <= {sddata_wait_flag0[14:0],1'b0};
    end
    else begin
        sddata_wait_flag0 <= {sddata_wait_flag0[14:0],1'b1};
    
    end
        

always @(posedge	sys_clk)
begin
	if((outdata_num_reg==sddata_num_max-1)&&(cmd_clk==1'b1))
		begin
			case(delay_num)
				0:
					begin
						delay_num<=1;	
						outdata_num_reg<=0;
						outdata_en_reg<=1'b0;
						outdata_reg<=0;					
					end
				1:
					begin
						delay_num<=2;						
					end
				2:
					begin
						delay_num<=0;
					end
			endcase
		end
	else
		if((half_flag==1'b1)&&(cmd_clk==1'b1))
			begin
				outdata_reg<={sd_sddata_in_delay,sd_sddata_in};
				outdata_en_reg<=1'b1;
				if(outdata_en_reg==1'b1)
					outdata_num_reg<=outdata_num_reg+1'd1;
			end
        // else
            // begin
				// outdata_reg<=outdata_reg;
				// outdata_en_reg<=1'b0;
				// outdata_num_reg<=outdata_num_reg;
            // end
end

always@(posedge	sys_clk)
    begin
        if((sddata_num_max != 64)&&(~sddata_wait_flag0[sd_data_8b_cycle])) begin
            outdata     = outdata_reg;
            outdata_en  = outdata_en_reg;
            outdata_num = outdata_num_reg;
        end
        else begin
            outdata     = 0;
            outdata_en  = 0;
            outdata_num = 0;
        end        
    end

//���ݴ�����̵ȴ��������ݳ�ʱ
parameter	counter1ms=9'd400;

reg	clk1ms_pluse;
reg[8:0]	clk1ms_counter;
always @(posedge	sys_clk)
begin
	if(clk1ms_counter==counter1ms)
		begin
			clk1ms_counter<=0;
			clk1ms_pluse<=1'b1;
		end
	else
		begin
			clk1ms_pluse<=1'b0;
			if(id_clk_pluse==1'b1)
				clk1ms_counter<=clk1ms_counter+1'd1;
		end
end

reg[15:0]	get_sddata_outtime_counter;
//reg	get_sddata_outtime_over;
always @(posedge	sys_clk)
begin
	if(get_sddata_outtime_req==1'b1)
		begin
			if(get_sddata_outtime_counter==get_sddata_times)
				get_sddata_outtime_over<=1'b1;
			else
				if(clk1ms_pluse==1'b1)
					get_sddata_outtime_counter<=get_sddata_outtime_counter+1'd1;
		end
	else
		begin
			get_sddata_outtime_over<=0;
			get_sddata_outtime_counter<=0;
		end
end



//�������������������Ӧģ��
always @(*)
begin
	if(sd_int_req==1'b1)
		begin
			send_cmd=send_int_cmd;
			send_cmd_req=send_int_cmd_req;
			send_int_cmd_overflag=send_cmd_overflag;
			
			get_respone_req=int_get_respone_req;
			respone_long_req=int_respone_long_req;
			int_get_respone_overflag=get_respone_overflag;
			int_get_respone_timeout=get_respone_timeout;			
			int_res_longdata=respone_longdata;
			int_res_shortdata=respone_shortdata;

			send_tran_cmd_overflag=0;
			tran_get_respone_overflag=0;
			tran_get_respone_timeout=0;
			tran_res_longdata=0;
			tran_res_shortdata=0;			
		end
	else
		begin
			send_cmd=send_tran_cmd;
			send_cmd_req=send_tran_cmd_req;
			send_tran_cmd_overflag=send_cmd_overflag;
			
			get_respone_req=tran_get_respone_req;
			respone_long_req=tran_respone_long_req;
			tran_get_respone_overflag=get_respone_overflag;
			tran_get_respone_timeout=get_respone_timeout;			
			tran_res_longdata=respone_longdata;
			tran_res_shortdata=respone_shortdata;	
		
			send_int_cmd_overflag=0;
			
			int_get_respone_overflag=0;
			int_get_respone_timeout=0;
			int_res_longdata=0;
			int_res_shortdata=0;			
		end
end


assign	sd_command_dir=(sd_in_command_dir==1'b1)?1'b1:1'b0;//SD_IN��������

assign	sd_command_out=(sd_out_command_dir==1'b1)?sd_command_out_temp:1'b1;//����SD_CMDĬ����1

// assign	sd_clk=(sd_clk_stop)?0:(sd_int_req==1'b1)?id_clk:(sd_tran_fast_req)?sys_clk:data_clk;
assign	sd_clk=(sd_clk_stop)?0:(sd_int_req==1'b1)?id_clk:(sd_tran_fast_req)?sys_clk:sd_clk_25M;

assign	sd_idle_flag=(sd_int_req==1'b1)?1'b0:sd_tran_idle_flag;
// synopsys translate_off
initial	
begin

	id_clk_counter=0;
	id_clk_pluse=0;
	id_clk=0;
	data_clk=0;

	sd_int_state=sd_int_idle;
	sd_int_time_counter=0;

	sd_int_req=0;

	cmd0time_counter=0;
	sd_int_next_cmd0=0;
	SD_ACMD41=0;
	sd_type=0;
	sd_rca=0;
	sd_int_overflag=0;


	send_int_cmd=0;
	send_int_cmd_req=0;
	send_int_cmd_overflag=0;
//Respone
	int_get_respone_req=0;
	int_respone_long_req=0;
	int_get_respone_overflag=0;
	int_get_respone_timeout=0;			
	int_res_longdata=0;
	int_res_shortdata=0;

//ERR
	int_errout=0;

	sd_tran_state=sd_tran_idle;
	sd_tran_data_sync_counter=0;

	tran_data_timout=0;

	sd_block_address=0;
	block_counter=0;			
	trant_errout=0;

//SD_DATA
	get_sddata_outtime_flag=0;
	get_sddata_overflag=0;
	get_sddata_req<=0;
//CMD
	send_tran_cmd=0;
	send_tran_cmd_req=0;
	send_tran_cmd_overflag=0;
//Respone
	tran_get_respone_req=0;
	tran_respone_long_req=0;
	tran_get_respone_overflag=0;
	tran_get_respone_timeout=0;			
	tran_res_longdata=0;
	tran_res_shortdata=0;

	sd_tran_idle_flag<=0;

	send_cmd_state=send_cmd_idle;
//reg	send_cmd_overflag;
	cmd_sync_counter=0;
	cmd_outdata=0;
	cmd_bit_counter=0;
	cmd_last_data=0;
	cmd_last_data_outreq=0;

	sd_command_out_temp=0;

	crc7_indata=0;
	crc7_indata_req=0;

	send_cmd=0;
	send_cmd_req=0;
	sd_out_command_dir=0;
	send_cmd_overflag=0;


	get_respone_state=get_respone_idle;
	sd_in_command_dir=0;
	get_outtime_counter=0;

	zero_counter=0;
	respone_shift_counter=0;
	sd_command_intemp=0;
	get_last_counter=0;

	get_respone_req=0;
	respone_long_req=0;
	get_respone_overflag=0;
	get_respone_timeout=0;
	respone_longdata=0;
	respone_shortdata=0;


	get_sddata_state=get_sddata_idle;

	get_sddata_outtime_req=0;
	get_sddata_times=0;
	half_flag=0;
	outdata=0;
	outdata_en=0;
	outdata_num=0;
	outdata_reg=0;
	outdata_en_reg=0;
	outdata_num_reg=0;

	sd_sddata_dir<=0;

	get_sddata_outtime_flag=0;

	clk1ms_pluse=0;
	clk1ms_counter=0;

	get_sddata_outtime_counter=0;
	outdata_done = 0;
    sddata_num_max = 511;
    cmd6_resp = 0;
    sd_tran_fast_req = 0;
    wait_8time_cnt=0;
    sd_ram_block_cnt=0;
    sddata_wait_flag=0;
    
    sd_change_18v_state = sd_change_18v_idle;
    sd_clk_stop=0;
    wait_18v_10ms_over=0;
    wait_18v_10ms_req=0;
    wait_18v_10ms_cnt=0;
    wait_18v_1ms_over=0;
    wait_18v_1ms_req=0;
    wait_18v_1ms_cnt=0;
    
    LED_TEST=0;
    sd_chg_sddata_dir=0;
    sd_chg_v=1;
    sd_change_18v_req=0;
end
//synopsys translate_on 
endmodule
