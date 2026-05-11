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

VALID_ROOMS = {"1", "2", "3"}

def read_room_number(samples: int = 10, delay: float = 0.3):
    """
    Captures `samples` frames, runs OCR on each, and returns the most
    frequently detected number string (majority vote).
    Only accepts room numbers 1, 2, or 3.
    Retries indefinitely until a valid room number is confidently detected.
    """
    if not CAMERA_AVAILABLE:
        logging.warning("[CAMERA] Mock mode — returning None.")
        time.sleep(1)
        return None

    attempt = 0

    while True:
        attempt += 1
        logging.info(f"[CAMERA] Scan attempt #{attempt}...")
        print(f"\n[CAMERA] Scan attempt #{attempt}")

        picam2 = None
        detected = []

        try:
            picam2 = Picamera2()
            picam2.configure(picam2.create_preview_configuration())
            picam2.start()
            time.sleep(2)   # Warm-up / auto-exposure settle

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
                    raw = nums[0]
                    if raw in VALID_ROOMS:
                        logging.info(f"[CAMERA] Sample {i+1}/{samples} → '{raw}' ✓ accepted")
                        print(f"[CAMERA] Sample {i+1}/{samples} scanned: {raw} ✓")
                        detected.append(raw)
                    else:
                        logging.warning(f"[CAMERA] Sample {i+1}/{samples} → '{raw}' ✗ ignored (not a valid room)")
                        print(f"[CAMERA] Sample {i+1}/{samples} scanned: {raw} ✗ (ignored)")
                else:
                    logging.debug(f"[CAMERA] Sample {i+1}/{samples} → no number")
                    print(f"[CAMERA] Sample {i+1}/{samples} scanned: (nothing)")

                time.sleep(delay)

            picam2.close()
            picam2 = None

        except Exception as e:
            logging.error(f"[CAMERA] Exception during scan: {e}")
            if picam2:
                try:
                    picam2.close()
                except Exception:
                    pass
            print(f"[CAMERA] Error during scan — retrying...")
            time.sleep(1)
            continue   # Retry on hardware/camera error too

        # ── Evaluate this attempt ────────────────────────────────────────
        if not detected:
            logging.warning(f"[CAMERA] Attempt #{attempt}: no valid room detected — retrying...")
            print(f"[CAMERA] Attempt #{attempt}: no valid room found — retrying...\n")
            time.sleep(0.5)
            continue   # Retry

        result = Counter(detected).most_common(1)[0][0]
        confidence = detected.count(result)

        logging.info(f"[CAMERA] Attempt #{attempt}: majority vote → Room {result}  ({confidence}/{len(detected)} valid samples)")
        print(f"[CAMERA] Attempt #{attempt} result: Room {result}  ({confidence}/{samples} samples agreed)")

        return result