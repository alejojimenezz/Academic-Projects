import mediapipe as mp
import math

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

def letra_a(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['index_pip'])/ref < 0.3 and
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_b(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['middle_mcp'])/ref < 0.25 and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y < p['middle_pip'].y and
        p['ring_tip'].y < p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_c(p, ref, label):
    return (
        distancia(p['index_tip'], p['wrist'])/ref < 0.45/ref and
        distancia(p['ring_tip'], p['wrist'])/ref < 1.2 and
        0.2 < distancia(p['index_tip'], p['index_mcp'])/ref < 0.7 and
        0.2 < distancia(p['middle_tip'], p['middle_mcp'])/ref < 0.7 and
        0.2 < distancia(p['ring_tip'], p['ring_mcp'])/ref < 0.7 and
        0.2 < distancia(p['pinky_tip'], p['pinky_mcp'])/ref < 0.7 and
        0.15 < distancia(p['middle_tip'], p['thumb_tip'])/ref < 0.4
    )

def letra_d(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['middle_tip'])/ref < 0.2 and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and 
        p['ring_tip'].y > p['ring_pip'].y and 
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_e(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['middle_mcp'])/ref < 0.3 and
        distancia(p['index_tip'], p['index_mcp'])/ref < 0.1/ref and
        distancia(p['middle_tip'], p['middle_mcp'])/ref < 0.1/ref and
        distancia(p['ring_tip'], p['ring_mcp'])/ref < 0.1/ref and
        distancia(p['pinky_tip'], p['pinky_mcp'])/ref < 0.1/ref and
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_f(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['index_pip'])/ref < 0.3 and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_i(p, ref, label):
    return (
        distancia(p['pinky_tip'], p['wrist'])/ref > 0.5 and
        distancia(p['thumb_tip'], p['index_dip'])/ref < 0.5 and
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_k(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['middle_pip'])/ref < 0.2 and
        p['thumb_tip'].y < p['thumb_ip'].y and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y < p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_l(p, ref, label):
    if label == 'Right':
        return (
            distancia(p['thumb_tip'], p['middle_tip'])/ref > 0.2 and
            distancia(p['thumb_tip'], p['index_pip'])/ref > 0.5 and
            p['thumb_tip'].x < p['thumb_ip'].x and
            p['index_tip'].y < p['index_pip'].y and
            p['middle_tip'].y > p['middle_pip'].y and
            p['ring_tip'].y > p['ring_pip'].y and
            p['pinky_tip'].y > p['pinky_pip'].y
        )
    else:
        return (
            distancia(p['thumb_tip'], p['middle_tip'])/ref > 0.2 and
            distancia(p['thumb_tip'], p['index_pip'])/ref > 0.5 and
            p['thumb_tip'].x > p['thumb_ip'].x and
            p['index_tip'].y < p['index_pip'].y and
            p['middle_tip'].y > p['middle_pip'].y and
            p['ring_tip'].y > p['ring_pip'].y and
            p['pinky_tip'].y > p['pinky_pip'].y
        )

def letra_m(p, ref, label):
    return (
        distancia(p['pinky_tip'], p['wrist'])/ref < 0.5 and
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_n(p, ref, label):
    return (
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y < p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_o(p, ref, label):
    return (
        distancia(p['index_tip'], p['wrist'])/ref < 0.45/ref and
        distancia(p['ring_tip'], p['wrist'])/ref < 1.2 and
        0.2 < distancia(p['index_tip'], p['index_mcp'])/ref < 0.7 and
        0.2 < distancia(p['middle_tip'], p['middle_mcp'])/ref < 0.7 and
        0.2 < distancia(p['ring_tip'], p['ring_mcp'])/ref < 0.7 and
        0.2 < distancia(p['pinky_tip'], p['pinky_mcp'])/ref < 0.7 and
        distancia(p['middle_tip'], p['thumb_tip'])/ref < 0.15
    )

def letra_q(p, ref, label):
    return (
        distancia(p['index_tip'], p['thumb_tip'])/ref < 0.2 and
        distancia(p['middle_tip'], p['thumb_tip'])/ref < 0.2 and
        distancia(p['ring_tip'], p['thumb_tip'])/ref < 0.2 and
        p['thumb_tip'].y < p['thumb_mcp'].y and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y < p['middle_pip'].y and
        p['ring_tip'].y < p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_r(p, ref, label):
    if label == 'Right':
        return (
            p['index_tip'].y < p['index_pip'].y and
            p['middle_tip'].y < p['middle_pip'].y and
            p['index_tip'].x > p['middle_tip'].x and
            p['ring_tip'].y > p['ring_pip'].y and
            p['pinky_tip'].y > p['pinky_pip'].y
        )
    else:
        return (
            p['index_tip'].y < p['index_pip'].y and
            p['middle_tip'].y < p['middle_pip'].y and
            p['index_tip'].x < p['middle_tip'].x and
            p['ring_tip'].y > p['ring_pip'].y and
            p['pinky_tip'].y > p['pinky_pip'].y
        )
    
def letra_u(p, ref, label):
    return (
        distancia(p['thumb_tip'], p['middle_dip'])/ref < 0.5 and
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

def letra_v(p, ref, label):
    return (
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y < p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_w(p, ref, label):
    return (
        p['index_tip'].y < p['index_pip'].y and
        p['middle_tip'].y < p['middle_pip'].y and
        p['ring_tip'].y < p['ring_pip'].y and
        p['pinky_tip'].y > p['pinky_pip'].y
    )

def letra_y(p, ref, label):
    return (
        distancia(p['pinky_tip'], p['wrist'])/ref > 0.5 and
        distancia(p['thumb_tip'], p['index_dip'])/ref > 0.6 and
        p['index_tip'].y > p['index_pip'].y and
        p['middle_tip'].y > p['middle_pip'].y and
        p['ring_tip'].y > p['ring_pip'].y and
        p['pinky_tip'].y < p['pinky_pip'].y
    )

static_alphabet = {
    "A": letra_a,
    "B": letra_b,
    "C": letra_c,
    "D": letra_d,
    "E": letra_e,
    "F": letra_f,
    "I": letra_i,
    "K": letra_k,
    "L": letra_l,
    "M": letra_m,
    "N": letra_n,
    "O": letra_o,
    # "P": letra_p,
    "Q": letra_q,
    "R": letra_r,
    # "T": letra_t,
    "U": letra_u,
    "V": letra_v,
    "W": letra_w,
    # "X": letra_x,
    "Y": letra_y,
}

dynamic_alphabet = {
    # "G": letra_g,
    # "H": letra_h,
    # "J": letra_j,
    # "Ñ": letra_ñ,
    # "S": letra_s,
    # "Z": letra_z,
}