"""
main.py — Smart Medical Transport Robot
========================================

State machine:
  IDLE
    └─► (dispatch received) ──► RUNNING_BATCH
          └─► for each room:
                MOVING_TO_ROOM          — fast IR loop, stop on black
                  └─► SCANNING_ROOM     — camera OCR
                        ├─► wrong room  — push forward, back to IR loop
                        └─► right room  — publish arrival
                              └─► WAITING_FOR_PROCEED
                                    └─► (proceed received)
                                          └─► PUSH_CLEAR — push off stripe
                                                └─► next room or IDLE
"""

import logging
import time
import queue

from uart_controller    import UARTCarController
from mqtt_controller    import MQTTController
from console_interface  import SharedState, ConsoleMonitor
from functions          import (
    setup_gpio,
    read_sensors,
    confirm_intersection,
    decide_movement,
    get_rooms,
    get_request_ids_for_room,
    get_sample_ids_for_room,
)
from camera_module import read_room_number

# =========================
# Logging
# =========================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - [%(levelname)s] - %(message)s'
)

# =========================
# Constants
# =========================
CAR_ID = "1"

# How long (seconds) to push forward to clear the current black stripe
# so the IR sensors move off it before the next line-follow segment.
PUSH_CLEAR_DURATION = 0.6

# Tiny sleep at the bottom of the fast IR loop — keeps CPU usage sane
# while still reacting within ~5 ms to a 2 cm stripe.
IR_LOOP_SLEEP = 0.005   # 5 ms  →  ~200 iterations/second


# =========================
# Core: Line Follow → Stop at Black Stripe
# =========================
def run_until_black_stripe(car: UARTCarController) -> None:
    """
    Drives the car forward using line-following logic.
    Returns ONLY when BOTH IR sensors simultaneously confirm a solid
    black stripe (real intersection/room marker).

    Speed notes:
      • Raw GPIO reads (no averaging) for minimum latency.
      • confirm_intersection() uses 3 fast reads with 5 ms gaps
        — total confirmation window ≈ 10 ms, well within a 2 cm stripe
        at the robot's speed.
      • stop() is called before confirm_intersection returns so the car
        halts as fast as the UART (115200 baud) allows.
    """
    logging.info("[ROBOT] Line-follow started — waiting for black stripe...")
    last_cmd = ""

    while True:
        left, right = read_sensors()   # Raw single read — fastest possible

        # ── Both sensors see BLACK ──────────────────────────────────────
        if left == 1 and right == 1:
            # Issue stop IMMEDIATELY — don't wait for confirm
            if last_cmd != "S\n":
                car.stop()
                last_cmd = "S\n"

            # Now confirm it's a real stripe and not electrical noise
            if confirm_intersection():
                logging.info("[ROBOT] ✓ Black stripe confirmed — car stopped.")
                return   # Caller takes over

            # False positive — resume moving
            car.forward()
            last_cmd = "F\n"
            continue

        # ── Normal line-following ────────────────────────────────────────
        _, cmd = decide_movement(left, right)
        if cmd != last_cmd:          # Only send when direction changes
            car.send_command_and_reconnect_if_failed(cmd)
            last_cmd = cmd

        time.sleep(IR_LOOP_SLEEP)


def push_clear_stripe(car: UARTCarController) -> None:
    """
    Drives forward for PUSH_CLEAR_DURATION seconds so the IR sensors
    move completely off the current black stripe.
    After this call the sensors should read white again.
    """
    logging.info(f"[ROBOT] Pushing forward {PUSH_CLEAR_DURATION}s to clear stripe...")
    car.forward()
    time.sleep(PUSH_CLEAR_DURATION)
    car.stop()
    logging.info("[ROBOT] Clear push done.")


# =========================
# Main
# =========================
def main():
    shared_state    = SharedState()
    dispatch_queue  = queue.Queue()
    control_queue   = queue.Queue()

    car              = None
    mqtt_controller  = None
    console          = ConsoleMonitor(shared_state)

    try:
        # ── Hardware init ────────────────────────────────────────────────
        setup_gpio()

        shared_state.update(uart_status="CONNECTING")
        car = UARTCarController(port='/dev/serial0', baudrate=9600)
        shared_state.update(uart_status="CONNECTED")

        mqtt_controller = MQTTController(CAR_ID, dispatch_queue, control_queue)
        mqtt_controller.start()
        console.start()

        # ── Main loop ────────────────────────────────────────────────────
        while True:
            # Keep MQTT status fresh in the dashboard
            shared_state.update(
                mqtt_status="CONNECTED" if mqtt_controller.connected else "DISCONNECTED"
            )

            # ════════════════════════════════════════════════════════════
            # STATE: IDLE — wait for a dispatch from the backend
            # ════════════════════════════════════════════════════════════
            shared_state.update(state="IDLE", current_batch=None, current_room=None)
            logging.info("[ROBOT] IDLE — waiting for dispatch...")

            payload  = None
            batch_id = None
            rooms    = []

            while True:
                try:
                    payload = dispatch_queue.get(timeout=1.0)
                    rooms, batch_id = get_rooms(payload)

                    if not rooms or not batch_id:
                        logging.error("[ROBOT] Dispatch payload invalid — ignoring.")
                        payload = None
                        continue

                    break   # Valid dispatch received
                except queue.Empty:
                    # Update MQTT status while waiting
                    shared_state.update(
                        mqtt_status="CONNECTED" if mqtt_controller.connected else "DISCONNECTED"
                    )

            # ── Send ACK ─────────────────────────────────────────────────
            logging.info(f"[ROBOT] Dispatch received: batch={batch_id}  rooms={rooms}")
            mqtt_controller.publish_ack(batch_id)

            shared_state.update(state="RUNNING_BATCH", current_batch=batch_id)

            # ════════════════════════════════════════════════════════════
            # Process each room in the batch
            # ════════════════════════════════════════════════════════════
            for room in rooms:
                shared_state.update(state="MOVING_TO_ROOM", current_room=room)
                logging.info(f"[ROBOT] ── Target room: {room} ──")

                # ── Inner loop: keep going until we confirm correct room ──
                while True:
                    # 1. Follow line until we hit a black stripe
                    run_until_black_stripe(car)

                    # 2. Scan the room number with camera
                    shared_state.update(state="SCANNING_ROOM")
                    logging.info("[ROBOT] Scanning room number...")
                    detected_room = read_room_number()
                    logging.info(
                        f"[ROBOT] Camera → '{detected_room}'  |  Expected → '{room}'"
                    )

                    # 3. Correct room?
                    if str(detected_room) == str(room):
                        # ── Arrived at correct room ───────────────────────
                        logging.info(f"[ROBOT] ✓ Room {room} confirmed.")

                        request_ids = get_request_ids_for_room(payload, room)
                        sample_ids  = get_sample_ids_for_room(payload, room)

                        mqtt_controller.publish_arrival(room, request_ids, sample_ids)

                        # ── Wait for backend 'proceed' ────────────────────
                        shared_state.update(state="WAITING_FOR_PROCEED")
                        logging.info(f"[ROBOT] Waiting for 'proceed' on room {room}...")

                        while True:
                            # Keep car stopped while waiting
                            car.stop()
                            try:
                                ctrl = control_queue.get(timeout=1.0)
                                cmd_type = str(ctrl.get("command", "")).lower()
                                cmd_room = str(ctrl.get("room",    ""))
                                cmd_car  = str(ctrl.get("car_id",  CAR_ID))

                                if (cmd_type == "proceed"
                                        and cmd_room == str(room)
                                        and cmd_car  == CAR_ID):
                                    logging.info("[ROBOT] ✓ 'proceed' received.")
                                    break
                                else:
                                    logging.warning(
                                        f"[ROBOT] Ignored control msg: {ctrl}"
                                    )
                            except queue.Empty:
                                pass    # Keep looping / keep car stopped

                        # ── Push forward off current stripe ───────────────
                        push_clear_stripe(car)
                        break   # Done with this room, advance to next

                    else:
                        # ── Wrong room — push off stripe and look again ───
                        logging.warning(
                            f"[ROBOT] Wrong room (got '{detected_room}'). "
                            f"Pushing forward to next stripe..."
                        )
                        push_clear_stripe(car)
                        # Loop back → run_until_black_stripe for next marker

                # Brief pause before starting line-follow for next room
                time.sleep(0.5)

            # ── All rooms done ────────────────────────────────────────────
            logging.info(f"[ROBOT] ✓ Batch {batch_id} complete — returning to IDLE.")
            car.stop()
            # Loop back to IDLE at top of while True

    except KeyboardInterrupt:
        logging.info("[SHUTDOWN] KeyboardInterrupt — shutting down...")
    except Exception as e:
        logging.exception(f"[FATAL] Unhandled exception: {e}")
    finally:
        logging.info("[SHUTDOWN] Cleanup...")
        if console:
            console.stop()
        if mqtt_controller:
            mqtt_controller.stop()
        if car:
            car.stop()
            car.cleanup()
        try:
            import RPi.GPIO as GPIO
            GPIO.cleanup()
        except Exception:
            pass
        print("[SHUTDOWN] Clean exit.")


if __name__ == "__main__":
    main()