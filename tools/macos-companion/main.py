import cv2
import mediapipe as mp
from PIL import Image
import numpy as np
import threading
from flask import Flask, request, jsonify, send_file
from pathlib import Path
import datetime
import sys
import os

# --- Flask API (runs in background thread) ---
app = Flask(__name__)
LOG_FILE = Path(__file__).parent / "lilithos_api.log"
CREST_PATH = Path(__file__).parent / "khandokar_crest.png"

@app.route("/log", methods=["POST"])
def log():
    data = request.json
    entry = f"[{datetime.datetime.now().isoformat()}] {data.get('message', '')}\n"
    with open(LOG_FILE, "a") as f:
        f.write(entry)
    return jsonify({"status": "logged"})

@app.route("/command", methods=["POST"])
def command():
    data = request.json
    return jsonify({"status": "command received", "command": data.get('command', '')})

@app.route("/crest", methods=["GET"])
def crest():
    return send_file(CREST_PATH, mimetype='image/png')

def run_flask():
    app.run(host="127.0.0.1", port=5050, debug=False, use_reloader=False)

# --- Ritual Log ---
def ritual_log(message):
    print(f"[LilithOS-Mac][KHANDOKAR-CREST] :: {message}")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{datetime.datetime.now().isoformat()}] {message}\n")

# --- Hand Tracking & Crest Overlay ---
def main():
    # Start Flask API in background
    threading.Thread(target=run_flask, daemon=True).start()
    ritual_log("Flask API started on port 5050.")
    # Camera and hand tracking
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
    cap = cv2.VideoCapture(0)
    crest_img = None
    if CREST_PATH.exists():
        crest_img = Image.open(CREST_PATH).convert("RGBA")
        crest_img = crest_img.resize((96, 96))
    ritual_log("Holographic ritual initiated. Camera online.")
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            ritual_log("Camera feed lost.")
            break
        frame = cv2.flip(frame, 1)
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(rgb)
        if results.multi_hand_landmarks:
            for hand_landmarks in results.multi_hand_landmarks:
                tip = hand_landmarks.landmark[8]  # Index fingertip
                pip = hand_landmarks.landmark[6]  # Index PIP
                h, w, _ = frame.shape
                cx, cy = int(tip.x * w), int(tip.y * h)
                # Overlay crest at fingertip
                if crest_img is not None:
                    frame_pil = Image.fromarray(cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)).convert("RGBA")
                    frame_pil.paste(crest_img, (cx-48, cy-48), crest_img)
                    frame = cv2.cvtColor(np.array(frame_pil), cv2.COLOR_RGBA2BGR)
                else:
                    cv2.circle(frame, (cx, cy), 32, (0,255,0), 2)
                # Gesture detection
                gesture = "open_palm" if tip.y < pip.y else "fist"
                ritual_log(f"Gesture: {gesture} at ({cx},{cy})")
                # Draw landmarks
                mp.solutions.drawing_utils.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
        # Matrix effect
        for i in range(0, frame.shape[1], 40):
            cv2.line(frame, (i, 0), (i, frame.shape[0]), (0, 255, 0), 1)
        cv2.imshow('LilithOS Mac Holographic', frame)
        if cv2.waitKey(1) & 0xFF == 27:
            break
    cap.release()
    cv2.destroyAllWindows()
    ritual_log("Holographic ritual ended.")

if __name__ == "__main__":
    main() 