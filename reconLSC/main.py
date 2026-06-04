import cv2
import mediapipe as mp
from limitFrame import get_hand_roi
from alphabet import static_alphabet, hand_map, distancia

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        continue
    frame = cv2.flip(frame, 1)

    roi, roi_x, roi_y = get_hand_roi(frame)
    
    # rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    # results = hands.process(rgb_frame)

    if roi is not None and roi.size > 0:
        h_roi, w_roi = roi.shape[:2]
        cv2.rectangle(frame,
                      (roi_x, roi_y),
                      (roi_x + w_roi, roi_y + h_roi),
                      (0, 255, 0), 2)

        rgb_roi = cv2.cvtColor(roi, cv2.COLOR_BGR2RGB)
        results = hands.process(rgb_roi)
    else:
        rgb_roi = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(rgb_roi)
        roi_x, roi_y = 0, 0
        roi = frame
    
    if results.multi_hand_landmarks:

        for hand_landmarks, hand_label in zip(results.multi_hand_landmarks, results.multi_handedness):
            
            h_roi, w_roi = roi.shape[:2]
            H, W = frame.shape[:2]

            class RemappedLandmarks:
                def __init__(self, lm, rx, ry, rw, rh):
                    self.landmark = []
                    for p in lm.landmark:
                        class Pt:
                            pass
                        pt = Pt()
                        pt.x = (p.x * rw + rx) / W
                        pt.y = (p.y * rh + ry) / H
                        pt.z = p.z
                        self.landmark.append(pt)

            remapped = RemappedLandmarks(hand_landmarks, roi_x, roi_y, w_roi, h_roi)
            mp_drawing.draw_landmarks(roi, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            frame[roi_y:roi_y + h_roi, roi_x:roi_x + w_roi] = roi
            
            label = hand_label.classification[0].label
            p = hand_map(hand_landmarks.landmark)
            ref = distancia(p['wrist'], p['middle_tip'])

            letter = None

            for key, func in static_alphabet.items():
                if func(p, ref, label):
                    letter = key
                    break

            if letter:
                cv2.putText(frame, f"Letra: {letter}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 0), 5)
                cv2.putText(frame, f"Letra: {letter}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)

            #cv2.putText(frame, f"ref: {distancia(p['thumb_tip'], p['index_pip'])/ref}", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

            finger_tips = [
                'thumb_tip',
                'index_tip',
                'middle_tip',
                'ring_tip',
                'pinky_tip'
            ]

            h, w, _ = frame.shape

            if cv2.waitKey(1) & 0xFF == ord('c'):
                for finger in finger_tips:
                    x = int(p[finger].x * w)
                    y = int(p[finger].y * h)

                    cv2.circle(frame, (x, y), 5, (255, 0, 0), -1)

                    cv2.putText(frame,
                                f"({x},{y})",
                                (x + 10, y - 10),
                                cv2.FONT_HERSHEY_SIMPLEX,
                                0.4,
                                (255,255,255),
                                1)

    cv2.imshow('Reconocimiento LSC', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    if cv2.getWindowProperty('Reconocimiento LSC', cv2.WND_PROP_VISIBLE) < 1:
        break

cap.release()
cv2.destroyAllWindows()