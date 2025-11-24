import cv2
import mediapipe as mp
from alphabet import static_alphabet, hand_map, distancia
from collections import deque   # Para almacenar elementos en forma de lista
# Elimina elementos antiguos, creando espacio para nuevos

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

movimientoJ = deque(maxlen=10) # Almacenar 10 puntos de movimiento
currentLetter = None
delayTimer = 0
delayTime = 120

cap = cv2.VideoCapture(0)

while cap.isOpened():
    ret, frame = cap.read()
    frame = cv2.flip(frame, 1)
    if not ret:
        continue
    
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)
    
    if results.multi_hand_landmarks:

        for hand_landmarks, hand_label in zip(results.multi_hand_landmarks, results.multi_handedness):
            mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            
            letter = None
            label = hand_label.classification[0].label

            p = hand_map(hand_landmarks.landmark)
            ref = distancia(p['wrist'], p['middle_tip'])

            for key, func in static_alphabet.items():
                if func(p, ref, label):
                    letter = key
                    break

            # Movimiento letra J
            pinky = p['pinky_tip']
            movimientoJ.append((pinky.x, pinky.y))

            if len(movimientoJ) == movimientoJ.maxlen:
                dx = movimientoJ[-1][0] - movimientoJ[0][0]
                dy = movimientoJ[-1][1] - movimientoJ[0][1]

                if dx > 0.05 and dy > 0.05:  # Puedes ajustar estos valores según tu cámara
                    letter = 'J'

            if delayTimer == 0 and letter:
                currentLetter = letter
                delayTimer = delayTime


            if delayTimer > 0 and currentLetter:
                cv2.putText(frame, f"Letra: {letter}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 0), 5)
                cv2.putText(frame, f"Letra: {letter}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 255, 255), 2)
                delayTimer -= 1

            #cv2.putText(frame, f"ref: {distancia(p['thumb_tip'], p['index_pip'])/ref}", (50, 100), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    cv2.imshow('Reconocimiento LSC', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    if cv2.getWindowProperty('Reconocimiento LSC', cv2.WND_PROP_VISIBLE) < 1:
        break

cap.release()
cv2.destroyAllWindows()