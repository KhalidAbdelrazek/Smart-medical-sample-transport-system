import time
import cv2
import re
from collections import Counter
import logging

try:
    from picamera2 import Picamera2
    import pytesseract
    CAMERA_AVAILABLE = True
except ImportError:
    logging.warning("[CAMERA] picamera2 or pytesseract not found. Camera module will run in mock mode.")
    CAMERA_AVAILABLE = False

def read_room_number(samples=10, delay=0.3):
    """
    Uses the PiCamera to capture images, runs OCR to find numbers, 
    and returns the most common detected number.
    """
    if not CAMERA_AVAILABLE:
        logging.warning("[CAMERA] Camera unavailable. Returning mock value (None).")
        time.sleep(2) # Mock the time it takes to scan
        return None

    try:
        picam2 = Picamera2()
        config = picam2.create_preview_configuration()
        picam2.configure(config)
        picam2.start()

        time.sleep(2)

        detected_numbers = []

        for i in range(samples):
            frame = picam2.capture_array()

            gray = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
            gray = cv2.GaussianBlur(gray, (5, 5), 0)
            _, thresh = cv2.threshold(gray, 0, 255,
                                       cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            config_str = r'--oem 3 --psm 7 -c tessedit_char_whitelist=0123456789'
            text = pytesseract.image_to_string(thresh, config=config_str)

            numbers = re.findall(r'\d+', text)

            if numbers:
                detected_numbers.append(numbers[0])

            time.sleep(delay)

        picam2.close()

        if not detected_numbers:
            return None

        return Counter(detected_numbers).most_common(1)[0][0]
    except Exception as e:
        logging.error(f"[CAMERA] Error reading room number: {e}")
        try:
            picam2.close()
        except:
            pass
        return None
