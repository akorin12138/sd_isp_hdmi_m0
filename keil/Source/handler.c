#include "code_def.h"
#include "isp.h"
uint32_t flag = 0;
uint32_t picbase = 8448;
uint8_t sd_change = 0;
uint8_t split_change = 0;
uint16_t split_x = 8;

void UARTHandle()
{
	int data, a;
	data = ReadUART();
	printf("Cortex-M0 : ");
	WriteUART(data);
	WriteUART('\n');
}

void KEY0Handler(void)
{
	if (KEY->KEY_DATA == 0)
	{
		flag = ~flag;
		printf("flag:%d,key data: %d\n", flag, KEY->KEY_DATA);
		SD->SD_SHOWEN = flag;
	}
	if (KEY->KEY_DATA == 1)
	{
		getISPstate();
	}
	if (KEY->KEY_DATA == 2)
	{
		if (SD->SD_STATE == 0)
			printf("SD card is busy!\n");
		else
			printf("SD card is idle.\n");
	}
	if (KEY->KEY_DATA == 3)
	{
		sd_change = ~sd_change;
		if (sd_change)
		{
			printf("night\n");
			SD->SD_ADDR = 1516000;
		}
		else
		{
			printf("day\n");
			SD->SD_ADDR = 34944;
		}
	}
	if (KEY->KEY_DATA == 4)
	{
		split_change = ~split_change;
		if (split_change)
		{
			printf("split\n");
			ISP->ISP_CTRL_EN = 1;
		}
		else
		{
			printf("window\n");
			ISP->ISP_CTRL_EN = 0;
		}
	}
	if (KEY->KEY_DATA == 12)
	{
		split_x += 10;
		if (split_x >= 1920)
			split_x = 8;
		else
			setISPcoodrd(split_x, 4);
	}
	if (KEY->KEY_DATA == 13)
	{
		split_x -= 10;
		if (split_x <= 0)
			split_x = 8;
		else
			setISPcoodrd(split_x, 4);
	}

}

void SDHandler(void)
{
	SD->SD_SHOWEN = 0;
	flag = 0;
	printf("read done\n");
}
