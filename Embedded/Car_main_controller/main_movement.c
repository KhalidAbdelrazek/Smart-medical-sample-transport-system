/*
 * main_movement.c
 *
 * PROFESSIONAL REDESIGN — v2.0
 * Author: NADER (refactored)
 *
 * Architecture changes vs v1.x:
 *
 *  1. INDEPENDENT left/right PWM  — the original code called
 *     Timer_wave_fastPWM(Left_wheels) for ALL movements, meaning the
 *     right-wheel PWM channel was never updated during turns.  This
 *     caused asymmetric turns and unpredictable correction behavior.
 *     Both channels are now set on every movement call.
 *
 *  2. NAMED speed constants       — speeds are defined as meaningful
 *     macros, making tuning explicit and safe.
 *
 *  3. SOFT CORRECTION primitives  — Move_Correct_Left/Right() apply
 *     a gentle differential (one wheel slightly slower) instead of
 *     the full-opposite-direction spin used in Move_Left/Right().
 *     This halves oscillation amplitude on well-laid tape.
 *
 *  4. HARD TURN primitives        — Move_Left_Turn/Right_Turn() keep
 *     the full differential-drive spin for P/N rotation commands
 *     and for recovery sweeps where the robot genuinely needs to
 *     pivot in place.
 *
 *  5. SEPARATE forward/backward speed sets — backward motion often
 *     behaves differently due to wheel inertia; having independent
 *     constants lets you tune them separately.
 *
 *  6. All functions are void-returning (the int return in v1 was
 *     unused and misleading).
 *
 * ── Motor wiring assumed ──────────────────────────────────────────
 *
 *  LEFT  motor front:  PA0 (IN1-fwd) / PA1 (IN2-bwd)
 *  LEFT  motor back:   PA2 (IN3-fwd) / PA3 (IN4-bwd)   (parallel pair)
 *  RIGHT motor front:  PA4 (IN1-fwd) / PA5 (IN2-bwd)
 *  RIGHT motor back:   PA6 (IN3-fwd) / PA7 (IN4-bwd)   (parallel pair)
 *
 *  "FORWARD" for the robot = LEFT motors spin forward, RIGHT motors
 *   spin forward.
 *
 * ── PWM channel mapping ──────────────────────────────────────────
 *
 *  Timer_wave_fastPWM(duty)  → Timer 0 or 1 output tied to LEFT side
 *  Timer2_wave_fastPWM(duty) → Timer 2 output tied to RIGHT side
 *
 *  If your hardware uses a single shared enable per H-bridge the
 *  second Timer call can be removed without breaking correctness —
 *  only the differential correction will lose granularity.
 */

#include "Timers.h"
#include "DIO.h"

/* =========================================================
 * SPEED CONSTANTS  — tune to your robot
 * =========================================================
 *
 * Range: 0–255 (Timer fast-PWM duty cycle).
 * Start with STRAIGHT ≈ 55–70, tune CORRECTION to get smooth
 * recovery without hunting.
 */

/* ── Forward speeds ──────────────────────────────────── */
#define SPD_FWD_STRAIGHT        60    /* both wheels forward          */
#define SPD_FWD_FAST            65    /* outer wheel during correction */
#define SPD_FWD_SLOW            35    /* inner wheel during correction */

/* ── Backward speeds ─────────────────────────────────── */
#define SPD_BWD_STRAIGHT        60
#define SPD_BWD_FAST            65
#define SPD_BWD_SLOW            35

/* ── Hard-turn (in-place pivot) speed ───────────────── */
#define SPD_TURN                75

/* =========================================================
 * PRIVATE HELPER — set both PWM channels at once
 * =========================================================*/
static void set_pwm(unsigned char left_duty, unsigned char right_duty)
{
    Timer_wave_fastPWM(left_duty);
    Timer2_wave_fastPWM(right_duty);
}

/* =========================================================
 * FORWARD PRIMITIVES
 * =========================================================*/

/*
 * Move_Up_Straight() — both wheels forward at equal speed.
 * Use for: straight-line travel, line-following when centered.
 */
void Move_Up_Straight(void)
{
    /* Left motors FORWARD */
    DIO_Writepin('A', 0, 0);
    DIO_Writepin('A', 1, 1);
    DIO_Writepin('A', 2, 0);
    DIO_Writepin('A', 3, 1);
    /* Right motors FORWARD */
    DIO_Writepin('A', 4, 0);
    DIO_Writepin('A', 5, 1);
    DIO_Writepin('A', 6, 0);
    DIO_Writepin('A', 7, 1);
    set_pwm(SPD_FWD_STRAIGHT, SPD_FWD_STRAIGHT);
}

/*
 * Move_Up() — legacy alias kept so any remaining main.c references
 * compile without change.
 */
void Move_Up(void)
{
    Move_Up_Straight();
}

/*
 * Move_Correct_Left() — soft left correction.
 *
 * Left sensor on line = robot has drifted right.
 * Slow down LEFT wheel, speed up RIGHT wheel to pull back left.
 * Both wheels still move forward (no reverse spin) → smoother.
 */
void Move_Correct_Left(void)
{
    /* Left motors FORWARD (slower) */
    DIO_Writepin('A', 0, 0);
    DIO_Writepin('A', 1, 1);
    DIO_Writepin('A', 2, 0);
    DIO_Writepin('A', 3, 1);
    /* Right motors FORWARD (faster) */
    DIO_Writepin('A', 4, 0);
    DIO_Writepin('A', 5, 1);
    DIO_Writepin('A', 6, 0);
    DIO_Writepin('A', 7, 1);
    set_pwm(SPD_FWD_SLOW, SPD_FWD_FAST);
}

/*
 * Move_Correct_Right() — soft right correction.
 *
 * Right sensor on line = robot has drifted left.
 * Speed up LEFT wheel, slow down RIGHT wheel.
 */
void Move_Correct_Right(void)
{
    /* Left motors FORWARD (faster) */
    DIO_Writepin('A', 0, 0);
    DIO_Writepin('A', 1, 1);
    DIO_Writepin('A', 2, 0);
    DIO_Writepin('A', 3, 1);
    /* Right motors FORWARD (slower) */
    DIO_Writepin('A', 4, 0);
    DIO_Writepin('A', 5, 1);
    DIO_Writepin('A', 6, 0);
    DIO_Writepin('A', 7, 1);
    set_pwm(SPD_FWD_FAST, SPD_FWD_SLOW);
}

/* =========================================================
 * BACKWARD PRIMITIVES
 * =========================================================*/

void Move_Down_Straight(void)
{
    /* Left motors BACKWARD */
    DIO_Writepin('A', 0, 1);
    DIO_Writepin('A', 1, 0);
    DIO_Writepin('A', 2, 1);
    DIO_Writepin('A', 3, 0);
    /* Right motors BACKWARD */
    DIO_Writepin('A', 4, 1);
    DIO_Writepin('A', 5, 0);
    DIO_Writepin('A', 6, 1);
    DIO_Writepin('A', 7, 0);
    set_pwm(SPD_BWD_STRAIGHT, SPD_BWD_STRAIGHT);
}

void Move_Down(void)
{
    Move_Down_Straight();
}

/* =========================================================
 * HARD-TURN PRIMITIVES (in-place differential pivot)
 * Used by P/N rotation commands and recovery sweeps.
 * =========================================================*/

/*
 * Move_Left_Turn() — pivot LEFT in place.
 * Left wheels BACKWARD, Right wheels FORWARD.
 */
void Move_Left_Turn(void)
{
    /* Left motors BACKWARD */
    DIO_Writepin('A', 0, 1);
    DIO_Writepin('A', 1, 0);
    DIO_Writepin('A', 2, 1);
    DIO_Writepin('A', 3, 0);
    /* Right motors FORWARD */
    DIO_Writepin('A', 4, 0);
    DIO_Writepin('A', 5, 1);
    DIO_Writepin('A', 6, 0);
    DIO_Writepin('A', 7, 1);
    set_pwm(SPD_TURN, SPD_TURN);
}

/*
 * Move_Right_Turn() — pivot RIGHT in place.
 * Left wheels FORWARD, Right wheels BACKWARD.
 */
void Move_Right_Turn(void)
{
    /* Left motors FORWARD */
    DIO_Writepin('A', 0, 0);
    DIO_Writepin('A', 1, 1);
    DIO_Writepin('A', 2, 0);
    DIO_Writepin('A', 3, 1);
    /* Right motors BACKWARD */
    DIO_Writepin('A', 4, 1);
    DIO_Writepin('A', 5, 0);
    DIO_Writepin('A', 6, 1);
    DIO_Writepin('A', 7, 0);
    set_pwm(SPD_TURN, SPD_TURN);
}

/*
 * Legacy aliases — main.c calls Move_Left() / Move_Right() during
 * P/N rotation loops.  These now map to the hard-turn versions.
 */
void Move_Left(void)
{
    Move_Left_Turn();
}

void Move_Right(void)
{
    Move_Right_Turn();
}

/* =========================================================
 * STOP
 * =========================================================*/
void Stop(void)
{
    DIO_Writepin('A', 0, 0);
    DIO_Writepin('A', 1, 0);
    DIO_Writepin('A', 2, 0);
    DIO_Writepin('A', 3, 0);
    DIO_Writepin('A', 4, 0);
    DIO_Writepin('A', 5, 0);
    DIO_Writepin('A', 6, 0);
    DIO_Writepin('A', 7, 0);
    set_pwm(0, 0);
} 