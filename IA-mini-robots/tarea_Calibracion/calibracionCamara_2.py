"""
================================================================================
TALLER – CALIBRACIÓN DE CÁMARA
Inteligencia Artificial & Mini Robots
Prof. Flavio Prieto – Universidad Nacional de Colombia
================================================================================
Autor: [Tu nombre]
Fecha: Mayo 2026

Este script implementa las 8 partes del taller de calibración de cámara usando
OpenCV y patrones de ajedrez (chessboard). Como no se dispone de imágenes reales
de cámara, se generan imágenes sintéticas con distorsión conocida para demostrar
todo el pipeline completo.
================================================================================
"""

import cv2
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.patches import FancyArrowPatch
import os, time, warnings
warnings.filterwarnings('ignore')

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ─────────────────────────────────────────────────────────────────────────────
BOARD_SIZE   = (9, 6)          # esquinas internas del tablero (cols, filas)
SQUARE_SIZE  = 0.025           # tamaño de cada cuadro en metros (2.5 cm)
N_IMAGES     = 20              # número de imágenes sintéticas a generar
IMG_W, IMG_H = 640, 480        # resolución de las imágenes

# Parámetros intrínsecos "verdaderos" de la cámara simulada
K_TRUE = np.array([
    [520.0,   0.0, 320.0],
    [  0.0, 520.0, 240.0],
    [  0.0,   0.0,   1.0]
], dtype=np.float64)

# Coeficientes de distorsión "verdaderos" [k1, k2, p1, p2, k3]
DIST_TRUE = np.array([-0.28, 0.12, 0.001, 0.002, -0.04], dtype=np.float64)

OUTPUT_DIR = "resultados_calibracion"
os.makedirs(OUTPUT_DIR, exist_ok=True)

print("=" * 70)
print("  TALLER – CALIBRACIÓN DE CÁMARA")
print("  Universidad Nacional de Colombia")
print("=" * 70)


# ─────────────────────────────────────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────────────────────────────────────

def save_fig(fig, name):
    path = os.path.join(OUTPUT_DIR, name)
    fig.savefig(path, dpi=120, bbox_inches='tight')
    print(f"  ✔ Guardado: {path}")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 1: ADQUISICIÓN Y PREPROCESAMIENTO
# Generamos imágenes sintéticas del patrón con distintas poses y ruido
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 1: Adquisición y Preprocesamiento")
print("─" * 70)

def generar_puntos_3d(board_size, square_size):
    """Genera los puntos 3D del tablero (Z=0, plano del patrón)."""
    pts = np.zeros((board_size[0] * board_size[1], 3), dtype=np.float32)
    pts[:, :2] = np.mgrid[0:board_size[0], 0:board_size[1]].T.reshape(-1, 2)
    pts *= square_size
    return pts

def generar_imagen_sintetica(K, dist, board_size, square_size, img_w, img_h,
                              ruido_px=0.5):
    """
    Genera una imagen sintética del tablero con una pose aleatoria.
    Devuelve (imagen_gris, rvec, tvec, corners_2d_limpios).
    """
    obj_pts = generar_puntos_3d(board_size, square_size)

    # Pose aleatoria: rotación y traslación
    angulos = np.random.uniform(-0.5, 0.5, 3)
    rvec = angulos.astype(np.float64)
    tvec = np.array([
        np.random.uniform(-0.1, 0.1),
        np.random.uniform(-0.1, 0.1),
        np.random.uniform(0.35, 0.55)
    ], dtype=np.float64)

    # Proyectar puntos 3D → 2D con distorsión
    corners_2d, _ = cv2.projectPoints(obj_pts, rvec, tvec, K, dist)
    corners_2d = corners_2d.reshape(-1, 2)

    # Verificar que todos los puntos queden dentro de la imagen
    margen = 10
    if (corners_2d[:, 0].min() < margen or corners_2d[:, 0].max() > img_w - margen or
        corners_2d[:, 1].min() < margen or corners_2d[:, 1].max() > img_h - margen):
        return None, None, None, None

    # Crear imagen con el tablero dibujado
    img = np.ones((img_h, img_w), dtype=np.uint8) * 200
    corners_int = corners_2d.astype(np.int32)

    for r in range(board_size[1] + 1):
        for c in range(board_size[0] + 1):
            # Índice del cuadro
            c0 = c * square_size
            r0 = r * square_size
            pts_cuadro = np.array([[c0, r0, 0], [c0 + square_size, r0, 0],
                                    [c0 + square_size, r0 + square_size, 0],
                                    [c0, r0 + square_size, 0]], dtype=np.float64)
            p2d, _ = cv2.projectPoints(pts_cuadro, rvec, tvec, K, dist)
            p2d = p2d.reshape(-1, 1, 2).astype(np.int32)
            color = 255 if (r + c) % 2 == 0 else 0
            cv2.fillConvexPoly(img, p2d, color)

    # Añadir ruido gaussiano
    ruido = np.random.normal(0, 10, img.shape).astype(np.int16)
    img = np.clip(img.astype(np.int16) + ruido, 0, 255).astype(np.uint8)

    # Ruido en las esquinas detectadas (simulación de error de detección)
    corners_ruidosos = corners_2d + np.random.normal(0, ruido_px, corners_2d.shape)
    corners_ruidosos = corners_ruidosos.astype(np.float32).reshape(-1, 1, 2)

    return img, rvec, tvec, corners_ruidosos

# Generar el conjunto de imágenes
print(f"  Generando {N_IMAGES} imágenes sintéticas del tablero {BOARD_SIZE[0]}×{BOARD_SIZE[1]}...")
np.random.seed(42)

imagenes      = []
corners_reales = []
obj_pts_lista  = []
obj_pts_base   = generar_puntos_3d(BOARD_SIZE, SQUARE_SIZE)

intentos = 0
while len(imagenes) < N_IMAGES and intentos < N_IMAGES * 5:
    img, rvec, tvec, corners = generar_imagen_sintetica(
        K_TRUE, DIST_TRUE, BOARD_SIZE, SQUARE_SIZE, IMG_W, IMG_H, ruido_px=0.4)
    if img is not None:
        imagenes.append(img)
        corners_reales.append(corners)
        obj_pts_lista.append(obj_pts_base.copy())
    intentos += 1

N_OK = len(imagenes)
print(f"  ✔ {N_OK} imágenes generadas correctamente.")

# Convertir a escala de grises y mostrar muestra
print("  Convirtiendo a escala de grises y verificando iluminación...")
imagenes_gray = [img.copy() for img in imagenes]  # ya están en gris (1 canal)

# Visualización de muestra (4 imágenes)
fig, axes = plt.subplots(2, 4, figsize=(16, 7))
fig.suptitle("Parte 1 – Muestra de imágenes del patrón de calibración\n"
             "(Generadas sintéticamente con distintas poses y ruido)", fontsize=13)
for i, ax in enumerate(axes.flat):
    if i < N_OK:
        ax.imshow(imagenes[i], cmap='gray', vmin=0, vmax=255)
        ax.set_title(f"Imagen {i+1}", fontsize=9)
    ax.axis('off')
plt.tight_layout()
save_fig(fig, "parte1_muestra_imagenes.png")
plt.show()

# Histogramas de intensidad de 4 imágenes
fig, axes = plt.subplots(1, 4, figsize=(14, 3))
fig.suptitle("Parte 1 – Histogramas de intensidad (verificación de iluminación)", fontsize=12)
for i, ax in enumerate(axes):
    hist = cv2.calcHist([imagenes[i]], [0], None, [256], [0, 256])
    ax.plot(hist, color='steelblue')
    ax.set_title(f"Imagen {i+1}", fontsize=9)
    ax.set_xlabel("Intensidad"); ax.set_ylabel("Frecuencia")
    ax.grid(True, alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte1_histogramas.png")
plt.show()

print("  ✔ Parte 1 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 2: DETECCIÓN DE PUNTOS DE CALIBRACIÓN
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 2: Detección de Puntos de Calibración")
print("─" * 70)

# En imágenes reales se usaría cv2.findChessboardCorners + cornerSubPix.
# Con imágenes sintéticas usamos los corners proyectados directamente
# (que incluyen el ruido añadido en la generación).
print("  Usando corners proyectados sintéticamente (con ruido de detección).")
print(f"  Puntos 2D por imagen: {BOARD_SIZE[0] * BOARD_SIZE[1]}")
print(f"  Total de puntos: {N_OK * BOARD_SIZE[0] * BOARD_SIZE[1]}")

# Visualizar corners detectados en 4 imágenes
criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
fig, axes = plt.subplots(2, 4, figsize=(16, 8))
fig.suptitle("Parte 2 – Esquinas detectadas (p_i = (u_i, v_i))", fontsize=13)
for i, ax in enumerate(axes.flat):
    if i < N_OK:
        img_color = cv2.cvtColor(imagenes[i], cv2.COLOR_GRAY2BGR)
        cv2.drawChessboardCorners(img_color, BOARD_SIZE, corners_reales[i], True)
        ax.imshow(cv2.cvtColor(img_color, cv2.COLOR_BGR2RGB))
        ax.set_title(f"Imagen {i+1} – {BOARD_SIZE[0]*BOARD_SIZE[1]} pts", fontsize=9)
    ax.axis('off')
plt.tight_layout()
save_fig(fig, "parte2_corners_detectados.png")
plt.show()

# Análisis de distribución espacial de corners
fig, ax = plt.subplots(figsize=(7, 5))
for i in range(min(N_OK, 8)):
    pts = corners_reales[i].reshape(-1, 2)
    ax.scatter(pts[:, 0], pts[:, 1], s=5, alpha=0.5, label=f"Img {i+1}")
ax.set_xlim(0, IMG_W); ax.set_ylim(IMG_H, 0)
ax.set_title("Parte 2 – Distribución espacial de esquinas detectadas\n(primeras 8 imágenes)")
ax.set_xlabel("u (píxeles)"); ax.set_ylabel("v (píxeles)")
ax.legend(fontsize=7, ncol=2); ax.grid(True, alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte2_distribucion_corners.png")
plt.show()

print("  ✔ Parte 2 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 3: ESTIMACIÓN DE PARÁMETROS INTRÍNSECOS
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 3: Estimación de Parámetros Intrínsecos")
print("─" * 70)

ret, K_est, dist_est, rvecs_est, tvecs_est = cv2.calibrateCamera(
    obj_pts_lista, corners_reales, (IMG_W, IMG_H), None, None
)

print(f"\n  RMS de reproyección (calibración completa): {ret:.4f} píxeles")
print("\n  Matriz intrínseca estimada K:")
print(f"    fx = {K_est[0,0]:.2f} px    fy = {K_est[1,1]:.2f} px")
print(f"    cx = {K_est[0,2]:.2f} px    cy = {K_est[1,2]:.2f} px")
print(f"\n  Valores verdaderos:")
print(f"    fx = {K_TRUE[0,0]:.2f} px    fy = {K_TRUE[1,1]:.2f} px")
print(f"    cx = {K_TRUE[0,2]:.2f} px    cy = {K_TRUE[1,2]:.2f} px")

# Error relativo en cada parámetro
params = ['fx', 'fy', 'cx', 'cy']
vals_est  = [K_est[0,0], K_est[1,1], K_est[0,2], K_est[1,2]]
vals_true = [K_TRUE[0,0], K_TRUE[1,1], K_TRUE[0,2], K_TRUE[1,2]]
errores_k = [abs(e - t) / t * 100 for e, t in zip(vals_est, vals_true)]
print("\n  Error relativo (%):")
for p, e in zip(params, errores_k):
    print(f"    {p}: {e:.3f}%")

# Estabilidad: calibrar con subconjuntos crecientes de imágenes
print("\n  Evaluando estabilidad con subconjuntos crecientes de imágenes...")
subsets = list(range(5, N_OK + 1, 2))
fx_sub, fy_sub, cx_sub, cy_sub = [], [], [], []
for n in subsets:
    _, K_sub, _, _, _ = cv2.calibrateCamera(
        obj_pts_lista[:n], corners_reales[:n], (IMG_W, IMG_H), None, None)
    fx_sub.append(K_sub[0, 0]); fy_sub.append(K_sub[1, 1])
    cx_sub.append(K_sub[0, 2]); cy_sub.append(K_sub[1, 2])

fig, axes = plt.subplots(2, 2, figsize=(12, 7))
fig.suptitle("Parte 3 – Estabilidad de parámetros intrínsecos vs. N° de imágenes", fontsize=13)
for ax, vals, ref, name in zip(axes.flat,
                                [fx_sub, fy_sub, cx_sub, cy_sub],
                                [K_TRUE[0,0], K_TRUE[1,1], K_TRUE[0,2], K_TRUE[1,2]],
                                ['fx', 'fy', 'cx', 'cy']):
    ax.plot(subsets, vals, 'o-', color='steelblue', markersize=4, label='Estimado')
    ax.axhline(ref, color='tomato', linestyle='--', label='Valor verdadero')
    ax.set_title(f"Parámetro {name}"); ax.set_xlabel("N° de imágenes")
    ax.set_ylabel("Valor (píxeles)"); ax.legend(); ax.grid(True, alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte3_estabilidad_intrinsecos.png")
plt.show()

# Tabla resumen
fig, ax = plt.subplots(figsize=(8, 3))
ax.axis('off')
tabla = [["Parámetro", "Valor verdadero", "Valor estimado", "Error (%)"],
         ["fx (px)",  f"{K_TRUE[0,0]:.2f}", f"{K_est[0,0]:.2f}", f"{errores_k[0]:.3f}"],
         ["fy (px)",  f"{K_TRUE[1,1]:.2f}", f"{K_est[1,1]:.2f}", f"{errores_k[1]:.3f}"],
         ["cx (px)",  f"{K_TRUE[0,2]:.2f}", f"{K_est[0,2]:.2f}", f"{errores_k[2]:.3f}"],
         ["cy (px)",  f"{K_TRUE[1,2]:.2f}", f"{K_est[1,2]:.2f}", f"{errores_k[3]:.3f}"],
         ["Relación aspecto (fx/fy)", f"{K_TRUE[0,0]/K_TRUE[1,1]:.4f}",
          f"{K_est[0,0]/K_est[1,1]:.4f}", "–"]]
t = ax.table(cellText=tabla[1:], colLabels=tabla[0], cellLoc='center', loc='center')
t.auto_set_font_size(False); t.set_fontsize(10); t.scale(1.2, 1.5)
ax.set_title("Parte 3 – Resumen de parámetros intrínsecos", fontsize=12, pad=20)
plt.tight_layout()
save_fig(fig, "parte3_tabla_intrinsecos.png")
plt.show()

print("  ✔ Parte 3 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 4: ESTIMACIÓN DE DISTORSIÓN
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 4: Estimación de Distorsión")
print("─" * 70)

print("\n  Coeficientes de distorsión estimados D = [k1, k2, p1, p2, k3]:")
labels_dist = ['k1', 'k2', 'p1', 'p2', 'k3']
dist_flat = dist_est.flatten()
for l, e, t in zip(labels_dist, dist_flat, DIST_TRUE):
    print(f"    {l}: estimado = {e:+.5f}   verdadero = {t:+.5f}   "
          f"error = {abs(e-t):.5f}")

# Visualizar el campo de distorsión radial y tangencial
u_lin = np.linspace(0, IMG_W, 30)
v_lin = np.linspace(0, IMG_H, 30)
UU, VV = np.meshgrid(u_lin, v_lin)
puntos = np.stack([UU.ravel(), VV.ravel()], axis=1).astype(np.float32)

def distorsion_campo(puntos, K, dist):
    """Calcula el desplazamiento que introduce la distorsión."""
    pts_norm = cv2.undistortPoints(puntos.reshape(-1,1,2), K, dist, P=K)
    dx = pts_norm.reshape(-1,2)[:,0] - puntos[:,0]
    dy = pts_norm.reshape(-1,2)[:,1] - puntos[:,1]
    return dx, dy

dx_true, dy_true = distorsion_campo(puntos, K_TRUE, DIST_TRUE)
dx_est,  dy_est  = distorsion_campo(puntos, K_est,  dist_est)
mag_true = np.sqrt(dx_true**2 + dy_true**2).reshape(UU.shape)
mag_est  = np.sqrt(dx_est**2  + dy_est**2 ).reshape(UU.shape)

fig, axes = plt.subplots(1, 2, figsize=(13, 5))
fig.suptitle("Parte 4 – Campo de distorsión (magnitud en píxeles)", fontsize=13)
for ax, mag, title in zip(axes, [mag_true, mag_est],
                           ["Distorsión verdadera", "Distorsión estimada"]):
    im = ax.contourf(UU, VV, mag, levels=20, cmap='RdYlBu_r')
    ax.quiver(UU[::3,::3], VV[::3,::3],
              (dx_true if 'verd' in title else dx_est).reshape(UU.shape)[::3,::3],
              (dy_true if 'verd' in title else dy_est).reshape(UU.shape)[::3,::3],
              scale=150, color='black', alpha=0.6, width=0.003)
    plt.colorbar(im, ax=ax, label='Desplazamiento (px)')
    ax.set_title(title); ax.set_xlabel("u (px)"); ax.set_ylabel("v (px)")
    ax.invert_yaxis()
plt.tight_layout()
save_fig(fig, "parte4_campo_distorsion.png")
plt.show()

# Comparación de coeficientes
fig, ax = plt.subplots(figsize=(8, 4))
x = np.arange(5)
w = 0.35
ax.bar(x - w/2, DIST_TRUE, w, label='Verdadero', color='steelblue', alpha=0.8)
ax.bar(x + w/2, dist_flat,  w, label='Estimado',  color='tomato',    alpha=0.8)
ax.set_xticks(x); ax.set_xticklabels(labels_dist, fontsize=11)
ax.axhline(0, color='black', linewidth=0.8)
ax.set_title("Parte 4 – Coeficientes de distorsión: verdadero vs. estimado")
ax.set_ylabel("Valor del coeficiente"); ax.legend(); ax.grid(True, axis='y', alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte4_coeficientes_distorsion.png")
plt.show()

print("  ✔ Parte 4 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 5: CALIBRACIÓN EXTRÍNSECA
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 5: Calibración Extrínseca")
print("─" * 70)

# Los rvecs y tvecs ya fueron estimados en cv2.calibrateCamera
# Mostramos los primeros 4 poses
print("\n  Primeras 4 poses estimadas (Pc = R·Pw + t):")
for i in range(min(4, N_OK)):
    R, _ = cv2.Rodrigues(rvecs_est[i])
    t    = tvecs_est[i].flatten()
    print(f"\n  Imagen {i+1}:")
    print(f"    t = [{t[0]:+.4f}, {t[1]:+.4f}, {t[2]:+.4f}] m")
    angulo = np.degrees(np.linalg.norm(rvecs_est[i]))
    print(f"    Ángulo de rotación = {angulo:.2f}°")

# Visualización 3D de las poses de cámara
fig = plt.figure(figsize=(10, 7))
ax  = fig.add_subplot(111, projection='3d')

# Tablero en el plano Z=0
board_3d = obj_pts_base.reshape(-1, 3)
ax.scatter(board_3d[:,0], board_3d[:,1], board_3d[:,2],
           c='black', s=20, zorder=5)

# Ejes de cada pose de cámara
colores = plt.cm.tab10(np.linspace(0, 1, N_OK))
eje_len = 0.05
for i in range(N_OK):
    R, _ = cv2.Rodrigues(rvecs_est[i])
    t    = tvecs_est[i].flatten()
    # Posición de la cámara en coordenadas del mundo
    C = -R.T @ t
    for j, (eje, col) in enumerate(zip(R.T, ['r','g','b'])):
        ax.quiver(*C, *eje*eje_len, color=col, linewidth=1.2, alpha=0.7)

ax.set_xlabel("X (m)"); ax.set_ylabel("Y (m)"); ax.set_zlabel("Z (m)")
ax.set_title("Parte 5 – Poses de cámara estimadas\n(rojo=X, verde=Y, azul=Z)", fontsize=12)
ax.set_xlim(-0.15, 0.35); ax.set_ylim(-0.1, 0.2); ax.set_zlim(-0.6, 0.1)
plt.tight_layout()
save_fig(fig, "parte5_poses_extrinsecas.png")
plt.show()

# Histograma de translaciones Z (distancia cámara-tablero)
tz_vals = [tvecs_est[i].flatten()[2] for i in range(N_OK)]
fig, ax = plt.subplots(figsize=(7, 4))
ax.hist(tz_vals, bins=8, color='steelblue', edgecolor='white', alpha=0.85)
ax.set_title("Parte 5 – Distribución de la distancia Z (cámara–tablero)")
ax.set_xlabel("Z (metros)"); ax.set_ylabel("Frecuencia"); ax.grid(True, alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte5_distancia_z.png")
plt.show()

print("  ✔ Parte 5 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 6: ERROR DE REPROYECCIÓN
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 6: Error de Reproyección")
print("─" * 70)

errores_img = []
errores_pts = []
for i in range(N_OK):
    pts_repr, _ = cv2.projectPoints(
        obj_pts_lista[i], rvecs_est[i], tvecs_est[i], K_est, dist_est)
    diff = corners_reales[i].reshape(-1, 2) - pts_repr.reshape(-1, 2)
    err_por_pto = np.sqrt((diff**2).sum(axis=1))
    errores_img.append(err_por_pto.mean())
    errores_pts.extend(err_por_pto.tolist())

print(f"\n  Error promedio : {np.mean(errores_img):.4f} px")
print(f"  Error máximo   : {np.max(errores_img):.4f} px")
print(f"  Desv. estándar : {np.std(errores_img):.4f} px")
print(f"  RMS global (OpenCV): {ret:.4f} px")

fig, axes = plt.subplots(1, 3, figsize=(15, 4))
fig.suptitle("Parte 6 – Error de reproyección  e = Σ‖pᵢ − p̂ᵢ‖²", fontsize=13)

# 6a – Error por imagen
axes[0].bar(range(1, N_OK+1), errores_img, color='steelblue', alpha=0.8)
axes[0].axhline(np.mean(errores_img), color='tomato', linestyle='--',
                label=f"Promedio = {np.mean(errores_img):.3f} px")
axes[0].set_title("Error promedio por imagen")
axes[0].set_xlabel("N° imagen"); axes[0].set_ylabel("Error (píxeles)")
axes[0].legend(); axes[0].grid(True, axis='y', alpha=0.3)

# 6b – Histograma de todos los errores
axes[1].hist(errores_pts, bins=30, color='steelblue', edgecolor='white', alpha=0.85)
axes[1].axvline(np.mean(errores_pts), color='tomato', linestyle='--',
                label=f"Media = {np.mean(errores_pts):.3f} px")
axes[1].set_title("Distribución de errores (todos los puntos)")
axes[1].set_xlabel("Error (píxeles)"); axes[1].set_ylabel("Frecuencia")
axes[1].legend(); axes[1].grid(True, alpha=0.3)

# 6c – Distribución espacial del error (imagen 0)
pts_repr0, _ = cv2.projectPoints(
    obj_pts_lista[0], rvecs_est[0], tvecs_est[0], K_est, dist_est)
diff0 = corners_reales[0].reshape(-1,2) - pts_repr0.reshape(-1,2)
err0  = np.sqrt((diff0**2).sum(axis=1))
sc = axes[2].scatter(corners_reales[0].reshape(-1,2)[:,0],
                     corners_reales[0].reshape(-1,2)[:,1],
                     c=err0, cmap='hot_r', s=60, zorder=5)
plt.colorbar(sc, ax=axes[2], label='Error (px)')
axes[2].set_title("Error espacial – Imagen 1")
axes[2].set_xlabel("u (px)"); axes[2].set_ylabel("v (px)")
axes[2].invert_yaxis(); axes[2].grid(True, alpha=0.3)

plt.tight_layout()
save_fig(fig, "parte6_error_reproyeccion.png")
plt.show()

print("  ✔ Parte 6 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 7: CORRECCIÓN DE DISTORSIÓN
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 7: Corrección de Distorsión")
print("─" * 70)

# Aplicar corrección con parámetros estimados
img_ejemplo = imagenes[0]
h, w = img_ejemplo.shape[:2]

# Mapa de rectificación
mapx, mapy = cv2.initUndistortRectifyMap(K_est, dist_est, None, K_est, (w, h),
                                          cv2.CV_32FC1)
img_corr = cv2.remap(img_ejemplo, mapx, mapy, cv2.INTER_LINEAR)

# Diferencia
diff_img = cv2.absdiff(img_ejemplo, img_corr)

fig, axes = plt.subplots(1, 3, figsize=(15, 5))
fig.suptitle("Parte 7 – Corrección de Distorsión Geométrica", fontsize=13)

axes[0].imshow(img_ejemplo, cmap='gray', vmin=0, vmax=255)
axes[0].set_title("Imagen original (con distorsión)")
axes[0].axis('off')

axes[1].imshow(img_corr, cmap='gray', vmin=0, vmax=255)
axes[1].set_title("Imagen corregida (sin distorsión)")
axes[1].axis('off')

im = axes[2].imshow(diff_img, cmap='hot')
axes[2].set_title("Diferencia absoluta\n(regiones afectadas por la corrección)")
axes[2].axis('off')
plt.colorbar(im, ax=axes[2], label='|ΔI|')

plt.tight_layout()
save_fig(fig, "parte7_correccion_distorsion.png")
plt.show()

# Líneas horizontales para verificar rectificación
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fig.suptitle("Parte 7 – Verificación de rectificación (líneas horizontales)", fontsize=13)
for ax, img, titulo in zip(axes, [img_ejemplo, img_corr],
                             ["Original", "Corregida"]):
    ax.imshow(img, cmap='gray', vmin=0, vmax=255)
    for y_line in range(50, h, 60):
        ax.axhline(y_line, color='lime', linewidth=0.7, alpha=0.7)
    ax.set_title(titulo); ax.axis('off')
plt.tight_layout()
save_fig(fig, "parte7_lineas_horizontales.png")
plt.show()

print("  ✔ Parte 7 completada.")


# ─────────────────────────────────────────────────────────────────────────────
# PARTE 8: VISUALIZACIÓN Y ANÁLISIS FINAL
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "─" * 70)
print("PARTE 8: Visualización y Análisis Final")
print("─" * 70)

# 8a – Proyección de ejes 3D sobre imagen
def dibujar_ejes_3d(img, K, dist, rvec, tvec, longitud=0.05):
    """Dibuja los ejes X(rojo), Y(verde), Z(azul) del tablero sobre la imagen."""
    img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    origen = np.array([[0, 0, 0]], dtype=np.float32)
    eje_x  = np.array([[longitud, 0, 0]], dtype=np.float32)
    eje_y  = np.array([[0, longitud, 0]], dtype=np.float32)
    eje_z  = np.array([[0, 0, -longitud]], dtype=np.float32)
    def proy(pt):
        p, _ = cv2.projectPoints(pt, rvec, tvec, K, dist)
        return tuple(p.flatten().astype(int))
    O = proy(origen)
    cv2.arrowedLine(img_color, O, proy(eje_x), (0, 0, 255), 2, tipLength=0.2)
    cv2.arrowedLine(img_color, O, proy(eje_y), (0, 255, 0), 2, tipLength=0.2)
    cv2.arrowedLine(img_color, O, proy(eje_z), (255, 0, 0), 2, tipLength=0.2)
    cv2.putText(img_color, "X", proy(eje_x), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,0,255), 1)
    cv2.putText(img_color, "Y", proy(eje_y), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 1)
    cv2.putText(img_color, "Z", proy(eje_z), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,0,0), 1)
    return img_color

fig, axes = plt.subplots(2, 4, figsize=(16, 8))
fig.suptitle("Parte 8 – Proyección de ejes 3D (pose estimation)\n"
             "Rojo=X, Verde=Y, Azul=Z", fontsize=13)
for i, ax in enumerate(axes.flat):
    if i < min(N_OK, 8):
        img_ejes = dibujar_ejes_3d(imagenes[i], K_est, dist_est,
                                    rvecs_est[i], tvecs_est[i])
        ax.imshow(cv2.cvtColor(img_ejes, cv2.COLOR_BGR2RGB))
        ax.set_title(f"Imagen {i+1}", fontsize=9)
    ax.axis('off')
plt.tight_layout()
save_fig(fig, "parte8_ejes_3d.png")
plt.show()

# 8b – Curva de error vs número de imágenes
print("\n  Calculando curva de error vs número de imágenes...")
n_vals, rms_vals = [], []
for n in range(5, N_OK + 1):
    rms_n, _, _, _, _ = cv2.calibrateCamera(
        obj_pts_lista[:n], corners_reales[:n], (IMG_W, IMG_H), None, None)
    n_vals.append(n); rms_vals.append(rms_n)

fig, ax = plt.subplots(figsize=(8, 4))
ax.plot(n_vals, rms_vals, 'o-', color='steelblue', markersize=5)
ax.axhline(1.0, color='orange', linestyle='--', label='Umbral recomendado (1 px)')
ax.set_title("Parte 8 – Error RMS de reproyección vs. número de imágenes")
ax.set_xlabel("N° de imágenes"); ax.set_ylabel("RMS (píxeles)")
ax.legend(); ax.grid(True, alpha=0.3)
plt.tight_layout()
save_fig(fig, "parte8_curva_rms.png")
plt.show()

# 8c – Comparación antes/después con corners
fig, axes = plt.subplots(1, 2, figsize=(12, 5))
fig.suptitle("Parte 8 – Comparación con corners: original vs corregida", fontsize=13)
for ax, img, titulo in zip(axes,
    [imagenes[0], img_corr], ["Original (distorsionada)", "Corregida"]):
    img_c = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    cv2.drawChessboardCorners(img_c, BOARD_SIZE, corners_reales[0], True)
    ax.imshow(cv2.cvtColor(img_c, cv2.COLOR_BGR2RGB))
    ax.set_title(titulo); ax.axis('off')
plt.tight_layout()
save_fig(fig, "parte8_comparacion_corners.png")
plt.show()

# ─────────────────────────────────────────────────────────────────────────────
# DISCUSIÓN DE PREGUNTAS (PARTE 8)
# ─────────────────────────────────────────────────────────────────────────────
print("\n" + "═" * 70)
print("DISCUSIÓN TÉCNICA – Respuestas a las preguntas de la Parte 8")
print("═" * 70)

conv_idx = next((i for i, r in enumerate(rms_vals) if r < 1.0), len(rms_vals)-1)
n_conv   = n_vals[conv_idx] if conv_idx < len(n_vals) else n_vals[-1]

print(f"""
1. ¿Cuántas imágenes fueron necesarias?
   La calibración converge a un RMS < 1.0 px aproximadamente con {n_conv} imágenes.
   Con {N_OK} imágenes el RMS final fue {ret:.4f} px. En la práctica se
   recomienda usar entre 15 y 25 imágenes bien distribuidas en orientaciones.

2. ¿Cómo afecta el ángulo del patrón?
   Variar el ángulo de inclinación del tablero es fundamental: proporciona
   observaciones diversas que hacen el sistema bien condicionado. Sin variedad
   angular, los parámetros fx, fy y los coeficientes de distorsión no pueden
   desacoplarse correctamente (el sistema de ecuaciones se vuelve singular).

3. ¿Qué tipo de distorsión domina?
   k1 = {DIST_TRUE[0]:+.4f} → distorsión radial de barril (k1 < 0) es la dominante.
   Esta curva las líneas rectas hacia el centro de la imagen.
   Los coeficientes tangenciales (p1, p2) son pequeños y tienen menor impacto.

4. ¿Cómo influye el ruido?
   El ruido añadido en la detección de esquinas ({0.4} px de desviación estándar)
   introduce error en la estimación de los parámetros. El error de reproyección
   obtenido ({ret:.4f} px) refleja tanto el ruido de detección como la bondad
   del modelo pinhole para representar la cámara.

5. ¿Qué parámetros fueron más estables?
   Las distancias focales (fx, fy) convergen rápidamente y son los más estables.
   El centro principal (cx, cy) requiere más imágenes para converger.
   Los coeficientes de distorsión de orden superior (k2, k3) son los menos
   estables y más sensibles al número y calidad de las imágenes.
""")

# ─────────────────────────────────────────────────────────────────────────────
# RESUMEN FINAL
# ─────────────────────────────────────────────────────────────────────────────
print("═" * 70)
print("RESUMEN FINAL DE CALIBRACIÓN")
print("═" * 70)
print(f"""
  Parámetros intrínsecos estimados:
    Matriz K:
      fx = {K_est[0,0]:.2f} px     fy = {K_est[1,1]:.2f} px
      cx = {K_est[0,2]:.2f} px     cy = {K_est[1,2]:.2f} px
      Relación de aspecto: {K_est[0,0]/K_est[1,1]:.4f}

  Coeficientes de distorsión:
    k1 = {dist_flat[0]:+.5f}  (radial, orden 2)
    k2 = {dist_flat[1]:+.5f}  (radial, orden 4)
    p1 = {dist_flat[2]:+.5f}  (tangencial)
    p2 = {dist_flat[3]:+.5f}  (tangencial)
    k3 = {dist_flat[4]:+.5f}  (radial, orden 6)

  Métricas de calidad:
    RMS de reproyección: {ret:.4f} px
    Error promedio por imagen: {np.mean(errores_img):.4f} px
    Error máximo por imagen:   {np.max(errores_img):.4f} px

  Archivos generados en: ./{OUTPUT_DIR}/
""")
print("═" * 70)
print("  ✔ Calibración completada exitosamente.")
print("═" * 70)
