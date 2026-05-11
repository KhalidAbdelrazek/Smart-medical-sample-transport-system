/*
 * Timers.c
 *
 * Created: 9/18/2025 5:51:07 PM
 *  Author: nanav
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include "important macros.h"
#define F_CPU 8000000UL
#include <util/delay.h>

void Timer_CTC_init_interrupt(void)
{
	//select mode
	SET_BIT(TCCR0,WGM01);
	//load value in OCR0
	OCR0 = 80; //when it reaches it 10ms pass
	//select timer clock
	SET_BIT(TCCR0,CS00);
	SET_BIT(TCCR0,CS02);
	//enable interrupt
	sei();
	SET_BIT(TIMSK,OCIE0);
}

void Timer_wave_nonPWM(char value)
{
	SET_BIT(DDRB,3);
	SET_BIT(TCCR0,WGM01);
	
	SET_BIT(TCCR0,CS00);
	SET_BIT(TCCR0,CS02);
	SET_BIT(TCCR0,COM00);
	OCR0=255 - value;
}

void Timer_wave_fastPWM(char value)
{
	SET_BIT(DDRB,3);
	SET_BIT(TCCR0,WGM00);
	SET_BIT(TCCR0,WGM01);
	
	SET_BIT(TCCR0,CS00);
	SET_BIT(TCCR0,CS02);
	//inverting mode
	SET_BIT(TCCR0,COM00);
	SET_BIT(TCCR0,COM01);
	OCR0 =255 - value;
}


void Timer_wave_phasecorrectPWM(void)
{
	/* set OC0 as output pin */
	SET_BIT(DDRB,3);
	// select phase correct PWM mod
	SET_BIT(TCCR0,WGM00);
	/* load a value in OCR0 */
	OCR0=64;
	/* select timer clock */
	SET_BIT(TCCR0,CS00);
	SET_BIT(TCCR0,CS02);
	// Set OC0 on compare match 
	SET_BIT(TCCR0,COM00);
	SET_BIT(TCCR0,COM01);
}


void Timer2_OVF_interrupt_init(void)
{
	//select timer clock
	SET_BIT(ASSR,AS2);
	//select timer pre scalar
	SET_BIT(TCCR2,CS20);
	SET_BIT(TCCR2,CS22);
	//enable interrupt
	sei();
	SET_BIT(TIMSK,TOIE2);
}


short ultrasonic (void)
{
	short a,b,high,distance;
	TCCR1A=0;
	TIFR = (1<<ICF1);
	DIO_Writepin('D',7,1);
	_delay_us(50);
	DIO_Writepin('D',7,0);
	
	TCCR1B = 0xc1;
	while((TIFR&(1<<ICF1)) == 0);
	a = ICR1;
	TIFR = (1<<ICF1);
	TCCR1B = 0x81;
	while((TIFR&(1<<ICF1))==0);
	b =ICR1;
	TIFR = (1<<ICF1);
	TCNT1=0;
	TCCR1B =0;
	high = b-a;
	distance = ((high*34600)/(F_CPU*2));
	return distance;
}


void Timer1_wave_fastPWM(double value)
{
	//set OC1A as output pin
	SET_BIT(DDRD,5);
	//select fast PWM mode 
	SET_BIT(TCCR1A,WGM11);
	SET_BIT(TCCR1B,WGM12);
	SET_BIT(TCCR1B,WGM13);
	OCR1A=value*1000;
	ICR1=19999;
	SET_BIT(TCCR1B,CS10);
	SET_BIT(TCCR1A,COM1A1);
}