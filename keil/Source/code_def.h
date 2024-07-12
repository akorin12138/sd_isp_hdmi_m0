#include <stdint.h>
#ifndef __CODE_DEF_H
#define __CODE_DEF_H
/*----------------------------------------------------------------------------
    Define clocks
 *----------------------------------------------------------------------------*/
#define __XTAL (50000000UL) /* Oscillator frequency             */

#define __SYSTEM_CLOCK (__XTAL)
/*----------------------------------------------------------------------------
    Clock Variable definitions
 *----------------------------------------------------------------------------*/
#define SystemCoreClock (__SYSTEM_CLOCK) /*!< System Clock Frequency (Core Clock)*/

// INTERRUPT DEF /////////////////////////////////////////////////
#define NVIC_CTRL_ADDR (*(volatile unsigned *)0xe000e100)

// SysTick DE /////////////////////////////////////////////////F
typedef struct
{
    volatile uint32_t CTRL;
    volatile uint32_t LOAD;
    volatile uint32_t VALUE;
    volatile uint32_t CALIB;
} SysTickType;

#define SysTick_BASE 0xe000e010
#define SysTick ((SysTickType *)SysTick_BASE)

// RESERVE DEF /////////////////////////////////////////////////

//typedef struct{
//    volatile uint32_t Waterlight_MODE;
//    volatile uint32_t Waterlight_SPEED; 
//}WaterLightType;

//#define WaterLight_BASE 0x40000000
//#define WaterLight ((WaterLightType *)WaterLight_BASE)

typedef struct{
		volatile	uint32_t KEY_DATA;
}KEYType;

#define KEY_BASE 0x40000000
#define KEY ((KEYType *)KEY_BASE)
// UART DEF /////////////////////////////////////////////////
typedef struct{
    volatile uint32_t UARTRX_DATA;
    volatile uint32_t UARTTX_STATE;
    volatile uint32_t UARTTX_DATA;
}UARTType;

#define UART_BASE 0x40010000
#define UART ((UARTType *)UART_BASE)

// GPIO DEF /////////////////////////////////////////////////
typedef struct{
    volatile uint32_t GPIO_OUT;
    volatile uint32_t GPIO_INPUT;
    volatile uint32_t GPIO_EN;
}GPIOType;

#define GPIO_BASE 0x40020000
#define GPIO ((GPIOType *)GPIO_BASE)

// SDcard DEF /////////////////////////////////////////////////
typedef struct{
    volatile uint32_t SD_SHOWEN;
    volatile uint32_t SD_ADDR;
    volatile uint32_t SD_STATE;
		volatile uint32_t SD_INTEN;
}SDType;

#define SD_BASE 0x40030000
#define SD ((SDType *)SD_BASE)

// ISP DEF /////////////////////////////////////////////////
typedef struct{
    volatile uint32_t ISP_DATA_NUM0to7;
    volatile uint32_t ISP_DATA_NUM8to15;
	volatile uint32_t ISP_CTRL_EN;
	volatile uint32_t ISP_WIN_COORD;        //分屏起始坐标
}ISPType;

#define ISP_BASE 0x40040000
#define ISP ((ISPType *)ISP_BASE)

/**********************************************************/
/*					 							Header							 						*/
/**********************************************************/

void delay_ms(int ms);
void delay_us(int us);
char ReadUARTState(void);
char ReadUART(void);
void WriteUART(char data);
void UARTString(char *stri);
void UARTHandle(void);
void printWelcome();


#endif