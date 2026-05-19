#include <avr/io.h>
#include "important macros.h"

void DIO_Setpindir(char port,char pin,char dir)
{
	switch(port)
	{
		case 'A':
		case 'a':
		if(dir==1)
		{
			DDRA |=(1<<pin);
		}
		else
		{
			DDRA &=~(1<<pin);
		}
		break;
		case 'B':
		case 'b':
		if(dir==1)
		{
			DDRB |=(1<<pin);
		}
		else
		{
			DDRB &=~(1<<pin);
		}
		break;
		case 'C':
		case 'c':
		if(dir==1)
		{
			DDRC |=(1<<pin);
		}
		else
		{
			DDRC &=~(1<<pin);
		}
		break;
		case 'D':
		case 'd':
		if(dir==1)
		{
			DDRD |=(1<<pin);
		}
		else
		{
			DDRD &=~(1<<pin);
		}
		break;
		default:
		break;
	}
}




 void DIO_Writepin(char port,char pin , char val)
{
	switch(port)
	{
		case 'A':
		case 'a':
		if (val==1)
		{
			SET_BIT(PORTA,pin);
		}
		else
		{
			CLR_BIT(PORTA,pin);
		}
		break;
		case 'B':
		case 'b':
		if (val==1)
		{
			SET_BIT(PORTB,pin);
		}
		else
		{
			CLR_BIT(PORTB,pin);
		}
		break;
		case 'C':
		case 'c':
		if (val==1)
		{
			SET_BIT(PORTC,pin);
		}
		else
		{
			CLR_BIT(PORTC,pin);
		}
		break;
		case 'D':
		case 'd':
		if (val==1)
		{
			SET_BIT(PORTD,pin);
		}
		else
		{
			CLR_BIT(PORTD,pin);
		}
		break;
		
		
	}
	
	
}


void DIO_Togglepin(char port,char pin)
{
	switch(port)
	{
		case 'A':
		case 'a':
		TOG_BIT(PORTA,pin);
		break;
		case 'B':
		case 'b':
		TOG_BIT(PORTB,pin);
		break;
		case 'C':
		case 'c':
		TOG_BIT(PORTC,pin);
		break;
		case 'D':
		case 'd':
		TOG_BIT(PORTD,pin);
		break;
	}
}


char DIO_Readpin(char port,char pin)
{
	unsigned char val;
	switch(port)
	{
		case 'A':
		case 'a':
		val = READ_BIT(PINA,pin);
		break;
		case 'B':
		case 'b':
		val = READ_BIT(PINB,pin);
		break;
		case 'C':
		case 'c':
		val = READ_BIT(PINC,pin);
		break;
		case 'D':
		case 'd':
		val = READ_BIT(PIND,pin);
		break;
	}
	return val;
}


void DIO_Setportdir(char port,char dir)
{
	switch(port)
	{
		case 'A':
		case 'a':
		DDRA = dir;
		break;
		case 'B':
		case 'b':
		DDRB = dir;
		break;
		case 'C':
		case 'c':
		DDRC = dir;
		break;
		case 'D':
		case 'd':
		DDRD = dir;
		break;
	}
}


void DIO_Writeport(char port,char val)
{
	switch(port)
	{
		
		case 'A':
		case 'a':
		PORTA = val;
		break;
		case 'B':
		case 'b':
		PORTB = val;
		break;
		case 'C':
		case 'c':
		PORTC = val;
		break;
		case 'D':
		case 'd':
		PORTD = val;
		break;
	}
}

 char DIO_Readport(char  port)
{
	char return_val;
	switch(port)
	{
		case  'A':
		case  'a':
		return_val = PINA;
		break;
		case  'B':
		case  'b':
		return_val = PINB;
		break;
		case  'C':
		case  'c':
		return_val = PINC;
		break;
		case  'D':
		case  'd':
		return_val = PIND;
		break;
	}
	return return_val;
}

void DIO_Toggleport(char port)
{
	switch(port)
	{
		case 'A':
		case 'a':
		PORTA = PORTA^0xff;
		break;
		case 'B':
		case 'b':
		PORTB = PORTB^0xff;
		break;
		case 'C':
		case 'c':
		PORTC = PORTC^0xff;
		break;
		case 'D':
		case 'd':
		PORTD = PORTD^0xff;
		break;
	}
}


void DIO_Connectpullup(char port,char pin,char connect)
{
	switch(port)
	{
		case 'A':
		case 'a':
		if (connect == 1)
		{
			DIO_Writepin(port,pin,1);
		}
		else
		{
			DIO_Writepin(port,pin,0);
		}
		case 'B':
		case 'b':
		if (connect == 1)
		{
			DIO_Writepin(port,pin,1);
		}
		else
		{
			DIO_Writepin(port,pin,0);
		}
		case 'C':
		case 'c':
		if (connect == 1)
		{
			DIO_Writepin(port,pin,1);
		}
		else
		{
			DIO_Writepin(port,pin,0);
		}
		case 'D':
		case 'd':
		if (connect == 1)
		{
			DIO_Writepin(port,pin,1);
		}
		else
		{
			DIO_Writepin(port,pin,0);
		}
	}
}


void DIO_Writelownibble(unsigned char portname,unsigned char value)
{
	value&=0x0f;
	switch(portname)
	{
		case 'A':
		PORTA&=0xf0;
		PORTA|=value;
		break;
		case 'B':
		PORTB&=0xf0;
		PORTB|=value;
		break;
		case 'C':
		PORTC&=0xf0;
		PORTC|=value;
		break;
		case 'D':
		PORTD&=0xf0;
		PORTD|=value;
		break;
	}
}

void DIO_Writehighnibble(unsigned char portname,unsigned char value)
{
	value<<=4;
	switch(portname)
	{
		case 'A':
		PORTA&=0x0f;
		PORTA|=value;
		break;
		case 'B':
		PORTB&=0x0f;
		PORTB|=value;
		break;
		case 'C':
		PORTC&=0x0f;
		PORTC|=value;
		break;
		case 'D':
		PORTD&=0x0f;
		PORTD|=value;
		break;
	}
}