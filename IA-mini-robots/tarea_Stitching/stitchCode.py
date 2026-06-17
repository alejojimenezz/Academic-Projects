import cv2
import numpy as np
import matplotlib.pyplot as plt

def detectar_y_describir(imagen):

    gray = cv2.cvtColor(imagen, cv2.COLOR_BGR2GRAY)

    sift = cv2.SIFT_create()

    keypoints, descriptores = sift.detectAndCompute(gray, None)

    return keypoints, descriptores


def matching(desc1, desc2):
    
    bf = cv2.BFMatcher(cv2.NORM_L2)

    matches = bf.knnMatch(desc1, desc2, k=2)

    buenos = []

    for m, n in matches:

        if m.distance < 0.75 * n.distance:
            buenos.append(m)

    return buenos


def homografia(kp1, kp2, matches):
    
    puntos_img1 = np.float32(
        [kp1[m.queryIdx].pt for m in matches]
    ).reshape(-1, 1, 2)

    puntos_img2 = np.float32(
        [kp2[m.trainIdx].pt for m in matches]
    ).reshape(-1, 1, 2)

    H, mascara = cv2.findHomography(
        puntos_img1,
        puntos_img2,
        cv2.RANSAC,
        5.0
    )

    return H, mascara


def crear_panorama(img1, img2, H):
    
    alto1, ancho1 = img1.shape[:2]
    alto2, ancho2 = img2.shape[:2]

    esquinas_img1 = np.float32([
        [0, 0],
        [0, alto1],
        [ancho1, alto1],
        [ancho1, 0]
    ]).reshape(-1, 1, 2)

    esquinas_transformadas = cv2.perspectiveTransform(
        esquinas_img1,
        H
    )

    esquinas_img2 = np.float32([
        [0, 0],
        [0, alto2],
        [ancho2, alto2],
        [ancho2, 0]
    ]).reshape(-1, 1, 2)

    todas_esquinas = np.concatenate(
        (esquinas_transformadas, esquinas_img2),
        axis=0
    )

    [xmin, ymin] = np.int32(
        todas_esquinas.min(axis=0).ravel() - 0.5
    )

    [xmax, ymax] = np.int32(
        todas_esquinas.max(axis=0).ravel() + 0.5
    )

    translacion = [-xmin, -ymin]

    H_translacion = np.array([
        [1, 0, translacion[0]],
        [0, 1, translacion[1]],
        [0, 0, 1]
    ])

    panorama = cv2.warpPerspective(
        img1,
        H_translacion @ H,
        (xmax - xmin, ymax - ymin)
    )

    panorama[
        translacion[1]:alto2 + translacion[1],
        translacion[0]:ancho2 + translacion[0]
    ] = img2

    return panorama


def mostrar_imagen(titulo, imagen):

    imagen_rgb = cv2.cvtColor(imagen, cv2.COLOR_BGR2RGB)

    plt.figure(figsize=(15, 8))
    plt.title(titulo)
    plt.imshow(imagen_rgb)
    plt.axis("off")
    plt.show()



img1 = cv2.imread("images/Flores1.jpg")
img2 = cv2.imread("images/Flores2.jpg")

kp1, desc1 = detectar_y_describir(img1)
kp2, desc2 = detectar_y_describir(img2)

print(f"Keypoints imagen 1: {len(kp1)}")
print(f"Keypoints imagen 2: {len(kp2)}")

img_kp1 = cv2.drawKeypoints(
    img1,
    kp1,
    None,
    flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS
)

img_kp2 = cv2.drawKeypoints(
    img2,
    kp2,
    None,
    flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS
)

mostrar_imagen("Keypoints Imagen 1", img_kp1)
mostrar_imagen("Keypoints Imagen 2", img_kp2)

matches_buenos = matching(desc1, desc2)

print(f"Matches buenos: {len(matches_buenos)}")

img_matches = cv2.drawMatches(
    img1,
    kp1,
    img2,
    kp2,
    matches_buenos,
    None,
    flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS
)

mostrar_imagen("Matches", img_matches)

H, mascara = homografia(
    kp1,
    kp2,
    matches_buenos
)

print("Homografía:")
print(H)

panorama = crear_panorama(img1, img2, H)

mostrar_imagen("Panorama Final", panorama)

cv2.imwrite("images/panorama_resultado.jpg", panorama)