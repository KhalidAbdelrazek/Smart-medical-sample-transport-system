/*
 * main_movement.c
 *
 * Created: 3/1/2026 3:56:08 PM
 *  Author: NADER
 
 */ 

#include "Timers.h"
char Left_wheels = 55;
char  mid = 80;
char Right_wheels = 150;
int Move_Up(void)
{
	DIO_Writepin('A',0,0);
	DIO_Writepin('A',1,1);
	DIO_Writepin('A',2,0);
	DIO_Writepin('A',3,1);
	DIO_Writepin('A',4,0);
	DIO_Writepin('A',5,1);
	DIO_Writepin('A',6,0);
	DIO_Writepin('A',7,1);
	Timer_wave_fastPWM(Left_wheels);
	// Timer2_wave_fastPWM(Left_wheels);
}

int Move_Down(void)
{
	DIO_Writepin('A',0,1);
	DIO_Writepin('A',1,0);
	DIO_Writepin('A',2,1);
	DIO_Writepin('A',3,0);
	DIO_Writepin('A',4,1);
	DIO_Writepin('A',5,0);
	DIO_Writepin('A',6,1);
	DIO_Writepin('A',7,0);
	Timer_wave_fastPWM(Left_wheels);
	// Timer2_wave_fastPWM(Left_wheels);
}

int Move_Right(void)
{
	DIO_Writepin('A',0,0);
	DIO_Writepin('A',1,1);
	DIO_Writepin('A',2,0);
	DIO_Writepin('A',3,1);
	DIO_Writepin('A',4,1);
	DIO_Writepin('A',5,0);
	DIO_Writepin('A',6,1);
	DIO_Writepin('A',7,0);
	Timer_wave_fastPWM(Right_wheels);
	// Timer2_wave_fastPWM(Right_wheels);
}

int Move_Left(void)
{
	DIO_Writepin('A',0,1);
	DIO_Writepin('A',1,0);
	DIO_Writepin('A',2,1);
	DIO_Writepin('A',3,0);
	DIO_Writepin('A',4,0);
	DIO_Writepin('A',5,1);
	DIO_Writepin('A',6,0);
	DIO_Writepin('A',7,1);
	Timer_wave_fastPWM(Right_wheels);
	// Timer2_wave_fastPWM(Right_wheels);
}

int Move_Left_correction(void)
{
	DIO_Writepin('A',0,0);
	DIO_Writepin('A',1,1);
	DIO_Writepin('A',2,0);
	DIO_Writepin('A',3,1);
	DIO_Writepin('A',4,0);
	DIO_Writepin('A',5,1);
	DIO_Writepin('A',6,0);
	DIO_Writepin('A',7,1);
	Timer_wave_fastPWM(mid);
	// Timer2_wave_fastPWM(Left_wheels);
}

int move_Right_correction(void)
{
	DIO_Writepin('A',0,1);
	DIO_Writepin('A',1,0);
	DIO_Writepin('A',2,1);
	DIO_Writepin('A',3,0);
	DIO_Writepin('A',4,1);
	DIO_Writepin('A',5,0);
	DIO_Writepin('A',6,1);
	DIO_Writepin('A',7,0);
	Timer_wave_fastPWM(Left_wheels);
	// Timer2_wave_fastPWM(mid);
}

int Stop(void)
{
	DIO_Writepin('A',0,0);
	DIO_Writepin('A',1,0);
	DIO_Writepin('A',2,0);
	DIO_Writepin('A',3,0);
	DIO_Writepin('A',4,0);
	DIO_Writepin('A',5,0);
	DIO_Writepin('A',6,0);
	DIO_Writepin('A',7,0);
	Timer_wave_fastPWM(0);
	// Timer2_wave_fastPWM(0);
}

