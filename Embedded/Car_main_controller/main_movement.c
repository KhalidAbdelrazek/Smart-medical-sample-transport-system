/*
 * main_movement.c
 *
 * Created: 3/1/2026 3:56:08 PM
 *  Author: NADER
 *
 * CHANGES vs original
 * -------------------
 * 1. Stop() now writes PORTA = 0x00 in a single register write
 *    instead of 8 separate DIO_Writepin() calls.
 *    This cuts stop latency from ~8 µs to ~1 CPU cycle — critical
 *    for a 2 cm black stripe at speed.
 *
 * 2. All movement functions also write direction bits as a single
 *    PORTA assignment for the same speed reason.
 *
 * 3. Speed variable 'x' raised to 150/255 — gives better torque for
 *    line following. Change it to whatever suits your motor/track.
 *
 * 4. DIO.h included so DIO_Writepin is still available if needed
 *    elsewhere; direct PORTA writes are used here for speed.
 */

#include <avr/io.h>
#include "Timers.h"
#include "DIO.h"
#include "main_movement.h"

/*
 * Motor speed: 0–255.
 * 150 ≈ 59 % duty — a good starting value for reliable line following.
 * Increase for more speed, decrease for tighter control on curves.
 */
static char speed = 150;

/*
 * Port A motor wiring (L298N or similar dual H-bridge):
 *
 *   PA0 PA1 — Left-front  motor  (IN1, IN2)
 *   PA2 PA3 — Left-rear   motor  (IN3, IN4)
 *   PA4 PA5 — Right-front motor  (IN1, IN2)
 *   PA6 PA7 — Right-rear  motor  (IN3, IN4)
 *
 * Forward  : all motors spin same direction → PA = 0b10101010 = 0xAA
 * Backward : reverse direction              → PA = 0b01010101 = 0x55
 * Turn Left : left side reverse, right forward → PA = 0b01011010 = 0x5A
 *             (right-front/rear forward, left-front/rear backward)
 * Turn Right: right side reverse, left forward → PA = 0b10100101 = 0xA5
 * Stop      : all inputs LOW                   → PA = 0x00
 *
 * ⚠ Adjust these masks if your wiring differs — the logic above is
 *   derived from your original DIO_Writepin() calls.
 */

int Move_Up(void)
{
    PORTA = 0xAA;              /* 10101010 — all forward          */
    Timer_wave_fastPWM(speed);
    return 0;
}

int Move_Down(void)
{
    PORTA = 0x55;              /* 01010101 — all backward         */
    Timer_wave_fastPWM(speed);
    return 0;
}

int Move_Right(void)
{
    /*
     * Right turn: left motors forward (1010), right motors reverse (0101)
     * PA[1:0]=10, PA[3:2]=10, PA[5:4]=01, PA[7:6]=01 → 0b01011010 = 0x5A
     * Matches original: PA0=0,PA1=1,PA2=0,PA3=1 (left fwd)
     *                   PA4=1,PA5=0,PA6=1,PA7=0 (right rev)
     */
    PORTA = 0x5A;
    Timer_wave_fastPWM(speed);
    return 0;
}

int Move_Left(void)
{
    /*
     * Left turn: left motors reverse (0101), right motors forward (1010)
     * PA[1:0]=01, PA[3:2]=01, PA[5:4]=10, PA[7:6]=10 → 0b10100101 = 0xA5
     * Matches original: PA0=1,PA1=0,PA2=1,PA3=0 (left rev)
     *                   PA4=0,PA5=1,PA6=0,PA7=1 (right fwd)
     */
    PORTA = 0xA5;
    Timer_wave_fastPWM(speed);
    return 0;
}

int Stop(void)
{
    /*
     * SINGLE register write — all motor inputs go LOW simultaneously.
     * This is the fastest possible stop: 1 AVR instruction (OUT/STS).
     * Using 8 × DIO_Writepin() calls takes ~8 µs at 8 MHz; this takes
     * ~125 ns — 64× faster, essential for a narrow 2 cm black stripe.
     */
    PORTA = 0x00;
    return 0;
}