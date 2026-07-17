"""
Camera Module.
Handles camera frame capture, preprocessing, and OCR using pytesseract to read the room number.
"""

import logging
import re
import time
from collections import Counter
import config

logger = logging.getLogger(__name__)

# Fallbacks for libraries to allow running on non-RPi environments
try:
    from picamera2 import Picamera2
except ImportError:
    logger.warning("picamera2 not installed. Using Mock Picamera2 for development.")
    class Picamera2:
        def create_video_configuration(self, **kwargs):
            return {}
        def configure(self, video_config):
            pass
        def start(self):
            pass
        def capture_array(self):
            import numpy as np
            return np.zeros((240, 320, 3), dtype=np.uint8)
        def close(self):
            pass

try:
    import cv2
except ImportError:
    logger.warning("cv2 (OpenCV) not installed. Using Mock cv2 for development.")
    class MockCv2:
        COLOR_BGR2GRAY = 6
        THRESH_BINARY = 0
        THRESH_OTSU = 8
        def cvtColor(self, src, code):
            return src
        def GaussianBlur(self, src, ksize, sigmaX):
            return src
        def threshold(self, src, thresh, maxval, type):
            return 0, src
    cv2 = MockCv2()

try:
    import pytesseract
except ImportError:
    logger.warning("pytesseract not installed. Using Mock pytesseract for development.")
    class MockPytesseract:
        def image_to_string(self, thresh, config=""):
            # Simulate a successful OCR return of "1" for room 1 during test/dev
            return "1"
    pytesseract = MockPytesseract()


class CameraScanner:
    """
    Manages the camera lifecycle and reads room numbers using OCR.
    """
    def __init__(self, samples: int = 10, delay: float = 0.3):
        self.samples = samples
        self.delay = delay

    def read_room_number(self) -> str:
        """
        Captures camera frames, preprocesses them, runs OCR, and returns the
        most frequently detected valid room number.
        """
        logger.info("[CAMERA] Initializing Picamera2...")
        picam2 = Picamera2()

        # Low resolution + High FPS configuration (320x240 @ ~120 FPS)
        video_config = picam2.create_video_configuration(
            main={"size": (320, 240), "format": "RGB888"},
            controls={"FrameDurationLimits": (8333, 8333)}
        )

        picam2.configure(video_config)
        picam2.start()
        logger.info("[CAMERA] Warming up camera...")
        time.sleep(1)  # camera warmup

        try:
            while True:
                detected_numbers = []

                for i in range(self.samples):
                    frame = picam2.capture_array()

                    # Preprocessing
                    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                    gray = cv2.GaussianBlur(gray, (5, 5), 0)
                    _, thresh = cv2.threshold(
                        gray,
                        0,
                        255,
                        cv2.THRESH_BINARY + cv2.THRESH_OTSU
                    )

                    # OCR digit recognition config
                    tess_config = r'--oem 3 --psm 6 outputbase digits'
                    text = pytesseract.image_to_string(thresh, config=tess_config)

                    # Extract numbers
                    numbers = re.findall(r'\d+', text)
                    if numbers:
                        detected_numbers.append(numbers[0])
                        logger.info(f"[CAMERA] Frame {i+1}/{self.samples}: detected -> {numbers[0]}")
                    else:
                        logger.debug(f"[CAMERA] Frame {i+1}/{self.samples}: no number detected")

                    time.sleep(self.delay)

                if not detected_numbers:
                    logger.warning("[CAMERA] No number detected in sample batch, scanning again...")
                    continue

                # Determine the most common number detected in the samples
                final_number = Counter(detected_numbers).most_common(1)[0][0]

                if final_number in config.VALID_ROOMS:
                    logger.info(f"[CAMERA] Confirmed room: '{final_number}'")
                    picam2.close()
                    return final_number
                else:
                    logger.warning(f"[CAMERA] Scanned '{final_number}' which is not a valid room {config.VALID_ROOMS}. Re-scanning...")
        except Exception as e:
            logger.error(f"[CAMERA] OCR scan error: {e}")
            picam2.close()
            raise


# Keep backward compatibility function
def read_room_number(samples: int = 10, delay: float = 0.3) -> str:
    """Legacy wrapper for backward compatibility."""
    scanner = CameraScanner(samples, delay)
    return scanner.read_room_number()
