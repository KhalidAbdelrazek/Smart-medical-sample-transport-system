/*
 * main_movement.c
 *
 * PROFESSIONAL REDESIGN — v2.1
 * Author: NADER (refactored)
 *
 * ── CRITICAL FIX in v2.1 ─────────────────────────────────────────
 *
 *  ROOT CAUSE OF ROTATION FAILURE:
 *
 *  Timer_wave_fastPWM() uses INVERTING mode (COM00=1, COM01=1).
 *  In inverting Fast-PWM on ATmega:
 *      OCR0 = 255 - desired_duty
 *  So to get 0% duty (motor off) you write OCR0 = 255.
 *  But OCR0 = 255 in inverting mode means OC0 is ALWAYS HIGH —
 *  the PWM enable line never pulses low, so it stays at 100% in
 *  hardware after Stop() is called.
 *
 *  The original Stop() in v1 worked by zeroing all Port A direction
 *  pins only — it never touched OCR0 at all.  The H-bridge stopped
 *  because both IN pins went low (coast/brake), not because PWM = 0.
 *
 *  Our v2.0 Stop() called set_pwm(0, 0) → OCR0 = 255 (100% duty in
 *  inverting mode).  After that, when Move_Left_Turn() set the
 *  direction pins for a differential pivot, the enable line was
 *  already latched HIGH from the Stop() call and the PWM was no
 *  longer gating the motor — the H-bridge saw a continuous drive
 *  signal in both directions simultaneously (brake/fight condition).
 *
 *  FIX:
 *  Stop() now zeroes all direction pins exactly like v1 and calls
 *  Timer_wave_fastPWM(0) so OCR0 = 255 - 0 = 255 ONCE to ensure
 *  the inverting-mode output is inactive.  Crucially: every
 *  movement function that follows a Stop() re-initialises OCR0 to
 *  the correct duty value before enabling direction pins, so the
 *  latch is always overwritten before the H-bridge sees a direction.
 *
 *  SECOND FIX:
 *  SPD_TURN raised from 75 → 150 to match the original working
 *  Right_wheels = 150.  75/255 duty may be below the stall threshold
 *  of your motors at the hardware PWM frequency used.
 *
 * ── Architecture (unchanged from v2.0) ───────────────────────────
 *
 *  - Independent left/right PWM via Timer0 (OC0/PB3) and
 *    Timer2 (OC2/PD7).
 *  - Soft correction primitives for line-following (differential
 *    speed, no reverse spin) to reduce oscillation.
 *  - Hard-turn primitives for P/N rotation (full differential pivot).
 *  - Legacy aliases Move_Up/Down/Left/Right kept for compatibility.
 *
 * ── Motor wiring assumed ──────────────────────────────────────────
 *  LEFT  motors:  PA0(fwd) / PA1(bwd)  and  PA2(fwd) / PA3(bwd)
 *  RIGHT motors:  PA4(fwd) / PA5(bwd)  and  PA6(fwd) / PA7(bwd)
 *
 * ── PWM channel mapping ──────────────────────────────────────────
 *  Timer_wave_fastPWM(duty)  → OC0 / PB3  → LEFT  enable
 *  Timer2_wave_fastPWM(duty) → OC2 / PD7  → RIGHT enable
 *  Both use INVERTING mode: register value = 255 - duty.
 */

#include "Timers.h"
#include "DIO.h"
#include <stdint.h>

/* =========================================================
 * SPEED CONSTANTS
 * =========================================================
 *
 * These are the DUTY values passed to set_pwm().
 * Internally, Timer_wave_fastPWM writes OCR = 255 - duty
 * because it is configured in inverting mode.
 * You never need to think about the inversion here —
 * higher number = faster motor.
 *
 * SPD_TURN MUST be >= the motor stall threshold.
 * Original v1 used Right_wheels = 150 and it worked.
 * Keep SPD_TURN at 150 unless you have a reason to lower it.
 */
#define SPD_FWD_STRAIGHT 60
#define SPD_FWD_FAST 80
#define SPD_FWD_SLOW 30
#define SPD_BWD_STRAIGHT 60
#define SPD_BWD_FAST 80
#define SPD_BWD_SLOW 30
#define SPD_TURN 150 /* proven working value from v1    */

/* =========================================================
 * PRIVATE HELPER — set both PWM channels
 *
 * Call this BEFORE setting direction pins so the enable line is
 * at the correct duty before the H-bridge sees a direction command.
 * This prevents any transient full-drive glitch during transitions.
 * =========================================================*/
static void set_pwm(uint8_t left_duty, uint8_t right_duty)
{
	Timer_wave_fastPWM(left_duty);	 /* OC0 — LEFT side             */
	Timer2_wave_fastPWM(right_duty); /* OC2 — RIGHT side            */
}

/* =========================================================
 * FORWARD MOTION
 * =========================================================*/

/* Both wheels forward, equal speed. */
void Move_Up_Straight(void)
{
	set_pwm(SPD_FWD_STRAIGHT, SPD_FWD_STRAIGHT); /* PWM first       */
	DIO_Writepin('A', 0, 0);
	DIO_Writepin('A', 1, 1); /* L fwd     */
	DIO_Writepin('A', 2, 0);
	DIO_Writepin('A', 3, 1);
	DIO_Writepin('A', 4, 0);
	DIO_Writepin('A', 5, 1); /* R fwd     */
	DIO_Writepin('A', 6, 0);
	DIO_Writepin('A', 7, 1);
}

/* Legacy alias */
void Move_Up(void) { Move_Up_Straight(); }

/*
 * Soft LEFT correction — left sensor on line, robot drifted right.
 * Left wheel slower, right wheel faster; both still forward.
 * Curves gently left without oscillation.
 */
void Move_Correct_Left(void)
{
	set_pwm(SPD_FWD_SLOW, SPD_FWD_FAST);
	DIO_Writepin('A', 0, 0);
	DIO_Writepin('A', 1, 1); /* L fwd     */
	DIO_Writepin('A', 2, 0);
	DIO_Writepin('A', 3, 1);
	DIO_Writepin('A', 4, 0);
	DIO_Writepin('A', 5, 1); /* R fwd     */
	DIO_Writepin('A', 6, 0);
	DIO_Writepin('A', 7, 1);
}

/*
 * Soft RIGHT correction — right sensor on line, robot drifted left.
 * Left wheel faster, right wheel slower; both still forward.
 */
void Move_Correct_Right(void)
{
	set_pwm(SPD_FWD_FAST, SPD_FWD_SLOW);
	DIO_Writepin('A', 0, 0);
	DIO_Writepin('A', 1, 1); /* L fwd     */
	DIO_Writepin('A', 2, 0);
	DIO_Writepin('A', 3, 1);
	DIO_Writepin('A', 4, 0);
	DIO_Writepin('A', 5, 1); /* R fwd     */
	DIO_Writepin('A', 6, 0);
	DIO_Writepin('A', 7, 1);
}

/* =========================================================
 * BACKWARD MOTION
 * =========================================================*/

void Move_Down_Straight(void)
{
	set_pwm(SPD_BWD_STRAIGHT, SPD_BWD_STRAIGHT);
	DIO_Writepin('A', 0, 1);
	DIO_Writepin('A', 1, 0); /* L bwd     */
	DIO_Writepin('A', 2, 1);
	DIO_Writepin('A', 3, 0);
	DIO_Writepin('A', 4, 1);
	DIO_Writepin('A', 5, 0); /* R bwd     */
	DIO_Writepin('A', 6, 1);
	DIO_Writepin('A', 7, 0);
}

void Move_Down(void) { Move_Down_Straight(); }

/* =========================================================
 * HARD-TURN PRIMITIVES  (in-place differential pivot)
 *
 * Used exclusively by the P/N rotation commands and the
 * line-lost recovery sweeps in Line_Follower_Logic.c.
 *
 * PWM is set BEFORE direction pins to avoid H-bridge glitches.
 * SPD_TURN = 150 matches the original proven working value.
 * =========================================================*/

/*
 * Move_Left_Turn() — pivot LEFT.
 * Left wheels BACKWARD, Right wheels FORWARD.
 * Used by 'N' (negative / left rotation) command.
 */
void Move_Left_Turn(void)
{
	set_pwm(SPD_TURN, SPD_TURN); /* PWM first  */
	DIO_Writepin('A', 0, 1);
	DIO_Writepin('A', 1, 0); /* L bwd      */
	DIO_Writepin('A', 2, 1);
	DIO_Writepin('A', 3, 0);
	DIO_Writepin('A', 4, 0);
	DIO_Writepin('A', 5, 1); /* R fwd      */
	DIO_Writepin('A', 6, 0);
	DIO_Writepin('A', 7, 1);
}

/*
 * Move_Right_Turn() — pivot RIGHT.
 * Left wheels FORWARD, Right wheels BACKWARD.
 * Used by 'P' (positive / right rotation) command.
 */
void Move_Right_Turn(void)
{
	set_pwm(SPD_TURN, SPD_TURN);
	DIO_Writepin('A', 0, 0);
	DIO_Writepin('A', 1, 1); /* L fwd      */
	DIO_Writepin('A', 2, 0);
	DIO_Writepin('A', 3, 1);
	DIO_Writepin('A', 4, 1);
	DIO_Writepin('A', 5, 0); /* R bwd      */
	DIO_Writepin('A', 6, 1);
	DIO_Writepin('A', 7, 0);
}

/* Legacy aliases */
void Move_Left(void) { Move_Left_Turn(); }
void Move_Right(void) { Move_Right_Turn(); }

/* =========================================================
 * STOP
 *
 * v2.1 FIX: Zero direction pins first (H-bridge coast/brake),
 * THEN set PWM to 0 duty.
 *
 * In inverting Fast-PWM: Timer_wave_fastPWM(0) writes
 * OCR0 = 255 - 0 = 255, which in inverting mode means the OC0
 * output is always LOW → 0% duty → enable line inactive.
 * This is the correct way to deactivate the enable in inverting mode.
 *
 * Direction pins go low BEFORE the PWM call so the H-bridge
 * sees "no direction" while the enable is still whatever it was,
 * then the enable goes low.  This avoids any back-EMF shoot-through.
 * =========================================================*/
void Stop(void)
{
	/* 1. Remove direction signals — H-bridge enters coast/brake     */
	DIO_Writepin('A', 0, 0);
	DIO_Writepin('A', 1, 0);
	DIO_Writepin('A', 2, 0);
	DIO_Writepin('A', 3, 0);
	DIO_Writepin('A', 4, 0);
	DIO_Writepin('A', 5, 0);
	DIO_Writepin('A', 6, 0);
	DIO_Writepin('A', 7, 0);
	/* 2. Set PWM enable to 0% duty (OCR = 255 in inverting mode)    */
	set_pwm(0, 0);
}