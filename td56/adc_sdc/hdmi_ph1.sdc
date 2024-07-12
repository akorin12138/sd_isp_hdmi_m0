create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sys_clk}]
#create_clock -name isp_clk -period 10 -waveform {0 5} [get_nets {isp_clk}]
create_generated_clock -name sdcard_clk -source [get_ports { sys_clk }] -master_clock sys_clk -multiply_by 2 -duty_cycle 0.5 [get_nets { sdcard_clk }]
#create_generated_clock -name isp_clk -source [get_ports {sys_clk}] -master_clock {sys_clk} -multiply_by 4 -duty_cycle 0.5 [get_nets {isp_clk}]
create_generated_clock -name mux_clk -source [get_ports {sys_clk}] -master_clock {sys_clk} -multiply_by 4 -duty_cycle 0.5 [get_nets {mux_clk}]
create_generated_clock -name rgb_clk -source [get_ports {sys_clk}] -master_clock {sys_clk} -multiply_by 2.5 -duty_cycle 0.5 [get_nets {rgb_clk}]
create_generated_clock -name yuv_clk -source [get_ports {sys_clk}] -master_clock {sys_clk} -multiply_by 2 -duty_cycle 0.5 [get_nets {yuv_clk}]
create_generated_clock -name raw_clk -source [get_ports {sys_clk}] -master_clock {sys_clk} -multiply_by 2 -duty_cycle 0.5 [get_nets {raw_clk}]

#create_generated_clock -name sdram_clk -source [get_ports {sys_clk}] -master_clock sys_clk -multiply_by 10 [get_nets {sdram_clk_100m}]
#create_generated_clock -name sdram_clk_n -source [get_ports {sys_clk}] -master_clock sys_clk -multiply_by 10 -phase 270 [get_nets {sdram_clk_100m_shift}]
create_generated_clock -name hdmi_clk -source [get_ports {sys_clk}] -master_clock sys_clk -multiply_by 2 [get_nets {hdmi_clk}]
create_generated_clock -name hdmi_clk_5 -source [get_ports {sys_clk}] -master_clock sys_clk -multiply_by 8 [get_nets {hdmi_clk_5}]





#-------<CortexM0_SoC.v>--------#
#create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sysclk}]
#create_generated_clock -name sdcard_clk -source [get_ports { sysclk }] -master_clock sys_clk -multiply_by 3.57 -duty_cycle 0.5 [get_nets { sdcard_clk }]
# create_generated_clock  -name sdram_clk -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 6.81 [get_nets {sdram_clk_100m}]
# create_generated_clock  -name sdram_clk_n -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 6.81 -phase 270 [get_nets {sdram_clk_100m_shift}]
#create_generated_clock -name hdmi_clk -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 2.65 [get_nets {hdmi_clk}]
#create_generated_clock -name hdmi_clk_5 -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 13.25 [get_nets {hdmi_clk_5}]
#create_generated_clock -name isp_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 3.57 -duty_cycle 0.5 [get_nets {isp_clk}]

#create_clock -name sys_clk -period 20 -waveform {0 10} [get_ports {sysclk}]
#create_generated_clock -name sdcard_clk -source [get_ports { sysclk }] -master_clock sys_clk -multiply_by 2 -duty_cycle 0.5 [get_nets { sdcard_clk }]
##create_generated_clock -name isp_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 4 -duty_cycle 0.5 [get_nets {isp_clk}]
#create_generated_clock -name mux_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 4 -duty_cycle 0.5 [get_nets {mux_clk}]
#create_generated_clock -name rgb_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 4 -duty_cycle 0.5 [get_nets {rgb_clk}]
#create_generated_clock -name yuv_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 3 -duty_cycle 0.5 [get_nets {yuv_clk}]
#create_generated_clock -name raw_clk -source [get_ports {sysclk}] -master_clock {sys_clk} -multiply_by 3 -duty_cycle 0.5 [get_nets {raw_clk}]

##create_generated_clock -name sdram_clk -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 7 [get_nets {sdram_clk_100m}]
##create_generated_clock -name sdram_clk_n -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 7 -phase 270 [get_nets {sdram_clk_100m_shift}]
#create_generated_clock -name hdmi_clk -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 2 [get_nets {hdmi_clk}]
#create_generated_clock -name hdmi_clk_5 -source [get_ports {sysclk}] -master_clock sys_clk -multiply_by 8 [get_nets {hdmi_clk_5}]
 
