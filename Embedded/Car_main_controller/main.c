/*
 * main.c
 *
 * Created: 3/1/2026
 * Author : NADER
 *
 * Fix: 's' is sent ONCE from main.c only, after motors settle.
 *      Decide_Movement() no longer sends 's' � it just stops.
 */

#include <xc.h>
#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 8000000UL
#include <util/delay.h>
#include <stdio.h>

#include "DIO.h"
#include "Timers.h"
#include "Interrupts.h"
#include "LED.h"
#include "main_movement.h"
#include "Button.h"
#include "USART.h"

// =========================
// Main Function
// =========================
int main(void)
{
    // -------- Motor Pins Init (Port A) --------
    for (int i = 0; i < 8; i++) {
        DIO_Setpindir('A', i, 1);
    }

    // -------- IR Sensor Pins Init (Port D, pins 5 & 6) --------
    Button_Init('D', 5);
    Button_Init('D', 6);

    // -------- Status LED --------
    LED_Init('C', 0);
    LED_On('C', 0);
    _delay_ms(1000);
    LED_Off('C', 0);

    // -------- UART Init --------
    UART_Init(9600);
    UART_Send_string("[DEBUG] UART Initialized @9600\r\n");

    char Commands;

    // -------- Main Loop --------
    while (1)
    {
        Commands = UART_Receive_data();

        // ?? FORWARD ??????????????????????????????????????????
        if (Commands == 'F')
        {
            UART_Send_string("OK:F\r\n");

            // Small push to clear the previous intersection before line-following
            Push_Forward();
            _delay_ms(50);

            // Line-follow until BOTH IR sensors read BLACK (intersection)
            while (1)
            {
                char Left_IR  = Button_Read('D', 5);
                char Right_IR = Button_Read('D', 6);

                if (Left_IR == 1 && Right_IR == 1)
                {
                    // Intersection detected � stop motors
                    Stop();
                    _delay_ms(50);          // let motors fully settle before sending

                    // Send stop signal to RPi ONCE
                    UART_Send_string("s\r\n");

                    break;                  // exit line-follow loop, wait for next command
                }
			Decide_Movement();
            }
        }

        // ?? BACKWARD ?????????????????????????????????????????
        else if (Commands == 'B')
        {
            UART_Send_string("OK:B\r\n");

            Push_Backward();
            _delay_ms(50);

            while (1)
            {
                char Left_IR  = Button_Read('D', 5);
                char Right_IR = Button_Read('D', 6);

                if (Left_IR == 1 && Right_IR == 1)
                {
                    Stop();
                    _delay_ms(50);
                    UART_Send_string("s\r\n");
                    break;
                }
			Back_Decide_Movement();
            }
        }

        // ?? POSITIVE ROTATE ??????????????????????????????????
        else if (Commands == 'P')
        {
            UART_Send_string("OK:P\r\n");
            while (1)
			{
				
				Commands = UART_Receive_data();
				if (Commands == 'S')
				{
					Stop();
					_delay_ms(50);
					
					break;
				}
                Move_Right();
			}
            
        }

        // ?? NEGATIVE ROTATE ??????????????????????????????????
        else if (Commands == 'N')
        {
            UART_Send_string("OK:N\r\n");
             while (1)
             {
	            
	             Commands = UART_Receive_data();
	             if (Commands == 'F')
	             {
					 UART_Send_string("OK:F\r\n");
		             while(1)
					 {
                        char Left_IR  = Button_Read('D', 5);
                        char Right_IR = Button_Read('D', 6);

                        if (Left_IR == 1 && Right_IR == 1)
                        {
                            Stop();
                            _delay_ms(50);
                            UART_Send_string("s\r\n");
                            break;
                        }
                        Decide_Movement();
                     }
					 break;
	             } 
				 else if (Commands == 'B') 
				 {
					 UART_Send_string("OK:B\r\n");
                        while(1)
						{
                            char Left_IR  = Button_Read('D', 5);
                            char Right_IR = Button_Read('D', 6);

                            if (Left_IR == 1 && Right_IR == 1)
                            {
                                Stop();
                                _delay_ms(50);
                                UART_Send_string("s\r\n");
                                break;
                             }
                                Back_Decide_Movement();
                        }
						break;
	             }
                 Move_Left();
             }
            
        }

        // ?? STOP ?????????????????????????????????????????????
        else if (Commands == 'S')
        {
            UART_Send_string("OK:S\r\n");
            Stop();
        }

        // ?? IGNORE newline / carriage-return ?????????????????
        else if (Commands == '\n' || Commands == '\r')
        {
            continue;
        }
    }
}