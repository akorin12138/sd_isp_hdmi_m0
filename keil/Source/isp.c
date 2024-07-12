#include "isp.h"

static uint32_t	isp_num0to7;
static uint32_t	isp_num8to15;
static uint32_t	isp_coord;
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

/**
 * @note   This function is used to set isp-moudules' ordination.
 * @brief  isp_name:target isp-moudule, isp_id:target isp-moudule's input of source isp-moudule
 * @param  isp_name 
 * @param  isp_id
 * @retval None
 */
void setISPnum(uint8_t isp_name,uint8_t isp_id){
	if(isp_name%4){
		isp_num8to15 |= isp_id << (isp_name-1);
		//printf("isp_num8to15:%80x\n",isp_num8to15);
		ISP->ISP_DATA_NUM8to15 = isp_num8to15;
		
	}
	else{
		isp_num0to7 |= isp_id << isp_name;
		//printf("isp_num0to7:%80x\n",isp_num0to7);
		ISP->ISP_DATA_NUM0to7 = isp_num0to7;
	}
}


/// @brief 
void getISPstate(){
		printf("isp_num8to15:%08x\n",isp_num8to15);
		printf("isp_num0to7:%08x\n",isp_num0to7);
}

/// @brief 用于设定分屏起始坐标
/// @param splitwin_x 
/// @param splitwin_y 
void setISPcoodrd(uint16_t splitwin_x, uint16_t splitwin_y){
	isp_coord &= 0;
	isp_coord |= splitwin_x << 11;
	isp_coord |= 4;						// only been set to 4 pixel
	printf("isp choord: x:%d,y:4\n", isp_coord>>11);
	ISP->ISP_WIN_COORD = isp_coord;
}