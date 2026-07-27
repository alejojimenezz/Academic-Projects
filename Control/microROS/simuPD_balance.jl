# ============================================================
#  pid_balance_PD.jl
#  Sintonización analítica del PD de balance (lazo de ángulo)
#  Robot de equilibrio en dos ruedas — mismo modelo que parametros_LQR.jl
#
#  Requiere: ControlSystems.jl, Plots.jl (mismos paquetes del LQR)
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
d = 0.1612
J_Y_delta = J_centroide
g = 9.8

Q_aux = J_centroide * M + (J_centroide + M*L^2) * (2*m + 2*inercia/r^2)

A_23 = -(M^2 * L^2 * g) / Q_aux
A_43 = M * L * g * (M + 2*m + 2*inercia/r^2) / Q_aux

B_41 = -(M*L/r + M + 2*m + 2*inercia/r^2) / Q_aux
B_42 = B_41

# Ganancia real de la matriz B (con el factor inercia/r, igual que en tu LQR)
B41_actual = (inercia/r) * B_41
B42_actual = (inercia/r) * B_42

@printf "A_43 (= a²)       = %.4f\n" A_43
@printf "B41_actual        = %.6f\n" B41_actual

# ------------------------------------------------------------
# 2. Subsistema de balance (2 estados: θ, θ̇)
#    Control común a ambas ruedas: u = u1 = u2  (como Balance_Pwm)
#    θ̈ = A_43·θ + (B41_actual + B42_actual)·u
# ------------------------------------------------------------
a2 = A_43
a = sqrt(a2)
K = abs(B41_actual + B42_actual)      # ganancia de torque por comando común

@printf "\na (tasa natural de caída)     = %.4f rad/s\n" a
@printf "K (ganancia torque/comando)   = %.4f\n" K
@printf "Kp,f mínimo para estabilidad  = %.4f N·m/rad\n" (a2/K)

# Modelo en espacio de estados del subsistema de balance (planta abierta)
A_bal = [0 1; a2 0]
B_bal = [0; -K]          # signo negativo: Θ/U = -K/(s²-a²)
C_bal = [1 0]
D_bal = [0]
sys_bal = ss(A_bal, B_bal, C_bal, D_bal)

# ------------------------------------------------------------
# 3. Diseño PD por asignación de polos
#    Control: u = Kp_f·θ + Kd_f·θ̇   (misma estructura que Balance_PD del firmware)
#    Ecuación característica lazo cerrado: s² + K·Kd_f·s + (K·Kp_f - a²) = 0
# ------------------------------------------------------------
zeta = 0.7          # factor de amortiguamiento (≈5% sobreimpulso)
wn = 25.0          # frecuencia natural deseada [rad/s] — más rápida que 'a'

Kp_f = (wn^2 + a2) / K
Kd_f = (2*zeta*wn) / K

@printf "\n--- Ganancias PD analíticas (unidades físicas) ---\n"
@printf "Kp_f = %.4f  N·m/rad\n" Kp_f
@printf "Kd_f = %.4f  N·m·s/rad\n" Kd_f

# Raíces de una ecuación cuadrática s² + b·s + c = 0 (evita depender de Polynomials.jl)
function raices_cuadratica(b, c)
    disc = Complex(b^2 - 4c)
    s1 = (-b + sqrt(disc)) / 2
    s2 = (-b - sqrt(disc)) / 2
    return [s1, s2]
end

# Verificación: polos en lazo cerrado
p_cl = raices_cuadratica(K*Kd_f, K*Kp_f - a2)
println("\nPolos en lazo cerrado: ", p_cl)

# ------------------------------------------------------------
# 4. Root locus variando Kp_f (con Kd_f fijo en el valor diseñado)
#    Útil para mostrar en la presentación cómo el polo inestable
#    se mueve al semiplano izquierdo al subir la ganancia
# ------------------------------------------------------------
Kp_range = 0:1:800
polos_reales_1 = Float64[]
polos_reales_2 = Float64[]
polos_imag_1 = Float64[]
polos_imag_2 = Float64[]

for kp in Kp_range
    p = raices_cuadratica(K*Kd_f, K*kp - a2)
    push!(polos_reales_1, real(p[1]));
    push!(polos_imag_1, imag(p[1]))
    push!(polos_reales_2, real(p[2]));
    push!(polos_imag_2, imag(p[2]))
end

p_rlocus = plot(polos_reales_1, polos_imag_1, label="Rama 1", color=:blue, linewidth=2)
plot!(p_rlocus, polos_reales_2, polos_imag_2, label="Rama 2", color=:red, linewidth=2)
scatter!(p_rlocus, [a, -a], [0, 0], label="Polos en lazo abierto", color=:black, markershape=:x, markersize=6)
scatter!(p_rlocus, real(p_cl), imag(p_cl), label="Polos diseñados", color=:green, markershape=:star5, markersize=8)
vline!(p_rlocus, [0], color=:gray, linestyle=:dash, label="")
xlabel!(p_rlocus, "Re(s)")
ylabel!(p_rlocus, "Im(s)")
title!(p_rlocus, "Lugar de las raíces — Lazo de balance (Kd_f fijo)")

savefig(p_rlocus, "root_locus_balance.png")
println("\nGráfica guardada en: root_locus_balance.png")

# ------------------------------------------------------------
# 5. Simulación de la respuesta al escalón en lazo cerrado
#    Perturbación inicial: robot arranca con 5° de inclinación
# ------------------------------------------------------------
A_cl = [0 1; (a2 - K*Kp_f) -K*Kd_f]
B_cl = [0; 0]     # sin entrada externa, solo condición inicial
C_cl = Matrix{Float64}(I, 2, 2)
D_cl = zeros(2, 1)
sys_cl = ss(A_cl, B_cl, C_cl, D_cl)

t_sim = 0.0:0.005:2.0        # Ts = 5ms, igual que Control_Frequency = 200 Hz
x0 = [deg2rad(5.0), 0.0]     # condición inicial: 5° de inclinación

Y, t_out, X = lsim(sys_cl, zeros(1, length(t_sim)), t_sim, x0)

# Reconstruir la señal de control u = Kp_f·θ + Kd_f·θ̇
U = Kp_f .* X[1, :] .+ Kd_f .* X[2, :]

p1 = plot(t_out, X[1, :] .* (180/π), label="θ [°]", color=:red, linewidth=2,
    xlabel="Tiempo [s]", ylabel="Ángulo [°]",
    title="Respuesta del PD de balance (condición inicial: 5°)")
p2 = plot(t_out, U, label="u [N·m] (por rueda)", color=:blue, linewidth=2,
    xlabel="Tiempo [s]", ylabel="Torque [N·m]",
    title="Señal de control")

fig = plot(p1, p2, layout=(2, 1), size=(800, 600), margin=5Plots.mm)
display(fig)
savefig(fig, "respuesta_PD_balance.png")
println("Gráfica guardada en: respuesta_PD_balance.png")

# ------------------------------------------------------------
# 6. Resumen numérico
# ------------------------------------------------------------
settle_idx = findlast(abs.(X[1, :]) .> 0.02*abs(x0[1]))
t_settle = settle_idx === nothing ? 0.0 : t_out[settle_idx]
overshoot = (minimum(X[1, :]) < 0) ? abs(minimum(X[1, :]))/x0[1]*100 : 0.0

@printf "\n--- Resumen respuesta al escalón ---\n"
@printf "Ángulo inicial          : %.2f °\n" rad2deg(x0[1])
@printf "Tiempo de asentamiento  : %.3f s (criterio 2%%)\n" t_settle
@printf "Sobreimpulso            : %.2f %%\n" overshoot
@printf "|u| máximo              : %.4f N·m\n" maximum(abs.(U))

# ------------------------------------------------------------
# 7. NOTA IMPORTANTE — Conversión a unidades de PWM (firmware)
# ------------------------------------------------------------
# El firmware (pid_control.h) usa Balance_Kp y Balance_Kd en PWM/°,
# no en N·m/rad. La conversión requiere una constante de motor Km
# (torque equivalente por unidad de PWM):
#
#   Balance_Kp_firmware = Kp_f / (57.3 * Km)
#   Balance_Kd_firmware = Kd_f / (57.3 * Km)
#
# Km se obtiene de:
#   (a) datasheet del motor (constante de torque × relación de reducción), o
#   (b) calibración empírica: aplicar un escalón de PWM conocido con el
#       robot fijo verticalmente (ruedas libres) y medir la aceleración
#       angular resultante para despejar Km directamente.
#
# Nota: la razón Kp_firmware/Kd_firmware NO depende de Km (se cancela),
# así que se puede comparar directamente contra la razón de fábrica:
#   Fábrica: 10200/78 = 130.8
#   Analítica (con wn=25, zeta=0.7): Kp_f/Kd_f = 369.64/12.49 = 29.6 (ver cálculo)
println("\nKp_f/Kd_f = ", Kp_f/Kd_f)