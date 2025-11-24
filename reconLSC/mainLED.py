import cv2
import mediapipe as mp
from alphabet import static_alphabet, hand_map, distancia

mp_hands = mp.solutions.hands
hands = mp_hands.Hands(min_detection_confidence=0.7, min_tracking_confidence=0.7)
mp_drawing = mp.solutions.drawing_utils

cap = cv2.VideoCapture(0)

letra_actual = None

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

            label = hand_label.classification[0].label
            p = hand_map(hand_landmarks.landmark)
            ref = distancia(p['wrist'], p['middle_tip'])

            letra_actual = None
            for key, func in static_alphabet.items():
                if func(p, ref, label):
                    letra_actual = key
                    break

            if letra_actual:
                cv2.putText(frame, f"Letra: {letra_actual}", (50, 50),
                            cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)

    # LED simulado
    led_center = (550, 50)
    led_radius = 30

    if letra_actual == "L":
        led_color = (0, 0, 255)
        texto_led = "LED ENCENDIDO"
    else:
        led_color = (100, 100, 100)
        texto_led = "LED APAGADO"

    # Dibujar círculo LED y texto
    cv2.circle(frame, led_center, led_radius, led_color, -1)
    cv2.putText(frame, texto_led, (led_center[0] - 100, led_center[1] + 60),
                cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 255, 255), 2)

    # Mostrar la ventana
    cv2.imshow('Reconocimiento LSC', frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    if cv2.getWindowProperty('Reconocimiento LSC', cv2.WND_PROP_VISIBLE) < 1:
        break

cap.release()
cv2.destroyAllWindows()