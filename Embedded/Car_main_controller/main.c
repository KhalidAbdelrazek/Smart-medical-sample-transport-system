/*
 * main.c
 *
 * Created: 3/1/2026
 * Author : NADER
 *
 * Fix: 's' is sent ONCE from main.c only, after motors settle.
 *      Decide_Movement() no longer sends 's' – it just stops.
 *
 * Commands 1 / 2 / 3:
 *   '1' – move backward, stop at the 1st black line  (skip 0)
 *   '2' – move backward, stop at the 2nd black line  (skip 1)
 *   '3' – move backward, stop at the 3rd black line  (skip 2)
 *
 *   Each black line is crossed by calling Push_Backward() for a short
 *   burst (~120 ms) so the car clears the ~2 cm stripe, then resumes
 *   Back_Decide_Movement() until the next line (or the target line).
 *   Sends "s\r\n" once motors have stopped at the target line.
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
    for (int i = 0; i < 8; i++)
    {
        DIO_Setpindir('A', i, 1);
    }

    // -------- IR Sensor Pins Init (Port D, pins 5 & 6) --------
    Button_Init('D', 3);
    Button_Init('D', 4);

    // -------- Status LED --------
    LED_Init('C', 0);
    LED_Init('C', 7);
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

        // ── FORWARD ──────────────────────────────────────────
        if (Commands == 'F')
        {
            UART_Send_string("OK:F\r\n");

            while (1)
            {
                if (Push_Forward())
                {
                    Stop();
                    break;
                }
            }

            _delay_ms(50);

            while (1)
            {
                char Left_IR = Button_Read('D', 3);
                char Right_IR = Button_Read('D', 4);

                if (Left_IR == 1 && Right_IR == 1)
                {
                    Stop();
                    _delay_ms(50);
                    UART_Send_string("s\r\n");
                    break;
                }
                Decide_Movement();
            }
        }

        // ── BACKWARD ─────────────────────────────────────────
        else if (Commands == 'B')
        {
            UART_Send_string("OK:B\r\n");

            while (1)
            {
                if (Push_Backward())
                {
                    Stop();
                    break;
                }
            }
            _delay_ms(50);

            while (1)
            {
                char Left_IR = Button_Read('D', 3);
                char Right_IR = Button_Read('D', 4);
                // char Left_IR_B = Button_Read('D', 5);
                // char Right_IR_B = Button_Read('D', 6);

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

        // ── POSITIVE ROTATE ──────────────────────────────────
        else if (Commands == 'P')
        {
            UART_Send_string("OK:P\r\n");
            while (1)
            {
                Commands = UART_Receive_data();
                if (Commands == 'F')
                {
                    UART_Send_string("OK:F\r\n");
                    while (1)
                    {
                        if (Push_Forward())
                        {
                            Stop();
                            break;
                        }
                    }
                    _delay_ms(50);

                    while (1)
                    {
                        char Left_IR = Button_Read('D', 3);
                        char Right_IR = Button_Read('D', 4);

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

                    while (1)
                    {
                        if (Push_Backward())
                        {
                            Stop();
                            break;
                        }
                    }
                    _delay_ms(50);

                    while (1)
                    {
                        char Left_IR = Button_Read('D', 3);
                        char Right_IR = Button_Read('D', 4);
                        // char Left_IR_B = Button_Read('D', 5);
                        // char Right_IR_B = Button_Read('D', 6);

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
                else if (Commands == 'S')
                {
                    Stop();
                    _delay_ms(50);
                    UART_Send_string("OK:S\r\n");
                    break;
                }
                Move_Right();
            }
        }

        // ── NEGATIVE ROTATE ──────────────────────────────────
        else if (Commands == 'N')
        {
            UART_Send_string("OK:N\r\n");
            while (1)
            {
                Commands = UART_Receive_data();
                if (Commands == 'F')
                {
                    UART_Send_string("OK:F\r\n");
                    while (1)
                    {
                        if (Push_Forward())
                        {
                            Stop();
                            break;
                        }
                    }
                    _delay_ms(50);
                    // int counter = 1;

                    while (1)
                    {
                        // if (counter == 1)
                        // {
                        //     while (1)
                        //     {
                        //         if (Push_Forward())
                        //             break;
                        //     }
                        //     counter = 0;
                        // }
                        char Left_IR = Button_Read('D', 3);
                        char Right_IR = Button_Read('D', 4);

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
                    while (1)
                    {
                        if (Push_Backward())
                        {
                            Stop();
                            break;
                        }
                    }
                    _delay_ms(50);

                    while (1)
                    {
                        char Left_IR = Button_Read('D', 3);
                        char Right_IR = Button_Read('D', 4);
                        // char Left_IR_B = Button_Read('D', 5);
                        // char Right_IR_B = Button_Read('D', 6);

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
                else if (Commands == 'S')
                {
                    Stop();
                    _delay_ms(50);
                    UART_Send_string("OK:S\r\n");
                    break;
                }
                Move_Left();
            }
        }

        // ── STOP ─────────────────────────────────────────────
        else if (Commands == 'S')
        {
            UART_Send_string("OK:S\r\n");
            Stop();
        }

        // ── IGNORE newline / carriage-return ─────────────────
        else if (Commands == '\n' || Commands == '\r')
        {
            continue;
        }

        // ── SKIP-LINE BACKWARD COMMANDS (1 / 2 / 3) ─────────
        //
        //  linesToSkip = command digit - 1
        //  The car moves backward using Back_Decide_Movement().
        //  Every time BOTH IR sensors detect BLACK (intersection):
        //    • If lines_skipped < linesToSkip  →  push through the line
        //      (Push_Backward for ~120 ms to clear the ~2 cm stripe)
        //      then wait until the sensors leave the black line,
        //      then increment lines_skipped and keep going.
        //    • If lines_skipped == linesToSkip  →  this is the target line,
        //      stop and send "s\r\n".
        //
        else if (Commands == '1' || Commands == '2' || Commands == '3')
        {
            int linesToSkip = 0;
            if (Commands == '1')
            {
                linesToSkip = 0;
            }
            else if (Commands == '2')
            {
                linesToSkip = 1;
            }
            else if (Commands == '3')
            {
                linesToSkip = 2;
            }
            // Number of lines to SKIP before stopping
            // int linesToSkip = (Commands - '0') - 1;  // '1'->0, '2'->1, '3'->2
            int lines_skipped = 0;

            // Debug acknowledgement
            if (Commands == '1')
                UART_Send_string("OK:1\r\n");
            else if (Commands == '2')
                UART_Send_string("OK:2\r\n");
            else
                UART_Send_string("OK:3\r\n");

            // Small initial push to get off any current intersection
            while (1)
            {
                if (Push_Backward())
                    break;
            }

            _delay_ms(50);

            while (1)
            {
                char Left_IR = Button_Read('D', 3);
                char Right_IR = Button_Read('D', 4);
                char Left_IR_B = Button_Read('D', 5);
                char Right_IR_B = Button_Read('D', 6);

                if (Left_IR == 1 && Right_IR == 1)
                {
                    // ── Black line detected ───────────────────
                    if (lines_skipped < linesToSkip)
                    {
                        // Push through this line (~120 ms clears 2 cm stripe)
                        while (1)
                        {
                            if (Push_Backward())
                                break;
                        }

                        // Wait until both sensors leave the black line
                        // while (1)
                        // {
                        //     char L = Button_Read('D', 3);
                        //     char R = Button_Read('D', 4);
                        //     if (L != 1 || R != 1) break;   // off the line
                        //     Push_Backward();                // keep pushing
                        //     _delay_ms(10);
                        // }

                        lines_skipped++;
                        // Continue backward line-following
                    }
                    else
                    {
                        // ── Target line reached – stop ────────
                        Stop();
                        _delay_ms(50);
                        UART_Send_string("s\r\n");
                        break;
                    }
                }
                else
                {
                    // Normal backward line-following
                    Back_Decide_Movement();
                }
            }
        }

        // ── BUZZER TEST ─────────────────────────────────────────
        else if (Commands == 'X')
        {
            UART_Send_string("OK:K\r\n");
            LED_On('C', 7);
            _delay_ms(2000);
            LED_Off('C', 7);
        }
		/*
		else if (Commands == 'O')
		{
			UART_Send_string("OK:O\r\n");

			while (1)
			{
				if (Push_Backward())
				{
					Stop();
					break;
				}
			}
			_delay_ms(50);

			while (1)
			{
				char Left_IR = Button_Read('D', 3);
				char Right_IR = Button_Read('D', 4);
				char Left_IR_B = Button_Read('D', 5);
				char Right_IR_B = Button_Read('D', 6);

				if (Left_IR == 1 && Right_IR == 1)
				{
					Stop();
					_delay_ms(50);
					UART_Send_string("s\r\n");
					break;
				}
				Back_Decide_Movement_noIR();
			}
		}
		*/
    }
}