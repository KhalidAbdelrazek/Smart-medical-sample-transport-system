/*
 * Interrupts.c
 *
 * Created: 12/4/2025 2:27:47 AM
 *  Author: nanav
 */ 
#include <avr/io.h>
#include <avr/interrupt.h>
#include "important macros.h"
#define F_CPU 8000000UL
#include <util/delay.h>

void INT0_init(void) 
{
	// 1. Configure the interrupt pin (PD2) as an input
	DDRD &= ~ (1 << 3);
	// Enable the internal pull-up resistor for PD2
	PORTD |= (1 << 3);

	// 2. Configure INT0 to trigger on a falling edge
	// This is done by setting the ISC01 bit in MCUCR
	// and clearing the ISC00 bit
	MCUCR |= (1 << ISC01);
	MCUCR &= ~ (1 << ISC00);

	// 3. Enable external interrupt INT0
	// This is done by setting the INT0 bit in GICR
	GICR |= (1 << INT0);

	// 4. Enable global interrupts
	sei();
}


void INT1_init(void) 
{
	DDRD &= ~ (1 << 4);
	PORTD |= (1 << 4);
	// 1. Enable the interrupt
	GICR |= (1 << INT1);

	// 2. Set trigger mode (Example: falling edge)
	MCUCR |= (1 << ISC11);
	MCUCR &= ~(1 << ISC10);

	// 3. Enable global interrupts
	sei();
}
