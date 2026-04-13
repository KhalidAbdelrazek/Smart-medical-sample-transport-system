/*
 * main_movement.c
 *
 * Created: 3/1/2026 3:56:08 PM
 *  Author: NADER
 */ 



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
}