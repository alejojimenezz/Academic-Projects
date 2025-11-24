import cv2
import mediapipe as mp
import math

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

def distancia(p1, p2):
    return math.sqrt((p2.x - p1.x)**2 + (p2.y - p1.y)**2)

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        continue
    
    rgb_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    results = hands.process(rgb_frame)
    
    if results.multi_hand_landmarks:
        for hand_landmarks in results.multi_hand_landmarks:
            mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
            
            thumb_tip = hand_landmarks.landmark[mp_hands.HandLandmark.THUMB_TIP]
            index_tip = hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_TIP]
            middle_tip = hand_landmarks.landmark[mp_hands.HandLandmark.MIDDLE_FINGER_TIP]
            ring_tip = hand_landmarks.landmark[mp_hands.HandLandmark.RING_FINGER_TIP]
            pinky_tip = hand_landmarks.landmark[mp_hands.HandLandmark.PINKY_TIP]
            
            # Obtener bases de los dedos (para ver si están cerrados)
            index_pip = hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_PIP]
            middle_pip = hand_landmarks.landmark[mp_hands.HandLandmark.MIDDLE_FINGER_PIP]
            ring_pip = hand_landmarks.landmark[mp_hands.HandLandmark.RING_FINGER_PIP]
            pinky_pip = hand_landmarks.landmark[mp_hands.HandLandmark.PINKY_PIP]
            
            letra = None
            
            # ---- Condiciones Mejoradas ----
            # Letra "B": Todos los dedos extendidos y rectos
            if (index_tip.y < index_pip.y and middle_tip.y < middle_pip.y and 
                ring_tip.y < ring_pip.y and pinky_tip.y < pinky_pip.y):
                letra = "B"
            
            # Letra "A": Pulgar cerca de la base del índice Y otros dedos cerrados
            elif (distancia(thumb_tip, hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_MCP]) < 0.1 and
                index_tip.y > index_pip.y and  # Índice cerrado
                middle_tip.y > middle_pip.y and 
                ring_tip.y > ring_pip.y and 
                pinky_tip.y > pinky_pip.y):
                letra = "A"
            
            # Letra "D": Solo índice extendido, otros cerrados, pulgar no en "A"
            elif (index_tip.y < index_pip.y and  # Índice extendido
                distancia(thumb_tip, hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_MCP]) > 0.15 and  # Pulgar lejos del índice
                middle_tip.y > middle_pip.y and 
                ring_tip.y > ring_pip.y and 
                pinky_tip.y > pinky_pip.y):
                letra = "L"
            
            # Letra "L": Índice extendido, pulgar horizontal, otros dedos cerrados
            elif (index_tip.y < index_pip.y and 
                  thumb_tip.x < hand_landmarks.landmark[mp_hands.HandLandmark.THUMB_IP].x and
                  middle_tip.y > middle_pip.y and ring_tip.y > ring_pip.y and pinky_tip.y > pinky_pip.y):
                letra = "D"
            
            # Letra "C": Dedos curvados (punta cerca de la muñeca)
            elif (distancia(index_tip, hand_landmarks.landmark[mp_hands.HandLandmark.WRIST]) < 0.3 and
                  distancia(middle_tip, hand_landmarks.landmark[mp_hands.HandLandmark.WRIST]) < 0.3):
                letra = "C"
            
            # Mostrar letra
            if letra:
                cv2.putText(frame, f"Letra: {letra}", (50, 50), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    
    cv2.imshow('Reconocimiento LSC', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    if cv2.getWindowProperty('Reconocimiento LSC', cv2.WND_PROP_VISIBLE) < 1:
        break

cap.release()
cv2.destroyAllWindows()