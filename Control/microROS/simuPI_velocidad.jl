# ============================================================
#  pid_velocity_PI.jl
#  Sintonización analítica del PI de velocidad (lazo externo)
#  Robot de equilibrio en dos ruedas — extiende pid_balance_PD.jl
#
#  Arquitectura en cascada (igual que el firmware):
#    Motor_Left  = Balance_Pwm + Velocity_Pwm + Turn_Pwm
#    Motor_Right = Balance_Pwm + Velocity_Pwm - Turn_Pwm
#
#  Requiere: ControlSystems.jl, Plots.jl
# ============================================================

using LinearAlgebra
using Printf
using ControlSystems
using Plots

# ------------------------------------------------------------
# 1. Parámetros físicos (idénticos a parametros_LQR.jl)
# ------------------------------------------------------------
m = 0.035
r = 0.0672 / 2
inercia = 0.5 * m * r^2

M = 1.000 - 2*m
L = 0.5 * 0.0766

J_centroide = (1/12) * M * (0.0766^2 + 0.0575^2)
g = 9.8

Q_aux = J_centroide * M + (J_centroide + M*L^2) * (2*m + 2*inercia/r^2)

A_23 = -(M^2 * L^2 * g) / Q_aux
A_43 = M * L * g * (M + 2*m + 2*inercia/r^2) / Q_aux

B_21 = (J_centroide + M*L^2 + M*L*r) / (Q_aux*r)
B_41 = -(M*L/r + M + 2*m + 2*inercia/r^2) / Q_aux

B21_actual = (inercia/r) * B_21
B41_actual = (inercia/r) * B_41

# ------------------------------------------------------------
# 2. Ganancias del lazo de ángulo ya diseñado (pid_balance_PD.jl)
# ------------------------------------------------------------
Kp_f = 369.6361     # N·m/rad
Kd_f = 12.4880      # N·m·s/rad

# ------------------------------------------------------------
# 3. Reducción de orden: modelo del lazo de velocidad
#    Con el lazo de ángulo ya cerrado, la velocidad se comporta
#    como un integrador puro: V(s)/Uvel(s) = Kv/s
#    (válido por separación de escalas de tiempo: wn_v << wn_balance)
# ------------------------------------------------------------
A11 = A_43 + 2*B41_actual*Kp_f
A12 = 2*B41_actual*Kd_f
A21 = A_23 + 2*B21_actual*Kp_f
A22 = 2*B21_actual*Kd_f

# Sistema aumentado [θ, θ̇, v] con entrada u_vel (par extra por rueda)
A3 = [0 1 0; A11 A12 0; A21 A22 0]
B3 = [0; 2*B41_actual; 2*B21_actual]
C3 = [0 0 1]     # salida: velocidad v
D3 = [0]

sys3 = ss(A3, B3, C3, D3)
tf3 = tf(sys3)
println("Función de transferencia V(s)/Uvel(s):")
display(tf3)

# Ganancia DC (para s→0): confirma el comportamiento integrador
num = numvec(tf3)[1]
den = denvec(tf3)[1]
Kv = num[end] / den[end-1]     # término independiente / coeficiente de s
@printf "\nKv (ganancia DC, V(s)/Uvel(s) ≈ Kv/s) = %.6f\n" Kv

# ------------------------------------------------------------
# 4. Diseño PI por asignación de polos
#    Uvel = Kp_v·(Vt − v) + Ki_v·∫(Vt − v) dt
#    Ecuación característica: s² + Kv·Kp_v·s + Kv·Ki_v = 0
#
#    IMPORTANTE: Kv < 0 (ver justificación en el análisis),
#    por eso se trabaja con magnitudes y la ley de control
#    lleva el signo ya incorporado (igual que en Velocity_PI
#    del firmware, que también usa doble negación).
# ------------------------------------------------------------
zeta_v = 0.8
wn_v = 1.0     # rad/s — deliberadamente ~25x más lento que wn=25 del lazo de ángulo

Kp_v = abs(2*zeta_v*wn_v / Kv)
Ki_v = abs(wn_v^2 / Kv)

@printf "\n--- Ganancias PI analíticas (unidades físicas) ---\n"
@printf "Kp_v = %.4f  N·m/(m/s)\n" Kp_v
@printf "Ki_v = %.4f  N·m/m\n" Ki_v

# ------------------------------------------------------------
# 5. Verificación: sistema completo en lazo cerrado (4 estados)
#    Estados: [θ, θ̇, v, ∫(Vt−v)]
# ------------------------------------------------------------
A4 = [0 1 0 0;
    A11 A12 2*B41_actual*Kp_v -2*B41_actual*Ki_v;
    A21 A22 2*B21_actual*Kp_v -2*B21_actual*Ki_v;
    0 0 -1 0]

B4 = [0; 2*B41_actual*Kp_v; 2*B21_actual*Kp_v; 1.0]   # entrada: Vt (referencia de velocidad)
C4 = Matrix{Float64}(I, 4, 4)
D4 = zeros(4, 1)

sys4 = ss(A4, B4, C4, D4)

autovalores = eigvals(A4)
println("\nPolos en lazo cerrado (balance + velocidad):")
for p in autovalores
    @printf "  %.4f %+.4fj\n" real(p) imag(p)
end
if all(real.(autovalores) .< 0)
    println("=> Sistema ESTABLE (todas las partes reales < 0)")
else
    println("=> ADVERTENCIA: sistema inestable, revisar Kp_v/Ki_v")
end

# ------------------------------------------------------------
# 6. Simulación: escalón de referencia de velocidad (0.2 m/s)
# ------------------------------------------------------------
t_sim = 0.0:0.005:8.0     # Ts = 5ms, igual que Control_Frequency = 200 Hz
Vt = 0.2
ref = Vt .* ones(1, length(t_sim))

Y, t_out, X = lsim(sys4, ref, t_sim, [0, 0, 0, 0])

p1 = plot(t_out, Y[3, :], label="v [m/s]", color=:blue, linewidth=2,
    xlabel="Tiempo [s]", ylabel="Velocidad [m/s]",
    title="Respuesta del PI de velocidad (referencia 0.2 m/s)")
plot!(p1, t_out, ref[1, :], label="referencia", color=:black, linestyle=:dot)

p2 = plot(t_out, Y[1, :] .* (180/π), label="θ [°]", color=:red, linewidth=2,
    xlabel="Tiempo [s]", ylabel="Ángulo [°]",
    title="Ángulo de inclinación inducido")

fig = plot(p1, p2, layout=(2, 1), size=(800, 600), margin=5Plots.mm)
display(fig)
savefig(fig, "respuesta_PI_velocidad.png")
println("\nGráfica guardada en: respuesta_PI_velocidad.png")

# ------------------------------------------------------------
# 7. Resumen numérico
# ------------------------------------------------------------
theta_max = maximum(abs.(Y[1, :])) * (180/π)
v_final = Y[3, end]
idx_settle = findlast(abs.(Y[3, :] .- Vt) .> 0.02*Vt)
t_settle = idx_settle === nothing ? 0.0 : t_out[idx_settle]

@printf "\n--- Resumen respuesta al escalón de velocidad ---\n"
@printf "Velocidad objetivo      : %.3f m/s\n" Vt
@printf "Velocidad final         : %.4f m/s\n" v_final
@printf "Ángulo máximo inducido  : %.2f °  (valida hipótesis de ángulo pequeño)\n" theta_max
@printf "Tiempo de asentamiento  : %.3f s (criterio 2%%)\n" t_settle

# ------------------------------------------------------------
# 8. NOTA — Conversión a unidades de firmware
# ------------------------------------------------------------
# El firmware (pid_control.h) usa Velocity_Kp y Velocity_Ki en PWM
# por pulso de encoder (no en N·m por m/s). La conversión requiere:
#   - Km: constante de motor (N·m por unidad de PWM) — misma del PD de balance
#   - Ke: relación pulsos de encoder <-> velocidad real (m/s por pulso),
#         que depende de la resolución del encoder, radio de rueda r,
#         y el período de muestreo Ts (5 ms, Control_Frequency=200)
#
#   Velocity_Kp_firmware = Kp_v * Ke / Km
#   Velocity_Ki_firmware = Ki_v * Ke / Km
#
# Ke se obtiene de la resolución del encoder (pulsos/revolución) y r:
#   Ke = (2*pi*r) / (pulsos_por_revolucion * Ts)   [m/s por pulso/muestra]