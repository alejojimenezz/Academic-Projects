# %% [markdown]
# # Tarea: Calibración de cámara
# 
# Diseño e implementación de de un sistema de calibración de cámara, para la estimación de parámetros geométricos que minimicen el error de reproyección. Aplicado a cámara de computador Lenovo ThinkPad X270.
# 
# ## Importación de librerias
# 
# ### Python
# 
# ```
# pip install opencv-python opencv-contrib-python numpy matplotlib
# ```
# 
# ### Notebook

# %%
import os
import cv2
import glob
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# %% [markdown]
# ## Configuraciones iniciales (Parte 1)
# 
# ### Adquisición

# %%
CARPETA_IMAGENES = "images"
COLS = 7
FILAS = 7
CUADRO_MM = 27

extensiones = ['*.jpg', '*.jpeg', '*.png', '*.bmp']
rutas = []
for ext in extensiones:
    rutas += glob.glob(os.path.join(CARPETA_IMAGENES, ext))
rutas.sort()

print(f"Imágenes encontradas: {len(rutas)}")

# %% [markdown]
# ### Preprocesamiento

# %%
n_preview = min(6, len(rutas))
fig, axes = plt.subplots(2, 3, figsize=(14, 7))
axes = axes.flatten()
for i in range(n_preview):
    img  = cv2.imread(rutas[i])
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    axes[i].imshow(gray, cmap='gray')
    axes[i].set_title(f"{os.path.basename(rutas[i])}\n{gray.shape[1]}×{gray.shape[0]} px",
                      fontsize=9)
    axes[i].axis('off')
for j in range(n_preview, len(axes)):
    axes[j].axis('off')

fig.suptitle('Imágenes en escala de grises I(x,y)', fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('preprocesamiento.png', dpi=120, bbox_inches='tight')
plt.show()

img_ref = cv2.imread(rutas[0])
H, W = img_ref.shape[:2]
print(f"Resolución: {W}×{H} px")

# %% [markdown]
# ## Puntos de calibración (Parte 2)
# 
# Con un tablero de ajedrez real se tienen 8x8 cuadros, en decir 7 esquinas internas, tanto para filas, como columnas; De 27 mm cada lado de cada cuadro.
# 
# Por último, como se toma un tablero plano de ajedrez, el valor de Z en los puntos 3D reales será $Z_i = 0$

# %%
# Criterio de refinamiento sub-píxel
criterio = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)

# Puntos 3D del patrón (en mm)
puntos_objeto = np.zeros((COLS * FILAS, 3), np.float32)
puntos_objeto[:, :2] = np.mgrid[0:COLS, 0:FILAS].T.reshape(-1, 2)
puntos_objeto *= CUADRO_MM

lista_pts3d  = []   # P_i IRL
lista_pts2d  = []   # p_i en imagen
imagenes_ok  = []   # rutas OK
imagenes_fail= []   # rutas FAIL

for ruta in rutas:
    img  = cv2.imread(ruta)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    encontrado, esquinas = cv2.findChessboardCorners(
        gray, (COLS, FILAS),
        cv2.CALIB_CB_ADAPTIVE_THRESH | cv2.CALIB_CB_NORMALIZE_IMAGE
    )

    if encontrado:
        esquinas_refinadas = cv2.cornerSubPix(
            gray, esquinas, (11, 11), (-1, -1), criterio
        )
        lista_pts3d.append(puntos_objeto)
        lista_pts2d.append(esquinas_refinadas)
        imagenes_ok.append(ruta)
    else:
        imagenes_fail.append(ruta)

print(f"Detección exitosa: {len(imagenes_ok)}/{len(rutas)} imágenes")
if imagenes_fail:
    print(f"  Fallidas ({len(imagenes_fail)}): {[os.path.basename(r) for r in imagenes_fail]}")
if len(imagenes_ok) < 5:
    raise ValueError("Se necesitan al menos 5 imágenes con detección exitosa. "
                     "Verifica la configuración del patrón o captura más imágenes.")

# Visualización de esquinas detectadas
n_show = min(6, len(imagenes_ok))
fig, axes = plt.subplots(2, 3, figsize=(14, 8))
axes = axes.flatten()
for i in range(n_show):
    img_vis  = cv2.imread(imagenes_ok[i]).copy()
    gray_vis = cv2.cvtColor(img_vis, cv2.COLOR_BGR2GRAY)
    _, esqs  = cv2.findChessboardCorners(gray_vis, (COLS, FILAS))
    cv2.drawChessboardCorners(img_vis, (COLS, FILAS), lista_pts2d[i], True)
    axes[i].imshow(cv2.cvtColor(img_vis, cv2.COLOR_BGR2RGB))
    axes[i].set_title(f"{os.path.basename(imagenes_ok[i])}", fontsize=9)
    axes[i].axis('off')
for j in range(n_show, len(axes)):
    axes[j].axis('off')

fig.suptitle('Esquinas detectadas $p_i = (u_i, v_i)$',
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('deteccion.png', dpi=120, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## Parámetros intrínsecos (Parte 3)

# %%
# Calibración con todas las imágenes exitosas
rms, K, D, rvecs, tvecs = cv2.calibrateCamera(
    lista_pts3d, lista_pts2d, (W, H), None, None
)

fx, fy = K[0, 0], K[1, 1]
cx, cy = K[0, 2], K[1, 2]

print("Parámetros Intrínsecos")
print("\n")
print(f"Matriz K:")
print(np.array2string(K, precision=2, suppress_small=True))
print(f"\n  fx = {fx:.2f} px   fy = {fy:.2f} px")
print(f"  cx = {cx:.2f} px   cy = {cy:.2f} px")
print(f"  Relación de aspecto fx/fy = {fx/fy:.4f}")
print(f"  Centro esperado: ({W/2:.0f}, {H/2:.0f}) px")

# %% [markdown]
# ## Distorsión (Parte 4)

# %%
print("\n")
print("Coeficientes de Distorsión")
print("\n")
d = D.flatten()
print(f"  k1 (radial)     = {d[0]:+.6f}")
print(f"  k2 (radial)     = {d[1]:+.6f}")
print(f"  p1 (tangencial) = {d[2]:+.6f}")
print(f"  p2 (tangencial) = {d[3]:+.6f}")
print(f"  k3 (radial)     = {d[4]:+.6f}")
tipo_distorsion = "BARRIL (barrel)" if d[0] < 0 else "COJÍN (pincushion)"
print(f"  → Distorsión dominante: {tipo_distorsion}")

# %% [markdown]
# ## Calibración extrínseca (Parte 5)

# %%
print("\n")
print("Parámetros Extrínsecos (primera imagen)")
print("\n")
R0, _  = cv2.Rodrigues(rvecs[0])
t0     = tvecs[0].flatten()
print(f"Rotación R (imagen 0):")
print(np.array2string(R0, precision=4, suppress_small=True))
print(f"Traslación t (mm): {t0}")
print(f"  Distancia estimada a cámara: {np.linalg.norm(t0):.1f} mm")

# %% [markdown]
# ## Error de reproyección (Parte 6)

# %%
# Calcular error por imagen
errores_por_imagen = []
for i in range(len(imagenes_ok)):
    pts_reproyectados, _ = cv2.projectPoints(
        lista_pts3d[i], rvecs[i], tvecs[i], K, D
    )
    err = cv2.norm(lista_pts2d[i], pts_reproyectados, cv2.NORM_L2)
    err_rms = np.sqrt(err**2 / len(pts_reproyectados))
    errores_por_imagen.append(err_rms)

errores_por_imagen = np.array(errores_por_imagen)

print("\n")
print("Error de Reproyección")
print("\n")
print(f"  RMS global (cv2): {rms:.4f} px")
print(f"  Error promedio:   {errores_por_imagen.mean():.4f} px")
print(f"  Error máximo:     {errores_por_imagen.max():.4f} px")
print(f"  Error mínimo:     {errores_por_imagen.min():.4f} px")
calidad = "EXCELENTE" if rms < 0.5 else ("BUENA" if rms < 1.0 else "MEJORABLE (> 1 px)")
print(f"  → Calidad: {calidad}")

# Gráfica de error por imagen
fig, axes = plt.subplots(1, 2, figsize=(14, 5))

nombres = [os.path.basename(r) for r in imagenes_ok]
colores = ['#e74c3c' if e > 1.0 else '#2ecc71' for e in errores_por_imagen]
axes[0].bar(range(len(errores_por_imagen)), errores_por_imagen, color=colores, edgecolor='k', linewidth=0.5)
axes[0].axhline(rms, color='navy', linestyle='--', linewidth=1.5, label=f'RMS global = {rms:.3f} px')
axes[0].axhline(1.0, color='orange', linestyle=':', linewidth=1.2, label='Umbral 1.0 px')
axes[0].set_xlabel('Imagen')
axes[0].set_ylabel('Error RMS (px)')
axes[0].set_title('Error de reproyección por imagen')
axes[0].legend()
axes[0].set_xticks(range(len(nombres)))
axes[0].set_xticklabels(nombres, rotation=45, ha='right', fontsize=7)

# Distribución
axes[1].hist(errores_por_imagen, bins=max(5, len(errores_por_imagen)//3),
             color='steelblue', edgecolor='white', alpha=0.85)
axes[1].axvline(rms, color='navy', linestyle='--', linewidth=1.5, label=f'RMS = {rms:.3f} px')
axes[1].set_xlabel('Error RMS (px)')
axes[1].set_ylabel('Frecuencia')
axes[1].set_title('Distribución del error de reproyección')
axes[1].legend()

fig.suptitle('Error de Reproyección $e = \\sum_i \\|p_i - \\hat{p}_i\\|^2$',
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('error_reproyeccion.png', dpi=120, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## Corrección de distorsión (Parte 7)

# %%
# Mapas de undistorsión (se calculan una sola vez)
K_nuevo, roi = cv2.getOptimalNewCameraMatrix(K, D, (W, H), alpha=1)
map1, map2   = cv2.initUndistortRectifyMap(K, D, None, K_nuevo, (W, H), cv2.CV_32FC1)

# Comparar N imágenes
n_comp = min(3, len(imagenes_ok))
fig, axes = plt.subplots(n_comp, 2, figsize=(14, 5 * n_comp))
if n_comp == 1:
    axes = axes[np.newaxis, :]

for i in range(n_comp):
    img_orig = cv2.imread(imagenes_ok[i])
    img_corr = cv2.remap(img_orig, map1, map2, cv2.INTER_LINEAR)

    # Recortar al ROI válido
    x, y, rw, rh = roi
    img_recortada = img_corr[y:y+rh, x:x+rw]

    axes[i, 0].imshow(cv2.cvtColor(img_orig, cv2.COLOR_BGR2RGB))
    axes[i, 0].set_title(f'Original – {os.path.basename(imagenes_ok[i])}', fontsize=10)
    axes[i, 0].axis('off')

    axes[i, 1].imshow(cv2.cvtColor(img_recortada, cv2.COLOR_BGR2RGB))
    axes[i, 1].set_title('Corregida (distorsión eliminada)', fontsize=10)
    axes[i, 1].axis('off')

fig.suptitle('Corrección de Distorsión: Original vs Rectificada',
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('correccion_distorsion.png', dpi=120, bbox_inches='tight')
plt.show()

print(f"ROI válido tras corrección: x={x}, y={y}, ancho={rw}, alto={rh}")
print(f"Recorte: {100*(1 - rw*rh/(W*H)):.1f}% del área original eliminada")

# %% [markdown]
# ## Visualización y análisis (Parte 8)
# 
# ### Proyección de ejes 3D sobre el patrón

# %%
# Proyección de ejes 3D
def dibujar_ejes_3d(img, K, D, rvec, tvec, longitud_mm=50):
    origen = np.float32([[0, 0, 0]])
    ejes   = np.float32([
        [longitud_mm, 0, 0],
        [0, longitud_mm, 0],
        [0, 0, -longitud_mm]   # Z hacia la cámara
    ])
    p_origen, _ = cv2.projectPoints(origen, rvec, tvec, K, D)
    p_ejes,   _ = cv2.projectPoints(ejes,   rvec, tvec, K, D)

    o  = tuple(p_origen[0].ravel().astype(int))
    px = tuple(p_ejes[0].ravel().astype(int))
    py = tuple(p_ejes[1].ravel().astype(int))
    pz = tuple(p_ejes[2].ravel().astype(int))

    cv2.arrowedLine(img, o, px, (0, 0, 255),   3, tipLength=0.2)  # X rojo
    cv2.arrowedLine(img, o, py, (0, 255, 0),   3, tipLength=0.2)  # Y verde
    cv2.arrowedLine(img, o, pz, (255, 128, 0), 3, tipLength=0.2)  # Z naranja
    cv2.putText(img, 'X', px, cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255),   2)
    cv2.putText(img, 'Y', py, cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0),   2)
    cv2.putText(img, 'Z', pz, cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 128, 0), 2)
    return img

n_ejes = min(4, len(imagenes_ok))
fig, axes = plt.subplots(1, n_ejes, figsize=(4 * n_ejes, 5))
if n_ejes == 1:
    axes = [axes]

for i in range(n_ejes):
    img_e = cv2.imread(imagenes_ok[i]).copy()
    img_e = dibujar_ejes_3d(img_e, K, D, rvecs[i], tvecs[i], longitud_mm=CUADRO_MM * 3)
    axes[i].imshow(cv2.cvtColor(img_e, cv2.COLOR_BGR2RGB))
    axes[i].set_title(f"Imagen {i}", fontsize=9)
    axes[i].axis('off')

fig.suptitle('Proyección de ejes 3D (Pose estimation)',
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('a_ejes_3d.png', dpi=120, bbox_inches='tight')
plt.show()

# %% [markdown]
# ### Análisis de estabilidad

# %%
# Análisis de estabilidad: calibración con subconjuntos
import random
random.seed(42)

n_total = len(imagenes_ok)
tamanios = list(range(5, n_total + 1)) if n_total >= 5 else [n_total]
n_rep = 5   # repeticiones por tamaño

fx_vals, fy_vals, rms_vals = [], [], []
tamanios_plot = []

for n in tamanios:
    fx_rep, fy_rep, rms_rep = [], [], []
    for _ in range(n_rep):
        idx = random.sample(range(n_total), n)
        pts3 = [lista_pts3d[i] for i in idx]
        pts2 = [lista_pts2d[i] for i in idx]
        try:
            r, Kt, _, _, _ = cv2.calibrateCamera(pts3, pts2, (W, H), None, None)
            fx_rep.append(Kt[0, 0])
            fy_rep.append(Kt[1, 1])
            rms_rep.append(r)
        except:
            pass
    if fx_rep:
        fx_vals.append(np.std(fx_rep))
        fy_vals.append(np.std(fy_rep))
        rms_vals.append(np.mean(rms_rep))
        tamanios_plot.append(n)

fig, axes = plt.subplots(1, 2, figsize=(13, 5))

axes[0].plot(tamanios_plot, fx_vals, 'o-', label='σ(fx)', color='#e74c3c')
axes[0].plot(tamanios_plot, fy_vals, 's-', label='σ(fy)', color='#3498db')
axes[0].set_xlabel('Número de imágenes')
axes[0].set_ylabel('Desviación estándar (px)')
axes[0].set_title('Estabilidad de fx y fy vs. N imágenes')
axes[0].legend()
axes[0].grid(True, alpha=0.3)

axes[1].plot(tamanios_plot, rms_vals, 'D-', color='#27ae60', label='RMS medio')
axes[1].axhline(0.5, color='gray', linestyle=':', label='0.5 px ref.')
axes[1].set_xlabel('Número de imágenes')
axes[1].set_ylabel('RMS promedio (px)')
axes[1].set_title('Error RMS vs. N imágenes')
axes[1].legend()
axes[1].grid(True, alpha=0.3)

fig.suptitle('Estabilidad de parámetros vs. número de imágenes',
             fontsize=13, fontweight='bold')
plt.tight_layout()
plt.savefig('b_estabilidad.png', dpi=120, bbox_inches='tight')
plt.show()

# %% [markdown]
# ### Mapa espacial del error de proyección

# %%
# Mapa espacial del error de reproyección
img_mapa = cv2.imread(imagenes_ok[0])
pts_repr, _ = cv2.projectPoints(lista_pts3d[0], rvecs[0], tvecs[0], K, D)

det = lista_pts2d[0].reshape(-1, 2)
rep = pts_repr.reshape(-1, 2)
err_pts = np.linalg.norm(det - rep, axis=1)

fig, ax = plt.subplots(figsize=(10, 7))
ax.imshow(cv2.cvtColor(img_mapa, cv2.COLOR_BGR2RGB), alpha=0.6)
sc = ax.scatter(det[:, 0], det[:, 1], c=err_pts, cmap='RdYlGn_r',
                s=60, zorder=5, edgecolors='k', linewidths=0.3)
for d, r in zip(det, rep):
    ax.plot([d[0], r[0]], [d[1], r[1]], 'b-', alpha=0.5, linewidth=0.8)
plt.colorbar(sc, ax=ax, label='Error (px)')
ax.set_title('Mapa espacial del error de reproyección (imagen 0)\nAzul = vector error, color = magnitud',
             fontsize=11)
ax.axis('off')
plt.tight_layout()
plt.savefig('c_mapa_error.png', dpi=120, bbox_inches='tight')
plt.show()

# %% [markdown]
# ## Datos y resultados finales
# 
# - **Resolución:** 1280x720 px
# - **Esquinas internas:** 7x7
# - **Lado de cuadro interno:** 27 mm
# - **Imágenes con detección exitosa:** 20/20
# 
# ### Parámetros intrínsecos
# 
# - **Matríz K:**
# $$
# \begin{bmatrix}
#     923.51 & 0 & 617.01 \\
#     0 & 923.49 & 382.24 \\
#     0 & 0 & 1
# \end{bmatrix}
# $$
# 
# $$
# \begin{align*}
#     f_x = 923.51\,px&\;\;f_y = 923.49\,px \\
#     c_x = 617.01\,px&\;\;c_y = 382.24\,px \\
# \end{align*}
# $$
# 
# - **Relación de aspecto:** 1
# - **Centro esperado:** (640, 360) px
# 
# ### Distorsión
# 
# - **Radial:**
# $$
# \begin{align*}
#     k_1 &= 0.155167 \\
#     k_2 &= -0.201095 \\
#     k_3 &= -0.139747
# \end{align*}
# $$
# - **Tangencial:**
# $$
# \begin{align*}
#     p_1 &= 0.004014 \\
#     p_2 &= 0.000031
# \end{align*}
# $$
# - **Distorsión dominante:** Cojín (pincushion)
# 
# ### Calibración extrínseca
# 
# - **Rotación de primera imágen:**
# $$
# \begin{bmatrix}
#     0.9948 & -0.02 & 0.1002 \\
#     0.015 & 0.9986 & 0.0503 \\
#     -0.1011 & -0.0485 & 0.9937
# \end{bmatrix}
# $$
# 
# - **Traslación (mm):**
# $$
# \begin{bmatrix}
#     -90.3583808 & -54.67869473 & 474.11347283
# \end{bmatrix}
# $$
# 
# - **Distancia estimada a cámara:** 485.7 mm
# 
# ### Error de reproyección
# 
# - **RMS Global:** 0.4571 px
# - **Error promedio:** 0.4195 px
# - **Error máximo:** 0.8999 px
# - **Error mínimo:** 0.2086 px
# 
# ![error](error_reproyeccion.png)
# 
# ### Corrección de distorsión
# 
# - **Recorte de imágen:** 14.6% del área original eliminada
# 
# ![imgCorreccion](correccion_distorsion.png)
# 
# ### Visualización y análisis
# 
# ![ejes3D](a_ejes_3d.png)
# ![estabilidad](b_estabilidad.png)
# ![mapaError](c_mapa_error.png)

# %% [markdown]
# ## Parámetros de calibración finales

# %%
# ── Guardar en formato OpenCV XML/YAML ────────────────────────
fs = cv2.FileStorage('calibracion_camara.xml', cv2.FILE_STORAGE_WRITE)
fs.write('camera_matrix',      K)
fs.write('dist_coefficients',  D)
fs.write('rms_error',          rms)
fs.write('image_width',        W)
fs.write('image_height',       H)
fs.release()

# ── Guardar en NumPy ──────────────────────────────────────────
np.savez('calibracion_camara.npz',
         K=K, D=D, rvecs=np.array(rvecs), tvecs=np.array(tvecs),
         rms=rms, image_size=[W, H])

print("Archivos guardados:")
print("  calibracion_camara.xml  (formato OpenCV)")
print("  calibracion_camara.npz  (formato NumPy)")
print("\nPara cargar en otro script:")
print("  data = np.load('calibracion_camara.npz')")
print("  K = data['K']")
print("  D = data['D']")


