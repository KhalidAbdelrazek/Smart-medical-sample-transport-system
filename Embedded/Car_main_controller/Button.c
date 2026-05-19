/*
 * Button driver.c
 *
 * Created: 8/2/2025 11:47:51 PM
 * Author : nanav
 */ 

#include <avr/io.h>
#include "DIO.h"

void Button_Init(char port,char pin)
{
	DIO_Setpindir(port,pin,0);
}

char Button_Read(char port,char pin)
{
	char x ;
	x = DIO_Readpin(port,pin);
	return x;
	
}