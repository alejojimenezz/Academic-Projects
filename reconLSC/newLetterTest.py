import cv2
import mediapipe as mp
import math

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

def distancia(p1, p2):
    return math.sqrt((p2.x - p1.x)**2 + (p2.y - p1.y)**2)

def hand_map(landmarks):
    HandLandmark = mp.solutions.hands.HandLandmark
    return {
        'wrist': landmarks[HandLandmark.WRIST],
        'thumb_cmc': landmarks[HandLandmark.THUMB_CMC],
        'thumb_mcp': landmarks[HandLandmark.THUMB_MCP],
        'thumb_ip': landmarks[HandLandmark.THUMB_IP],
        'thumb_tip': landmarks[HandLandmark.THUMB_TIP],
        'index_mcp': landmarks[HandLandmark.INDEX_FINGER_MCP],
        'index_pip': landmarks[HandLandmark.INDEX_FINGER_PIP],
        'index_dip': landmarks[HandLandmark.INDEX_FINGER_DIP],
        'index_tip': landmarks[HandLandmark.INDEX_FINGER_TIP],
        'middle_mcp': landmarks[HandLandmark.MIDDLE_FINGER_MCP],
        'middle_pip': landmarks[HandLandmark.MIDDLE_FINGER_PIP],
        'middle_dip': landmarks[HandLandmark.MIDDLE_FINGER_DIP],
        'middle_tip': landmarks[HandLandmark.MIDDLE_FINGER_TIP],
        'ring_mcp': landmarks[HandLandmark.RING_FINGER_MCP],
        'ring_pip': landmarks[HandLandmark.RING_FINGER_PIP],
        'ring_dip': landmarks[HandLandmark.RING_FINGER_DIP],
        'ring_tip': landmarks[HandLandmark.RING_FINGER_TIP],
        'pinky_mcp': landmarks[HandLandmark.PINKY_MCP],
        'pinky_pip': landmarks[HandLandmark.PINKY_PIP],
        'pinky_dip': landmarks[HandLandmark.PINKY_DIP],
        'pinky_tip': landmarks[HandLandmark.PINKY_TIP]          
    }

# Funcion para alphabet.py #################################################################################
def letra_p(p, ref, label):
    return (
        distancia(p['index_tip'], p['middle_pip'])/ref < 0.3 and
        distancia(p['ring_tip'], p['wrist'])/ref < 0.25 and
        distancia(p['pinky_tip'], p['wrist'])/ref < 0.25 and
        p['middle_tip'].y > p['middle_pip'].y
        
    )

def letra_t(p, ref, label):
    if label == 'Right':
        return (
            distancia(p['index_pip'], p['thumb_ip'])/ref < 0.25 and
            p['index_tip'].x < p['index_pip'].x
        )
    else:
        return (
            distancia(p['index_pip'], p['thumb_ip'])/ref < 0.25 and
            p['index_tip'].x > p['index_pip'].x
        )

def letra_x(p, ref, label):
    return (
        distancia(p['index_tip'], p['middle_pip'])/ref < 0.5 and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )
############################################################################################################

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
            
            letra = None
            label = hand_label.classification[0].label  # 'Left' o 'Right'

            p = hand_map(hand_landmarks.landmark)
            ref = distancia(p['wrist'], p['middle_tip'])

            # ---- Nueva letra ----
            if letra_p(p, ref, label):  # Cambiar nombre de funcion
                letra = "P"             # Cambiar letra en diccionario

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