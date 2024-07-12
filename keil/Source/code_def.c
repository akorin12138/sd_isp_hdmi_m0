#include "code_def.h"
#include <string.h>
#include <stdio.h>
char ReadUARTState(){
    char state;
    state = UART->UARTTX_STATE;
    return (state);
}

char ReadUART(){
    char data;
    data = UART->UARTRX_DATA;
    return (data);
}

void WriteUART(char data){
    while (ReadUARTState());
    UART->UARTTX_DATA = data;
}

void UARTString(char *stri){
    int i;
    for (i = 0; i < strlen(stri); i++)
    {
        WriteUART(stri[i]);
    }
}

int fputc(int ch, FILE *f) {
  if(ch == '\n') WriteUART('\r');
  WriteUART(ch);
  return (ch);
}

int fgetc(FILE *f) {
  char buf;
  buf = ReadUART();
  WriteUART(buf);
  if(buf == '\r') buf = '\n';
  return (buf);
}
int ferror(FILE *f) {
  /* Your implementation of ferror */
  return EOF;
}
void _ttywrch(int ch) {
  WriteUART(ch);
}
void printWelcome(){
	printf(" $$$$$$\\                        $$\\                         $$\\      $$\\  $$$$$$\\   \n");
		printf("$$  __$$\\                       $$ |                        $$$\\    $$$ |$$$ __$$\\   \n");
		printf("$$ /  \\__| $$$$$$\\   $$$$$$\\  $$$$$$\\    $$$$$$\\  $$\\   $$\\ $$$$\\  $$$$ |$$$$\\ $$ |  \n");
		printf("$$ |      $$  __$$\\ $$  __$$\\ \\_$$  _|  $$  __$$\\ \\$$\\ $$  |$$\\$$\\$$ $$ |$$\\$$\\$$ |  \n");
		printf("$$ |      $$ /  $$ |$$ |  \\__|  $$ |    $$$$$$$$ | \\$$$$  / $$ \\$$$  $$ |$$ \\$$$$ |  \n");
		printf("$$ |  $$\\ $$ |  $$ |$$ |        $$ |$$\\ $$   ____| $$  $$<  $$ |\\$  /$$ |$$ |\\$$$ |  \n");
		printf("\\$$$$$$  |\\$$$$$$  |$$ |        \\$$$$  |\\$$$$$$$\\ $$  /\\$$\\ $$ | \\_/ $$ |\\$$$$$$  /  \n");
		printf(" \\______/  \\______/ \\__|         \\____/  \\_______|\\__/  \\__|\\__|     \\__| \\______/   \n");
}
//延迟us
void delay_us(int us){
    uint32_t temp;
    SysTick->LOAD = us * (SystemCoreClock/1000000UL);
    SysTick->VALUE = 0x00; 
    SysTick->CTRL = 0x05;  
    do
    {
        temp = SysTick->CTRL;
    } while ((temp & 0x01) && !(temp & (1 << 16)));
    SysTick->CTRL = 0x00; 
    SysTick->VALUE = 0x00;
}
//延迟ms
void delay_ms(int ms) {
    uint32_t temp;
    SysTick->LOAD = ms * (SystemCoreClock/1000UL);
    SysTick->VALUE = 0x00; 
    SysTick->CTRL = 0x05;  
    do{
        temp = SysTick->CTRL;
    } while ((temp & 0x01) && !(temp & (1 << 16)));
    SysTick->CTRL = 0x00; 
    SysTick->VALUE = 0x00;
}


