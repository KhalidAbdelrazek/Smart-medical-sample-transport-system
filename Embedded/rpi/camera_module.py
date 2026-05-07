import time
import re
import logging
from collections import Counter

try:
    import cv2
    from picamera2 import Picamera2
    import pytesseract
    CAMERA_AVAILABLE = True
except ImportError:
    logging.warning("[CAMERA] picamera2 / pytesseract not found — running in mock mode.")
    CAMERA_AVAILABLE = False


def read_room_number(samples: int = 10, delay: float = 0.3):
    """
    Captures `samples` frames, runs OCR on each, and returns the most
    frequently detected number string (majority vote).

    Returns None if nothing is detected or camera is unavailable.
    """
    if not CAMERA_AVAILABLE:
        logging.warning("[CAMERA] Mock mode — returning None.")
        time.sleep(1)
        return None

    picam2 = None
    try:
        picam2 = Picamera2()
        picam2.configure(picam2.create_preview_configuration())
        picam2.start()
        time.sleep(2)   # Warm-up / auto-exposure settle

        detected = []

        for i in range(samples):
            frame = picam2.capture_array()

            # --- Pre-processing for OCR accuracy ---
            gray   = cv2.cvtColor(frame, cv2.COLOR_RGB2GRAY)
            gray   = cv2.GaussianBlur(gray, (5, 5), 0)
            _, thr = cv2.threshold(gray, 0, 255,
                                   cv2.THRESH_BINARY + cv2.THRESH_OTSU)

            # Digits-only whitelist, single-line PSM
            cfg  = r'--oem 3 --psm 7 -c tessedit_char_whitelist=0123456789'
            text = pytesseract.image_to_string(thr, config=cfg)

            nums = re.findall(r'\d+', text)
            if nums:
                logging.info(f"[CAMERA] Sample {i+1}/{samples} → '{nums[0]}'")
                detected.append(nums[0])
            else:
                logging.debug(f"[CAMERA] Sample {i+1}/{samples} → no number")

            time.sleep(delay)

        picam2.close()

        if not detected:
            logging.warning("[CAMERA] No room number detected in any sample.")
            return None

        result = Counter(detected).most_common(1)[0][0]
        logging.info(f"[CAMERA] Final room number (majority vote): {result}")
        return result

    except Exception as e:
        logging.error(f"[CAMERA] Exception: {e}")
        if picam2:
            try:
                picam2.close()
            except Exception:
                pass
        return None