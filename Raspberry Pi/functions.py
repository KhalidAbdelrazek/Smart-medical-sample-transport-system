"""
Utility functions for the Smart Medical Transport Robot.
Contains time formatting helpers and GPIO initialization logic.
"""

import datetime
import logging
import time
import config

logger = logging.getLogger(__name__)

# Try importing RPi.GPIO or fallback to MagicMock for testing/dev environments
try:
    import RPi.GPIO as GPIO
except ImportError:
    logger.warning("RPi.GPIO not installed. Using Mock GPIO for simulation/development.")
    from unittest.mock import MagicMock
    GPIO = MagicMock()


def get_timestamp() -> str:
    """Returns the current local time formatted as HH:MM:SS.mmm."""
    return datetime.datetime.now().strftime("%H:%M:%S.%f")[:-3]


def setup_gpio():
    """Initializes the GPIO pins for the line sensors."""
    try:
        GPIO.setwarnings(False)
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(config.SENSOR_LEFT_PIN, GPIO.IN)
        GPIO.setup(config.SENSOR_RIGHT_PIN, GPIO.IN)
        logger.info(f"GPIO initialized: Left Sensor Pin={config.SENSOR_LEFT_PIN}, Right Sensor Pin={config.SENSOR_RIGHT_PIN}")
    except Exception as e:
        logger.error(f"Failed to setup GPIO pins: {e}")


def read_sensors() -> tuple[int, int]:
    """Reads raw values from the left and right sensors."""
    try:
        return GPIO.input(config.SENSOR_LEFT_PIN), GPIO.input(config.SENSOR_RIGHT_PIN)
    except Exception as e:
        logger.error(f"Failed to read sensors: {e}")
        return 0, 0


def filter_sensors() -> tuple[int, int]:
    """Reads sensors multiple times and returns the majority value for stability."""
    left_samples = []
    right_samples = []

    for _ in range(config.FILTER_SAMPLES):
        l, r = read_sensors()
        left_samples.append(l)
        right_samples.append(r)
        time.sleep(0.01)

    left = max(set(left_samples), key=left_samples.count)
    right = max(set(right_samples), key=right_samples.count)

    return left, right


def confirm_intersection() -> bool:
    """
    Returns True only when INTERSECTION_CONFIRM_COUNT consecutive
    majority-vote reads BOTH return BLACK (1,1). This eliminates
    false-positives caused by thin lines or sensor noise.
    """
    consecutive = 0
    for _ in range(config.INTERSECTION_CONFIRM_COUNT):
        l, r = filter_sensors()
        if l == 1 and r == 1:
            consecutive += 1
        else:
            consecutive = 0  # reset — not a solid intersection
        time.sleep(config.INTERSECTION_CONFIRM_DELAY)
    return consecutive == config.INTERSECTION_CONFIRM_COUNT


def decide_movement(left: int, right: int) -> tuple[str, str]:
    """
    Decides movement logic based on sensor readings.
    LEFT=0 and RIGHT=0 -> MOVE FORWARD
    LEFT=0 and RIGHT=1 -> TURN LEFT
    LEFT=1 and RIGHT=0 -> TURN RIGHT
    LEFT=1 and RIGHT=1 -> STOP
    
    Returns (action_name, command_string)
    """
    if left == 0 and right == 0:
        return "FORWARD", "F\n"
    elif left == 1 and right == 0:
        return "LEFT", "L\n"
    elif left == 0 and right == 1:
        return "RIGHT", "R\n"
    else:
        return "STOP", "S\n"


def read_sensors_fast() -> tuple[int, int]:
    """Direct raw read, no filtering — for emergency stop detection."""
    try:
        return GPIO.input(config.SENSOR_LEFT_PIN), GPIO.input(config.SENSOR_RIGHT_PIN)
    except Exception as e:
        logger.error(f"Failed fast-read sensors: {e}")
        return 0, 0
