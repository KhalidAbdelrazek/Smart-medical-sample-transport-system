#include "DIO.h"

void LED_Init(char port , char pin)
{
	DIO_Setpindir(port,pin,1);
}

void LED_On(char port, char pin)
{
	DIO_Writepin(port,pin,1);
}

void LED_Off(char port, char pin)
{
	DIO_Writepin(port,pin,0);
}

void LED_Toggle(char port,char pin)
{
	DIO_Togglepin(port,pin);
}

char LED_Readstatus(char port,char pin)
{
	return DIO_Readpin(port,pin);
}