#include "code_def.h"
#include "isp.h"
#include <string.h>
#include <stdint.h>

int main()
{
	SD->SD_ADDR = 34944;
	GPIO->GPIO_EN = 1;
	NVIC_CTRL_ADDR = 0xf;
	printWelcome();
	GPIO->GPIO_OUT = 15;
	SD->SD_INTEN = 1;
	ISP->ISP_CTRL_EN = 1;
	setISPnum(dpc, 0);
	setISPnum(bayer, 1);
	setISPnum(wb, 3);
	setISPnum(gamma, 3);
	setISPnum(yuv, 4);
	setISPnum(lap, 7);
	setISPnum(rgb, 8);
	setISPnum(hdr, 8);
	setISPnum(ispL, 4); // output
	setISPnum(ispR, 10); // output
	setISPcoodrd(8, 4);
	while (1)
	{
		delay_ms(1000);
		delay_ms(1000);
		GPIO->GPIO_OUT = 1;
		delay_ms(1000);
		delay_ms(1000);
		//				printf("key value : %d", KEY->KEY_DATA);
		GPIO->GPIO_OUT = 0;
	}
}
