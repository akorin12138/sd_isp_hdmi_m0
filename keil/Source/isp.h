#ifndef __ISP_H
#define __ISP_H

#include "code_def.h"

/*
ISP_ID      ISP_name

[0]     		source_data
[1]     		dpc_raw
[2]     		blc_raw
[3]    		  bayer_rgb
[4]     		wb_rgb
[5]     		ccm_rgb
[6]     		gamma_rgb
[7]     		csc_YCbCr
[8]     		lap_yuv
[9]     		bilateral
[10]    		csc_RGB
[11]    		haze_rgb
[12]    		hdr_YUV
[13]    		gau_raw
[14]    		bnr_raw
*/

#define dpc 	28
#define blc 	24
#define bayer   20
#define wb 		16
#define ccm 	12
#define gamma   8
#define yuv 	4
#define lap 	0

#define dnr		29
#define rgb		25
#define haze	21
#define hdr		17
#define gau		13
#define bnr		9
#define ispL	5 //output
#define ispR	1 //output

void setISPnum(uint8_t isp_name,uint8_t isp_id);
void getISPstate(void);
void setISPcoodrd(uint16_t splitwin_x, uint16_t splitwin_y);
#endif
