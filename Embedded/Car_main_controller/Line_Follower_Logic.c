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
#include "USART.h"

char Left_IR;
char Right_IR;
char Left_IR_B;
char Right_IR_B;

// In Line_Follower_Logic.c
int Decide_Movement()
{

	Left_IR = Button_Read('D', 3);
	Right_IR = Button_Read('D', 4);

	if (Left_IR == 1 && Right_IR == 0)
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
		// ? DO NOT send 's' here � let main.c handle it ONCE
	}
	else if (Left_IR == 0 && Right_IR == 0)
	{
		Move_Up();
	}

	return (Left_IR == 1 && Right_IR == 1) ? 1 : 0; // return 1 if intersection
}

int Back_Decide_Movement()
{
    Left_IR    = Button_Read('D', 3);
    Right_IR   = Button_Read('D', 4);
    Left_IR_B  = Button_Read('D', 5);
    Right_IR_B = Button_Read('D', 6);

    if (Left_IR == 1 && Right_IR == 1)          // front intersection → stop
    {
        Stop();
    }
    else if (Left_IR_B == 1 && Right_IR_B == 1) // both back on line → straight back
    {
        Move_Down();
    }
    else if (Left_IR_B == 1 && Right_IR_B == 0) // line left → steer left
    {
        Move_Left();
    }
    else if (Left_IR_B == 0 && Right_IR_B == 1) // line right → steer right
    {
        Move_Right();
    }
    else                                          // both white → straight back
    {
        Move_Down();
    }

    return (Left_IR == 1 && Right_IR == 1) ? 1 : 0;
}

int Push_Forward(void)
{
    Left_IR   = Button_Read('D', 3);
    Right_IR  = Button_Read('D', 4);
    Left_IR_B = Button_Read('D', 5);
    Right_IR_B = Button_Read('D', 6);

    // Back IRs hit the line → we've pushed far enough, stop
    if (Left_IR_B == 1 && Right_IR_B == 1)
    {
        Stop();
        return 1;
    }
    // Front IRs on line → keep pushing through it
    else if (Left_IR == 1 && Right_IR == 1)
    {
        Move_Up();
    }
    else if (Left_IR == 1 && Right_IR == 0)
    {
        Move_Left();
    }
    else if (Left_IR == 0 && Right_IR == 1)
    {
        Move_Right();
    }
    else // both white → move forward
    {
        Move_Up();
    }
    return 0;
}

int Push_Backward(void)
{
    Left_IR   = Button_Read('D', 3);
    Right_IR  = Button_Read('D', 4);
    Left_IR_B = Button_Read('D', 5);
    Right_IR_B = Button_Read('D', 6);

    // Front IRs now white → we've pushed clear of the line
    if (Left_IR == 0 && Right_IR == 0)
    {
        return 1;
    }
    // Front IRs still on black → keep pushing backward through it
    else if (Left_IR == 1 && Right_IR == 1)
    {
        Move_Down();
    }
    else if (Left_IR_B == 1 && Right_IR_B == 0)
    {
        Move_Right();
    }
    else if (Left_IR_B == 0 && Right_IR_B == 1)
    {
        Move_Left();
    }
    else
    {
        Move_Down();
    }
    return 0;
}


int Back_Decide_Movement_noIR()
{

	Left_IR   = Button_Read('D', 3);
	Right_IR  = Button_Read('D', 4);
	// Conditions are SAME as forward, but movements are mirrored
	if (Left_IR == 1 && Right_IR == 0) // line is on the left
	{
		Move_Right(); // steer left while reversing
	}
	else if (Left_IR == 0 && Right_IR == 1) // line is on the right
	{
		Move_Left(); // steer right while reversing
	}
	else if (Left_IR == 1 && Right_IR == 1) // intersection
	{
		Stop();
	}
	else if (Left_IR == 0 && Right_IR == 0) // on track
	{
		Move_Down(); // keep reversing
	}

	return (Left_IR == 1 && Right_IR == 1) ? 1 : 0;
}
