/*
 * USART.c
 *
 * Created: 10/1/2025 8:18:50 PM
 * Author : nanav
 */ 

#include <avr/io.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include "important macros.h"


void UART_Init(unsigned long baud)
{
	// 1. Calculate UBRR for Double Speed mode (8 instead of 16)
	unsigned short ubrr_value = (F_CPU/(8UL*baud)) - 1;
	
	UBRRH = (unsigned char)(ubrr_value >> 8);
	UBRRL = (unsigned char)(ubrr_value);
	
	// 2. Enable Double Speed Mode
	UCSRA |= (1 << U2X);

	// 3. Enable RX and TX
	UCSRB = (1 << RXEN) | (1 << TXEN);
	
	// 4. Set Frame Format (8N1)
	UCSRC = (1 << URSEL) | (1 << UCSZ1) | (1 << UCSZ0);
}


void UART_Send_data(char data)
{
	/*wait for the UDR transmit buffer to be empty*/
	while(READ_BIT(UCSRA,UDRE)==0);
	//put data to udr to transmit buffer
	UDR = data;
}

char UART_Receive_data(void)
{
	while(READ_BIT(UCSRA,RXC)==0);
	return UDR;
}

void UART_Send_string (const char *ptr)
{
	while (*ptr != '\0')
	{
		UART_Send_data(*ptr++);
	}
}