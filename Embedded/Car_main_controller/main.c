/*
 * main.c
 *
 * Created: 3/1/2026 3:44:39 PM
 *  Author: NADER
 */ 

#include <xc.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include "DIO.h"
#include "Timers.h"
#include "Interrupts.h"
#include "LED.h"
#include "main_movement.h"
#include "Button.h"

int main(void)
{
   /*
   OSCCAL += 10;
   MCUCSR |= (1 << JTD);
   MCUCSR |= (1 << JTD);
   char x;
   _delay_ms(500);
   UART_Init(1200);
   */
   
   DIO_Setpindir('A',0,1);
   DIO_Setpindir('A',1,1);
   DIO_Setpindir('A',2,1);
   DIO_Setpindir('A',3,1);
   DIO_Setpindir('A',4,1);
   DIO_Setpindir('A',5,1);
   DIO_Setpindir('A',6,1);
   DIO_Setpindir('A',7,1);
   LED_Init('D',7);
   LED_On('D',7);
   _delay_ms(1000);
   LED_Off('D',7);
   Button_Init('D',6);
   
   
    while(1)
    {
		if (Button_Read('D',6) == 1)
		{
			Move_Up();
		}
    }
}