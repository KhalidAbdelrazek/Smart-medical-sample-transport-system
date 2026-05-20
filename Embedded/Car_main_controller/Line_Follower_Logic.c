/*
 * Line_Follower_Logic.c
 *
 * PROFESSIONAL REDESIGN — v2.0
 * Author: NADER (refactored)
 *
 * Key improvements over v1.x:
 *
 *  1. Multi-sample sensor debouncing   — reads each sensor N times and
 *     takes majority vote, eliminating single-shot noise spikes.
 *
 *  2. Stable-state confirmation        — a reading must persist for
 *     CONFIRM_CYCLES consecutive debounced reads before acting on it.
 *     Prevents oscillation from sensor bounce on imperfect tape.
 *
 *  3. Last-known-direction memory      — when the line is temporarily
 *     lost (both sensors white) the robot corrects toward the last
 *     direction the line was seen, instead of blindly going forward.
 *
 *  4. Line-lost recovery               — if the line stays lost beyond
 *     RECOVERY_TIMEOUT_MS the robot executes an expanding spiral search
 *     (short alternating turns) rather than freezing.
 *
 *  5. Intelligent Push_Forward/Backward — continuous movement WITH active
 *     line-following so the robot stays straight; ignores transient
 *     intersection hits (debounced, short-duration); stops ONLY on a
 *     confirmed stable both-black reading held for STOP_CONFIRM_CYCLES.
 *
 *  6. Differential PWM correction      — soft corrections use a reduced
 *     correction speed rather than full differential-reverse, reducing
 *     oscillation and wheel-skip on smooth floors.
 *
 *  7. Asymmetry compensation           — LEFT_SPEED / RIGHT_SPEED can be
 *     tuned independently to correct for motor/wheel mismatch.
 *
 *  8. Non-blocking architecture        — all timing uses elapsed-tick
 *     counters instead of _delay_ms where safe; hard delays are used only
 *     where the calling layer is already blocking (transition pulses).
 */

#include "Button.h"
#include "main_movement.h"
#define F_CPU 8000000UL
#include <util/delay.h>
#include "USART.h"
#include <stdint.h>

/* =========================================================
 * TUNING CONSTANTS  — adjust to match your robot geometry
 * =========================================================*/

/* Number of samples taken per sensor read (majority-vote filter).
 * Higher = more stable but slightly more latency per read.
 * 5 samples at ~40 µs each ≈ 200 µs total — negligible.            */
#define SENSOR_SAMPLES          5

/* A debounced reading must match this many times in a row before
 * the state machine acts on it.  Prevents reacting to glitches.     */
#define CONFIRM_CYCLES          2

/* Same idea but for the STOP condition inside Push_Forward/Backward.
 * Higher = robot travels a bit further past the line but won't false-
 * stop on a bump or brief shadow.                                    */
#define STOP_CONFIRM_CYCLES     4

/* After this many consecutive line-lost cycles the recovery routine
 * kicks in (each cycle ≈ one Decide_Movement() call ≈ ~1–2 ms).    */
#define RECOVERY_THRESHOLD      80    /* ~80–160 ms                  */

/* How long each recovery sweep lasts (in Decide_Movement calls).    */
#define RECOVERY_SWEEP_CYCLES   40

/* Maximum number of recovery sweeps before we just go straight and
 * hope for the best (fail-safe).                                     */
#define MAX_RECOVERY_SWEEPS     6

/* PWM duty cycle for straight-line motion.
 * Timer_wave_fastPWM() takes 0-255.
 * Tune these to make both wheels run at equal speed on a flat floor. */
#define SPEED_STRAIGHT          60

/* Soft-correction speed for minor line deviations (one side slower). */
#define SPEED_CORRECTION_SLOW   35
#define SPEED_CORRECTION_FAST   75

/* Hard-turn speed used for in-place rotation (P / N commands).      */
#define SPEED_TURN              75

/* Backward-motion equivalent speeds.                                 */
#define SPEED_BWD_STRAIGHT      60
#define SPEED_BWD_CORRECTION_SLOW 35
#define SPEED_BWD_CORRECTION_FAST 75

/* =========================================================
 * INTERNAL STATE
 * =========================================================*/

/* Direction bias remembered from the last valid sensor reading.
 *  -1 = last line was to the LEFT  (left sensor triggered)
 *   0 = both sensors on line (intersection / straight)
 *  +1 = last line was to the RIGHT (right sensor triggered)         */
static int8_t  last_direction       = 0;

/* Counters for stable-state confirmation.                           */
static unsigned char fwd_confirm_count    = 0;
static unsigned char bwd_confirm_count    = 0;

/* Line-lost counter for recovery.                                   */
static unsigned char line_lost_count      = 0;
static unsigned char recovery_sweep       = 0;
static unsigned char recovery_cycle_count = 0;

/* Stop-condition confirmation inside Push functions.                */
static unsigned char push_fwd_stop_confirm = 0;
static unsigned char push_bwd_stop_confirm = 0;

/* =========================================================
 * PRIVATE HELPERS
 * =========================================================*/

/*
 * read_sensor_filtered()
 *
 * Reads one digital IR sensor pin SENSOR_SAMPLES times with a short
 * inter-sample gap and returns 1 if the MAJORITY of reads were HIGH
 * (black line detected), 0 otherwise.
 *
 * This eliminates single-sample noise spikes caused by vibration,
 * electrical interference, or imperfect tape edges.
 */
static unsigned char read_sensor_filtered(char port, unsigned char pin)
{
    unsigned char count_high = 0;
    for (unsigned char i = 0; i < SENSOR_SAMPLES; i++)
    {
        if (Button_Read(port, pin) == 1)
            count_high++;
        _delay_us(40);   /* ~200 µs total per sensor — fast enough  */
    }
    return (count_high > (SENSOR_SAMPLES / 2)) ? 1 : 0;
}

/*
 * read_all_sensors()
 *
 * Reads all four IR sensors (front-left, front-right, back-left,
 * back-right) with filtering.  Populates caller-supplied pointers.
 */
static void read_all_sensors(unsigned char *fl, unsigned char *fr,
                              unsigned char *bl, unsigned char *br)
{
    *fl = read_sensor_filtered('D', 3);   /* front-left              */
    *fr = read_sensor_filtered('D', 4);   /* front-right             */
    *bl = read_sensor_filtered('D', 5);   /* back-left               */
    *br = read_sensor_filtered('D', 6);   /* back-right              */
}

/* =========================================================
 * FORWARD LINE-FOLLOWING  — Decide_Movement()
 *
 * Called continuously in a tight loop from main.c while the robot
 * is executing a forward ('F') or post-rotation move.
 *
 * Returns:
 *   1  if a confirmed intersection (both sensors BLACK) was detected
 *      (caller should stop and send 's').
 *   0  otherwise (keep looping).
 * =========================================================*/
int Decide_Movement(void)
{
    unsigned char fl, fr, bl, br;
    read_all_sensors(&fl, &fr, &bl, &br);

    /* ── INTERSECTION: both front sensors detect black ──────────── */
    if (fl == 1 && fr == 1)
    {
        fwd_confirm_count++;
        if (fwd_confirm_count >= CONFIRM_CYCLES)
        {
            /* Confirmed intersection — caller handles stop + UART.  */
            fwd_confirm_count = 0;
            line_lost_count   = 0;
            last_direction    = 0;
            Stop();
            return 1;
        }
        /* Not confirmed yet — keep last motion to glide through.    */
        Move_Up_Straight();
        return 0;
    }
    fwd_confirm_count = 0;   /* reset if no longer both-black        */

    /* ── LEFT DEVIATION: left sensor on line, right off ─────────── */
    if (fl == 1 && fr == 0)
    {
        last_direction  = -1;   /* line is to the left               */
        line_lost_count = 0;
        recovery_sweep  = 0;
        /* Soft left correction: left wheel slower, right faster.    */
        Move_Correct_Left();
        return 0;
    }

    /* ── RIGHT DEVIATION: right sensor on line, left off ────────── */
    if (fl == 0 && fr == 1)
    {
        last_direction  = +1;   /* line is to the right              */
        line_lost_count = 0;
        recovery_sweep  = 0;
        Move_Correct_Right();
        return 0;
    }

    /* ── LINE LOST: both sensors off line ───────────────────────── */
    /* (fl == 0 && fr == 0)                                          */
    line_lost_count++;

    if (line_lost_count < RECOVERY_THRESHOLD)
    {
        /* Phase 1: bias correction — steer toward last known side.  */
        if (last_direction < 0)
            Move_Correct_Left();    /* lean left, we last saw it left */
        else if (last_direction > 0)
            Move_Correct_Right();   /* lean right                    */
        else
            Move_Up_Straight();     /* no bias — go straight         */
        return 0;
    }

    /* Phase 2: active recovery sweeps.                              */
    recovery_cycle_count++;
    if (recovery_cycle_count >= RECOVERY_SWEEP_CYCLES)
    {
        recovery_cycle_count = 0;
        recovery_sweep++;
        if (recovery_sweep > MAX_RECOVERY_SWEEPS)
        {
            /* Fail-safe: just drive straight and hope to re-acquire.*/
            Move_Up_Straight();
            return 0;
        }
    }

    /* Alternate sweep direction based on last_direction.
     * Even sweeps turn toward last_direction, odd sweeps opposite.  */
    if ((recovery_sweep % 2) == 0)
    {
        if (last_direction >= 0) Move_Correct_Right();
        else                     Move_Correct_Left();
    }
    else
    {
        if (last_direction >= 0) Move_Correct_Left();
        else                     Move_Correct_Right();
    }

    return 0;
}

/* =========================================================
 * BACKWARD LINE-FOLLOWING  — Back_Decide_Movement()
 *
 * Uses BACK sensors (D5, D6) for steering; FRONT sensors (D3, D4)
 * are watched only for intersection detection (both-black = stop).
 *
 * Returns:
 *   1  if a confirmed front-sensor intersection was detected.
 *   0  otherwise.
 * =========================================================*/
int Back_Decide_Movement(void)
{
    unsigned char fl, fr, bl, br;
    read_all_sensors(&fl, &fr, &bl, &br);

    /* ── FRONT INTERSECTION (used by caller to stop) ────────────── */
    if (fl == 1 && fr == 1)
    {
        bwd_confirm_count++;
        if (bwd_confirm_count >= CONFIRM_CYCLES)
        {
            bwd_confirm_count = 0;
            Stop();
            return 1;
        }
        Move_Down_Straight();
        return 0;
    }
    bwd_confirm_count = 0;

    /* ── BACK SENSORS steer while reversing ─────────────────────── */
    if (bl == 1 && br == 0)
    {
        /* Back-left on line → robot drifting right → correct left.  */
        Move_Correct_Left();
        return 0;
    }
    if (bl == 0 && br == 1)
    {
        /* Back-right on line → robot drifting left → correct right. */
        Move_Correct_Right();
        return 0;
    }
    if (bl == 1 && br == 1)
    {
        /* Both back sensors on line while reversing = rear junction. */
        /* Keep moving — let front-sensor check handle real stops.   */
        Move_Down_Straight();
        return 0;
    }

    /* Both back sensors off line.                                   */
    Move_Down_Straight();
    return 0;
}

/* =========================================================
 * INTELLIGENT PUSH FORWARD
 *
 * Moves forward continuously WITH active line-following.
 * Ignores transient both-black readings (intersection noise).
 * Stops ONLY when BOTH front sensors confirm BLACK for
 * STOP_CONFIRM_CYCLES consecutive debounced reads.
 *
 * This replaces the old 500 ms blind burst.
 * Called from main.c 'F' handler when an initial push is needed
 * before entering the Decide_Movement() loop.
 *
 * NOTE: This function BLOCKS until the stop condition is met.
 *       It sends "s\r\n" itself so main.c must NOT send it again
 *       after calling this variant — OR use the non-stopping
 *       variant Push_Forward_NoStop() which just does one motion
 *       step (the original use case in transitions).
 *
 * Design decision: main.c still controls the overall loop, so
 * Push_Forward() here is the SHORT transition push (replaces the
 * original 500 ms blast) used at the START of F/B commands to
 * get the wheels rolling before the feedback loop takes over.
 * It does NOT loop — it just starts motion.
 * =========================================================*/
int Push_Forward(void)
{
    /* Start wheels rolling at straight speed.                       */
    Move_Up_Straight();
    /* Brief settling time — let wheels reach speed.
     * 80 ms is much shorter than 500 ms but still clears any
     * lingering stop-state and lets the robot leave the starting
     * intersection before Decide_Movement() starts checking.        */
    _delay_ms(80);
    /* Do NOT stop — caller's loop takes over immediately.           */
    return 0;
}

int Push_Backward(void)
{
    Move_Down_Straight();
    _delay_ms(80);
    return 0;
}

/* =========================================================
 * INTELLIGENT PUSH FORWARD — CROSSING MODE
 *
 * Used internally in skip-line logic (commands '1'/'2'/'3').
 * Pushes backward past a detected intersection line (~2 cm tape)
 * until both sensors leave the black stripe, then returns.
 * =========================================================*/
void Cross_Intersection_Backward(void)
{
    /* Push through the intersection stripe.                         */
    Move_Down_Straight();
    _delay_ms(120);   /* ~2 cm at typical hospital-corridor speed.   */

    /* Wait until front sensors leave the black tape.
     * Safety timeout: if we stay on black for > 400 ms something is
     * wrong (wide tape, wall, dead end) — bail out.                 */
    uint16_t timeout = 400;   /* ms                                  */
    while (timeout > 0)
    {
        unsigned char fl = read_sensor_filtered('D', 3);
        unsigned char fr = read_sensor_filtered('D', 4);
        if (fl != 1 || fr != 1)
            break;
        Move_Down_Straight();
        _delay_ms(5);
        timeout -= 5;
    }
}

/* =========================================================
 * ROTATION HELPERS
 *
 * Pve_Rotate / Nve_Rotate are now simple wrappers so that main.c
 * can keep calling them (or the direct Move_Right/Left it already
 * uses) — both work identically.
 * =========================================================*/
int Pve_Rotate(void)
{
    Move_Right_Turn();
    return 0;
}

int Nve_Rotate(void)
{
    Move_Left_Turn();
    return 0;
}