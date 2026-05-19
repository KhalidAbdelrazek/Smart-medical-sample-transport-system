from picamera2 import Picamera2
import cv2
import pytesseract
import time
from collections import Counter
import re

VALID_ROOMS = {"1", "2", "3"}

def read_room_number(samples=10, delay=0.3):

    picam2 = Picamera2()

    # =========================
    # Low resolution + High FPS
    # 320x240 @ 120 FPS
    # =========================
    video_config = picam2.create_video_configuration(
        main={"size": (320, 240), "format": "RGB888"},
        controls={"FrameDurationLimits": (8333, 8333)}  # ~120 FPS
    )

    picam2.configure(video_config)
    picam2.start()
    time.sleep(1)  # camera warmup

    while True:
        detected_numbers = []

        for i in range(samples):

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

            # OCR
            config = r'--oem 3 --psm 6 outputbase digits'
            text = pytesseract.image_to_string(thresh, config=config)

            # Extract numbers
            numbers = re.findall(r'\d+', text)

            if numbers:
                detected_numbers.append(numbers[0])
                print(f"Frame {i+1}: detected -> {numbers[0]}")
            else:
                print(f"Frame {i+1}: no number")

            time.sleep(delay)

        if not detected_numbers:
            print("No number detected, scanning again...\n")
            continue

        final_number = Counter(detected_numbers).most_common(1)[0][0]

        if final_number in VALID_ROOMS:
            picam2.close()
            return final_number
        else:
            print(f"'{final_number}' is not a valid room (1, 2 or 3), scanning again...\n")
