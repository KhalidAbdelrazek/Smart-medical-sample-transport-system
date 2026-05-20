/*
 * main_movement.h
 *
 * PROFESSIONAL REDESIGN — v2.0
 * Author: NADER (refactored)
 *
 * Declares all movement primitives for use in Line_Follower_Logic.c
 * and main.c.  The v1 interface (Move_Up, Move_Down, Move_Left,
 * Move_Right, Stop) is preserved for backward compatibility.
 * New functions are additive.
 */

#ifndef MAIN_MOVEMENT_H_
#define MAIN_MOVEMENT_H_

#include <stdint.h>

/* ── Forward motion ──────────────────────────────────────────── */
void Move_Up_Straight(void);      /* equal speed both sides         */
void Move_Up(void);               /* legacy alias → Move_Up_Straight */

void Move_Correct_Left(void);     /* soft left correction (fwd)     */
void Move_Correct_Right(void);    /* soft right correction (fwd)    */

/* ── Backward motion ─────────────────────────────────────────── */
void Move_Down_Straight(void);    /* equal speed both sides         */
void Move_Down(void);             /* legacy alias → Move_Down_Straight */

/* ── Hard turns (in-place differential pivot) ───────────────── */
void Move_Left_Turn(void);        /* pivot left  (used by N cmd)    */
void Move_Right_Turn(void);       /* pivot right (used by P cmd)    */

void Move_Left(void);             /* legacy alias → Move_Left_Turn  */
void Move_Right(void);            /* legacy alias → Move_Right_Turn */

/* ── Stop ────────────────────────────────────────────────────── */
void Stop(void);

#endif /* MAIN_MOVEMENT_H_ */