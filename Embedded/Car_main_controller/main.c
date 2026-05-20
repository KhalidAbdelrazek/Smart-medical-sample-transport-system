/*
 * main.c
 *
 * PROFESSIONAL REDESIGN — v2.0
 * Author: NADER (refactored)
 *
 * What changed vs v1.x:
 *
 *  1. SENSOR READS IN MAIN LOOP replaced by Decide_Movement() return value.
 *     main.c no longer needs to re-read sensors after calling Decide_Movement()
 *     because the function returns 1 on confirmed intersection.  This avoids
 *     double-reading and timing inconsistency.
 *
 *  2. Push_Forward() NO LONGER BLOCKS 500 ms.  It now starts motion for
 *     80 ms (clears the starting intersection) and returns.  The feedback
 *     loop in Decide_Movement() takes over immediately.
 *
 *  3. 'N' handler — the original had a redundant `counter` variable that
 *     called Push_Forward() twice.  Removed.
 *
 *  4. '1'/'2'/'3' handler — replaced inline Push_Backward + manual wait
 *     loops with Cross_Intersection_Backward() which handles timeout
 *     safety and sensor debouncing internally.
 *
 *  5. All _delay_ms() settling pauses trimmed to minimum safe values.
 *     50 ms is kept where motor coast-down matters; removed elsewhere.
 *
 *  6. UART receive loop at top now skips '\r' as well as '\n'.
 *
 *  7. All Stop() calls before UART sends are kept to ensure motors
 *     are off before RPi acts on the 's' signal.
 *
 * Protocol — UNCHANGED (compatible with rpi_main.py v1.10):
 *   'F' → forward line-follow until intersection, send 's'
 *   'B' → backward line-follow until intersection, send 's'
 *   'P' → positive rotate, wait for 'F'/'B'/'S', then resume
 *   'N' → negative rotate, wait for 'F'/'B'/'S', then resume
 *   'S' → stop immediately
 *   '1' → backward, stop at 1st line  (skip 0)
 *   '2' → backward, stop at 2nd line  (skip 1)
 *   '3' → backward, stop at 3rd line  (skip 2)
 *   'X' → buzzer / LED on for 2 s
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

/* =========================================================
 * HELPERS
 * =========================================================*/

/*
 * run_forward_until_intersection()
 *
 * Starts the robot moving forward, then calls Decide_Movement() in a
 * tight loop until a confirmed intersection is detected (return == 1).
 * Stops the robot, waits for motor coast-down, then sends 's'.
 *
 * This is the single canonical implementation used by 'F', post-'P',
 * and post-'N' handlers so the logic is not duplicated four times.
 */
static void run_forward_until_intersection(void)
{
    Push_Forward();         /* 80 ms rolling start, exits intersection  */

    while (1)
    {
        if (Decide_Movement() == 1)
        {
            /* Decide_Movement already called Stop() internally.        */
            _delay_ms(40);          /* motor coast-down                 */
            UART_Send_string("s\r\n");
            break;
        }
    }
}

/*
 * run_backward_until_intersection()
 *
 * Same pattern for backward travel.
 */
static void run_backward_until_intersection(void)
{
    Push_Backward();        /* 80 ms rolling start                      */

    while (1)
    {
        if (Back_Decide_Movement() == 1)
        {
            _delay_ms(40);
            UART_Send_string("s\r\n");
            break;
        }
    }
}

/* =========================================================
 * MAIN
 * =========================================================*/
int main(void)
{
    /* ── Port A: all motor outputs ─────────────────────── */
    for (int i = 0; i < 8; i++)
        DIO_Setpindir('A', i, 1);

    /* ── Port D: IR sensor inputs ──────────────────────── */
    Button_Init('D', 3);    /* front-left                              */
    Button_Init('D', 4);    /* front-right                             */
    Button_Init('D', 5);    /* back-left                               */
    Button_Init('D', 6);    /* back-right                              */

    /* ── Status LEDs ───────────────────────────────────── */
    LED_Init('C', 0);
    LED_Init('C', 7);
    LED_On('C', 0);
    _delay_ms(500);
    LED_Off('C', 0);

    /* ── UART ──────────────────────────────────────────── */
    UART_Init(9600);
    UART_Send_string("[DEBUG] UART Initialized @9600\r\n");

    char cmd;

    /* ── Main command loop ─────────────────────────────── */
    while (1)
    {
        cmd = UART_Receive_data();

        /* ── Skip whitespace ──────────────────────────── */
        if (cmd == '\n' || cmd == '\r')
            continue;

        /* ══════════════════════════════════════════════
         * 'F' — FORWARD LINE-FOLLOW
         * ══════════════════════════════════════════════*/
        if (cmd == 'F')
        {
            UART_Send_string("OK:F\r\n");
            run_forward_until_intersection();
        }

        /* ══════════════════════════════════════════════
         * 'B' — BACKWARD LINE-FOLLOW
         * ══════════════════════════════════════════════*/
        else if (cmd == 'B')
        {
            UART_Send_string("OK:B\r\n");
            run_backward_until_intersection();
        }

        /* ══════════════════════════════════════════════
         * 'P' — POSITIVE (RIGHT) ROTATION
         * Rotate right until RPi sends 'F', 'B', or 'S'.
         * ══════════════════════════════════════════════*/
        else if (cmd == 'P')
        {
            UART_Send_string("OK:P\r\n");

            while (1)
            {
                cmd = UART_Receive_data();

                if (cmd == 'F')
                {
                    UART_Send_string("OK:F\r\n");
                    run_forward_until_intersection();
                    break;
                }
                else if (cmd == 'B')
                {
                    UART_Send_string("OK:B\r\n");
                    run_backward_until_intersection();
                    break;
                }
                else if (cmd == 'S')
                {
                    Stop();
                    _delay_ms(40);
                    UART_Send_string("OK:S\r\n");
                    break;
                }
                else if (cmd == '\n' || cmd == '\r')
                {
                    /* ignore — keep rotating                         */
                }
                else
                {
                    /* keep rotating while waiting for RPi command    */
                    Move_Right_Turn();
                }
            }
        }

        /* ══════════════════════════════════════════════
         * 'N' — NEGATIVE (LEFT) ROTATION
         * Rotate left until RPi sends 'F', 'B', or 'S'.
         * ══════════════════════════════════════════════*/
        else if (cmd == 'N')
        {
            UART_Send_string("OK:N\r\n");

            while (1)
            {
                cmd = UART_Receive_data();

                if (cmd == 'F')
                {
                    UART_Send_string("OK:F\r\n");
                    run_forward_until_intersection();
                    break;
                }
                else if (cmd == 'B')
                {
                    UART_Send_string("OK:B\r\n");
                    run_backward_until_intersection();
                    break;
                }
                else if (cmd == 'S')
                {
                    Stop();
                    _delay_ms(40);
                    UART_Send_string("OK:S\r\n");
                    break;
                }
                else if (cmd == '\n' || cmd == '\r')
                {
                    /* ignore                                         */
                }
                else
                {
                    Move_Left_Turn();
                }
            }
        }

        /* ══════════════════════════════════════════════
         * 'S' — STOP
         * ══════════════════════════════════════════════*/
        else if (cmd == 'S')
        {
            Stop();
            _delay_ms(40);
            UART_Send_string("OK:S\r\n");
        }

        /* ══════════════════════════════════════════════
         * '1' / '2' / '3' — SKIP-LINE BACKWARD
         *
         * '1' → stop at 1st line  (skip 0)
         * '2' → stop at 2nd line  (skip 1)
         * '3' → stop at 3rd line  (skip 2)
         * ══════════════════════════════════════════════*/
        else if (cmd == '1' || cmd == '2' || cmd == '3')
        {
            int lines_to_skip = (int)(cmd - '0') - 1;   /* 0, 1, or 2 */
            int lines_skipped = 0;

            if      (cmd == '1') UART_Send_string("OK:1\r\n");
            else if (cmd == '2') UART_Send_string("OK:2\r\n");
            else                 UART_Send_string("OK:3\r\n");

            /* Initial push to clear any current intersection.       */
            Push_Backward();     /* 80 ms — exits current tape stripe */

            while (1)
            {
                if (Back_Decide_Movement() == 1)
                {
                    /* Intersection detected (confirmed by Back_Decide). */

                    if (lines_skipped < lines_to_skip)
                    {
                        /* Not target yet — push through this line.  */
                        Cross_Intersection_Backward();
                        lines_skipped++;
                        /* Brief gap after crossing before re-checking. */
                        _delay_ms(30);
                    }
                    else
                    {
                        /* Target line reached — stop.               */
                        Stop();
                        _delay_ms(40);
                        UART_Send_string("s\r\n");
                        break;
                    }
                }
            }
        }

        /* ══════════════════════════════════════════════
         * 'X' — BUZZER / LED INDICATOR
         * ══════════════════════════════════════════════*/
        else if (cmd == 'X')
        {
            UART_Send_string("OK:K\r\n");
            LED_On('C', 7);
            _delay_ms(2000);
            LED_Off('C', 7);
        }

    } /* end while(1) */
}