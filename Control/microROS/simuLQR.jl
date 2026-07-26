# ============================================================
#  LQR_propio.jl
#  Diseño y simulación de un controlador LQR propio para el
#  robot de balance de dos ruedas (Yahboom SBR).
#
#  Instalar dependencias (una sola vez):
#    using Pkg
#    Pkg.add(["ControlSystems", "Plots", "LaTeXStrings"])
# ============================================================

using LinearAlgebra
using Printf
using ControlSystems
using Plots
using LaTeXStrings

# ------------------------------------------------------------
# 1. PARÁMETROS FÍSICOS PROPIOS
#    <<< AQUÍ ES DONDE PONES TUS MEDICIONES REALES >>>
#    Todo en unidades SI (kg, m, s, rad)
# ------------------------------------------------------------
m = 0.035          # TODO: masa de UNA rueda [kg]
r = 0.0672 / 2     # TODO: radio de la rueda [m]
M_total = 1.000          # TODO: masa TOTAL del robot (con ruedas) [kg]
M = M_total - 2*m  # masa del cuerpo (sin ruedas), no tocar esta línea

L = 0.5 * 0.0766   # TODO: distancia centro de masa -> centro del chasis [m]
alto = 0.0766        # TODO: altura total del cuerpo (desde la base) [m]
ancho_base = 0.0575       # TODO: mitad de la longitud de la placa base [m]
d = 0.1612         # TODO: separación entre ruedas (track width) [m]

g = 9.8            # aceleración gravitacional, no tocar

# Momentos de inercia (se calculan solos a partir de lo anterior)
inercia_rueda = 0.5 * m * r^2
J_centroide = (1/12) * M * (alto^2 + ancho_base^2)
J_Y_delta = J_centroide     # misma expresión, eje Y

# ------------------------------------------------------------
# 2. TÉRMINOS AUXILIARES (no tocar, son álgebra derivada de 1.)
# ------------------------------------------------------------
Q_aux = J_centroide * M + (J_centroide + M*L^2) * (2*m + 2*inercia_rueda/r^2)

A_23 = -(M^2 * L^2 * g) / Q_aux
A_43 = M * L * g * (M + 2*m + 2*inercia_rueda/r^2) / Q_aux

B_21 = (J_centroide + M*L^2 + M*L*r) / (Q_aux * r)
B_22 = B_21
B_41 = -(M*L/r + M + 2*m + 2*inercia_rueda/r^2) / Q_aux
B_42 = B_41
B_61 = 1 / (r * (m*d + inercia_rueda*d/r^2 + 2*J_Y_delta/d))
B_62 = -B_61

# ------------------------------------------------------------
# 3. MATRICES DE ESPACIO DE ESTADOS
#    x = [posición, vel. lineal, ángulo, vel. angular, ángulo giro, vel. giro]
# ------------------------------------------------------------
A = [0 1 0 0 0 0;
    0 0 A_23 0 0 0;
    0 0 0 1 0 0;
    0 0 A_43 0 0 0;
    0 0 0 0 0 1;
    0 0 0 0 0 0]

B = (inercia_rueda/r) .* [0 0;
    B_21 B_22;
    0 0;
    B_41 B_42;
    0 0;
    B_61 B_62]

C = Matrix{Float64}(I, 6, 6)
D = zeros(6, 2)
sys = ss(A, B, C, D)

# ------------------------------------------------------------
# 4. VERIFICAR CONTROLABILIDAD
#    Si rank < 6, hay un error en las mediciones/álgebra: revisa parámetros
# ------------------------------------------------------------
rank_ctrb = rank(ctrb(sys))
println("Rango de controlabilidad: $rank_ctrb (debe ser 6)")
if rank_ctrb < 6
    error("El sistema NO es controlable con estos parámetros. Revisa las mediciones.")
end

# ------------------------------------------------------------
# 5. DISEÑO DEL LQR — AQUÍ ESTÁ EL "DISEÑO" REAL
#    <<< AJUSTA ESTOS PESOS SEGÚN TUS PRIORIDADES >>>
#
#    Regla de partida (Bryson): Q[i,i] = 1 / (valor_max_aceptable_x_i)^2
#                                R[j,j] = 1 / (valor_max_aceptable_u_j)^2
#
#    Orden de estados: [pos, vel, ángulo, vel_ang, giro, vel_giro]
# ------------------------------------------------------------
peso_posicion = 7700.0   # qué tan fuerte corrige desviaciones de posición
peso_velocidad = 0.0      # normalmente se deja en 0 (no se penaliza directo)
peso_angulo = 0.0      # OJO: en el original está en 0 porque el peso fuerte
# ya lo pone A_43/A_23 de forma natural. Si tu robot
# oscila mucho en el ángulo, SUBE este valor primero.
peso_vel_angulo = 1600.0   # amortigua las oscilaciones del ángulo
peso_giro = 500.0    # corrige el ángulo de yaw (deriva lateral)
peso_vel_giro = 0.0

Q_lqr = diagm([peso_posicion, peso_velocidad, peso_angulo,
    peso_vel_angulo, peso_giro, peso_vel_giro])

# --- Límite de esfuerzo de control (para R_lqr) ---
# CORRECCIÓN IMPORTANTE respecto a la versión anterior:
# u_max derivado de "torque_max*r/inercia_rueda" da un número gigante
# (~550) porque representa el límite teórico de la rueda girando SIN
# CARGA. Eso hace que R sea artificialmente diminuto y el LQR entregue
# ganancias K enormes (~200x las de fábrica) que saturan el PWM de tu
# firmware ante la más mínima inclinación.
#
# Lo correcto es calibrar u_max contra lo que TU firmware realmente
# puede entregar sin saturar el PWM. En tu app_control.c:
#   velocity_L = Ratio_accel * (x_speed + L_accel / Control_Frequency)
#   Motor_Left = PWM_Limit(velocity_L, 2600, -2600)
# Despejando L_accel para el caso límite (ignorando x_speed, que es
# pequeño frente al término de accel en una perturbación fuerte):
#   L_accel_max ≈ (PWM_max / Ratio_accel) * Control_Frequency

Ratio_accel = 2400   # TODO: confirma este valor en tu app_control.c (ya lo vimos = 2400)
Control_Frequency = 200    # TODO: confirma en tu firmware (Hz del loop de control, revisa main.h/bsp)
PWM_max = 2600   # TODO: confirma el límite real de PWM_Limit en tu firmware

u_max = (PWM_max / Ratio_accel) * Control_Frequency
@printf "\nu_max calibrado contra el firmware: %.4f\n" u_max

# R_lqr = [1.0  0.0;
#             0.0  1.0]

R_lqr = diagm[1/u_max^2 0; 0 1/u_max^2]     # regla de Bryson con el u_max correcto
# si al simular ves que el PWM sigue
# saturando, sube R_lqr manualmente
# (multiplícalo por 2, 5, 10...)

K = lqr(sys, Q_lqr, R_lqr)   # K es 2x6: fila 1 = rueda izq, fila 2 = rueda der

println("\nMatriz de ganancias K (2x6):")
display(K)

# ------------------------------------------------------------
# 6. EXTRAER K1..K6 PARA EL FIRMWARE
#    El firmware asume una estructura simétrica:
#      u_izq = -(K1*x1 + K2*x2 + K3*x3 + K4*x4 + K5*x5 + K6*x6)
#      u_der = -(K1*x1 + K2*x2 + K3*x3 + K4*x4 - K5*x5 - K6*x6)
#    Es decir: K1..K4 iguales en ambas filas, K5/K6 con signo opuesto.
#    Si tu K no sale exactamente simétrico (por redondeo numérico),
#    promediamos ambas filas para obtener el valor final.
# ------------------------------------------------------------
K1 = (K[1, 1] + K[2, 1]) / 2
K2 = (K[1, 2] + K[2, 2]) / 2
K3 = (K[1, 3] + K[2, 3]) / 2
K4 = (K[1, 4] + K[2, 4]) / 2
K5 = (K[1, 5] - K[2, 5]) / 2
K6 = (K[1, 6] - K[2, 6]) / 2

println("\n--- Valores para app_control.c ---")
@printf "K1 = %.6f\n" K1
@printf "K2 = %.6f\n" K2
@printf "K3 = %.6f\n" K3
@printf "K4 = %.6f\n" K4
@printf "K5 = %.6f\n" K5
@printf "K6 = %.6f\n" K6

# Verificación de asimetría (debería ser ~0; si es grande, algo anda mal)
asimetria = maximum(abs.([K[1, 1]-K[2, 1], K[1, 2]-K[2, 2], K[1, 3]-K[2, 3],
    K[1, 4]-K[2, 4], K[1, 5]+K[2, 5], K[1, 6]+K[2, 6]]))
@printf "\nMáxima asimetría detectada: %.6f (debe ser cercana a 0)\n" asimetria

# ------------------------------------------------------------
# 7. SIMULACIÓN DE LAZO CERRADO — respuesta a condición inicial
#    (ej: robot soltado con una inclinación inicial de 0.1 rad)
# ------------------------------------------------------------
Acl = A - B * K
sys_lc = ss(Acl, zeros(6, 2), Matrix{Float64}(I, 6, 6), zeros(6, 2))

t_sim = 0.0:0.01:5.0
x0 = [0.0, 0.0, 0.1, 0.0, 0.0, 0.0]   # inclinación inicial de 0.1 rad (~5.7°)

Y, t_out, X = lsim(sys_lc, zeros(2, length(t_sim)), t_sim, x0)
U = -K * X   # esfuerzo de control resultante

# ------------------------------------------------------------
# 8. GRAFICACIÓN
# ------------------------------------------------------------
p1 = plot(t_out, Y[3, :] .* (180/π), label=L"\theta\ [°]",
    color=:red, linewidth=2, ylabel="grados")
title!(p1, "Ángulo de inclinación")

p2 = plot(t_out, Y[1, :], label=L"x_1\ \mathrm{posición\ [m]}",
    color=:blue, linewidth=2, ylabel="m")
title!(p2, "Posición")

p3 = plot(t_out, Y[5, :] .* (180/π), label=L"x_5\ \mathrm{giro\ [°]}",
    color=:purple, linewidth=2, ylabel="grados")
title!(p3, "Ángulo de giro (yaw)")

p4 = plot(t_out, U[1, :], label="u izquierda", color=:blue, linewidth=2)
plot!(p4, t_out, U[2, :], label="u derecha", color=:red, linewidth=2, linestyle=:dash)
title!(p4, "Esfuerzo de control")

fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(1000, 600),
    xlabel="Tiempo [s]", legend=:topright, margin=5Plots.mm)

display(fig)
savefig(fig, "respuesta_condicion_inicial.png")
println("\nGráfica guardada en: respuesta_condicion_inicial.png")

# ------------------------------------------------------------
# 9. CHECKLIST DE VALIDACIÓN ANTES DE SUBIR AL ROBOT
# ------------------------------------------------------------
@printf "\n--- Checklist ---\n"
@printf "1. ¿El ángulo vuelve a 0 sin oscilar demasiado? Máx |θ|: %.3f°\n" maximum(abs.(Y[3, :]))*(180/π)
@printf "2. ¿El esfuerzo de control |u| se mantiene dentro del límite del motor? Máx |u|: %.4f (límite: %.4f)\n" maximum(abs.(U)) u_max
@printf "3. ¿El tiempo de establecimiento es razonable (< 2-3s)? revisa la gráfica.\n"

# --- 4. VERIFICACIÓN DIRECTA DE SATURACIÓN DE PWM ---
# Esta es la prueba que realmente importa: convertir U a PWM exactamente
# como lo hace tu firmware, y ver si se sale del rango ±PWM_max.
PWM_L = Ratio_accel .* (X[2, :] .+ U[1, :] ./ Control_Frequency)
PWM_R = Ratio_accel .* (X[2, :] .+ U[2, :] ./ Control_Frequency)
max_pwm = max(maximum(abs.(PWM_L)), maximum(abs.(PWM_R)))
@printf "4. PWM máximo pedido en la simulación: %.1f (límite físico: ±%.0f)\n" max_pwm PWM_max
if max_pwm > PWM_max
    println("   ⚠ SATURA: sube R_lqr (multiplícalo) o baja los pesos de Q_lqr y vuelve a correr.")
else
    println("   ✓ No satura con esta condición inicial.")
end

println("\nSi algo se ve mal (oscila, satura, tarda mucho): ajusta Q_lqr/R_lqr en el paso 5 y vuelve a correr.")