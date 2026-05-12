/*
 * Line_Follower_Logic.c
 *
 * Created: 5/12/2026 1:54:33 PM
 *  Author: NADER
 */ 

#include "Button.h"
#include "main_movement.h"
#define F_CPU 8000000UL
#include <util/delay.h>

int Decide_Movement()
{
	char Left_IR;
	char Right_IR;
	Button_Init('D',5);
	Button_Init('D',6);
	Left_IR = Button_Read('D',5);
	Right_IR = Button_Read('D',6);
	if (Left_IR == 1 && Right_IR == 0 )
	{
		Move_Left();
	}
	else if (Left_IR == 0 && Right_IR == 1)
	{
		Move_Right();
	}
	else if (Left_IR == 1 && Right_IR == 1)
	{
		Stop();
	}
	else if (Left_IR == 0 && Right_IR == 0)
	{
		Move_Up();
	}
}

int Back_Decide_Movement()
{
	char Left_IR;
	char Right_IR;
	Button_Init('D',5);
	Button_Init('D',6);
	Left_IR = Button_Read('D',5);
	Right_IR = Button_Read('D',6);
	if (Left_IR == 1 && Right_IR == 0 )
	{
		Move_Right();
	}
	else if (Left_IR == 0 && Right_IR == 1)
	{
		Move_Left();
	}
	else if (Left_IR == 1 && Right_IR == 1)
	{
		Stop();
	}
	else if (Left_IR == 0 && Right_IR == 0)
	{
		Move_Down();
	}
}

int Push_Forward(void)
{
	Move_Up();
	_delay_ms(500);
	Stop();
	_delay_ms(250);
}


int Push_Backward(void)
{
	Move_Down();
	_delay_ms(250);
	Stop();
	_delay_ms(250);
}

int Pve_Rotate(char pve_state)
{
	if(pve_state == 1)
	{
		Move_Right();
	}
	else
	{
		Stop();
	}
}

int Nve_Rotate(char nve_state)
{
	if(nve_state == 1)
	{
		Move_Left();
	}
	else
	{
		Stop();
	}
}

