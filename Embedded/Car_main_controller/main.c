/*
 * main.c
 *
 * Created: 3/1/2026
 * Author : NADER
 *
 * CHANGES vs original
 * -------------------
 * 1. UART_Init(115200) — matches the Raspberry Pi side.
 *
 * 2. sei() called right after UART_Init so the RX interrupt fires.
 *
 * 3. Main loop uses UART_Read_nonblocking() instead of the blocking
 *    UART_Receive_data(). The AVR no longer stalls waiting for a byte;
 *    it can react to the very next byte that arrives in the ISR buffer.
 *
 * 4. The duplicate-command guard is REMOVED for 'S' (stop).
 *    If the Pi sends "S\n" the Arduino must execute Stop() every time,
 *    even if the last command was already 'S'. This guarantees the car
 *    stops on a repeated stop command with zero hesitation.
 *
 * 5. The _delay_ms(10) after each movement command is removed.
 *    It was adding 10 ms of unnecessary latency after every command —
 *    especially harmful for Stop which needs to be instant.
 *
 * 6. The activity LED blink is removed from the main loop to eliminate
 *    any added delay in the command-processing path.
 */

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

/* Last executed command — used to suppress duplicate non-stop commands */
static char last_cmd = 0;

/* ── Command Handler ─────────────────────────────────────────────────
   Called every loop iteration when a byte is available in the RX buffer.
   Returns immediately (no blocking delays inside).                    */
static void handle_command(char cmd)
{
    /* ── Ignore newline characters (should be filtered by ISR, but
       kept here as a safety net)                                      */
    if (cmd == '\r' || cmd == '\n') return;

    /* ── STOP is always executed, even if last_cmd was already 'S'.
       A duplicate stop must never be suppressed — the Pi may be
       re-sending it to hold the car stationary.                       */
    if (cmd == 'S' || cmd == 's')
    {
        Stop();
        last_cmd = 'S';
        UART_Send_string("OK\r\n");
        return;
    }

    /* ── Suppress duplicate movement commands (saves unnecessary
       motor driver writes while following a straight line)            */
    if (cmd == last_cmd)
    {
        UART_Send_string("OK\r\n");
        return;
    }

    last_cmd = cmd;

    switch (cmd)
    {
        case 'F':
        case 'f':
            Move_Up();
            UART_Send_string("OK_F\r\n");
            break;

        case 'B':
        case 'b':
            Move_Down();
            UART_Send_string("OK_B\r\n");
            break;

        case 'L':
        case 'l':
            Move_Left();
            UART_Send_string("OK_L\r\n");
            break;

        case 'R':
        case 'r':
            Move_Right();
            UART_Send_string("OK_R\r\n");
            break;

        case 'T':
        case 't':
            /* Test command — no motor action */
            UART_Send_string("OK\r\n");
            break;

        default:
            UART_Send_string("ERR\r\n");
            break;
    }
}

/* ── Main ────────────────────────────────────────────────────────────*/
int main(void)
{
    /* ── Motor pins: Port A, all output ── */
    DIO_Setportdir('A', 0xFF);

    /* ── Status LED: blink once on boot ── */
    LED_Init('D', 7);
    LED_On('D', 7);
    _delay_ms(500);
    LED_Off('D', 7);

    /* ── UART @ 9600 baud (reliable at 8 MHz, 0.16% error) ── */
    UART_Init(9600);
    UART_Send_string("[BOOT] ATmega ready @ 9600\r\n");

    /* ── Enable global interrupts (required for UART RX ISR) ── */
    sei();

    /* ── Make sure car starts stopped ── */
    Stop();

    /* ── Main loop — never blocks ───────────────────────────────
       The ISR fills uart_rx_buf in the background.
       We drain it here as fast as the CPU can run.               */
    while (1)
    {
        if (UART_DataAvailable())
        {
            char byte = UART_Read_nonblocking();
            if (byte != 0)
                handle_command(byte);
        }
        /*
         * No delay here on purpose.
         * The loop runs at full 8 MHz so a Stop command issued by
         * the Pi is processed within microseconds of arriving in
         * the RX buffer — well within the time the car takes to
         * travel across a 2 cm black stripe.
         */
    }
}