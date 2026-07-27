# Diseño Analítico del Controlador PID — Robot de Equilibrio en Dos Ruedas

**Proyecto:** Control de robot de balance de dos ruedas
**Controladores implementados:** PD de balance (ángulo), PI de velocidad
**Motor:** JGB37-520, 12V, 333RPM, encoder Hall en cuadratura

---

## 1. Introducción y arquitectura de control

El robot se estabiliza mediante tres lazos de control en cascada, todos ejecutándose sobre el mismo actuador (PWM de cada rueda) a una frecuencia de control de **200 Hz** ($T_s = 5$ ms):

```c
Motor_Left  = Balance_Pwm + Velocity_Pwm + Turn_Pwm;
Motor_Right = Balance_Pwm + Velocity_Pwm - Turn_Pwm;
```

| Lazo      | Tipo | Entrada                                   | Rol                                                                                |
| --------- | ---- | ----------------------------------------- | ---------------------------------------------------------------------------------- |
| Balance   | PD   | Ángulo de inclinación $\theta$ (IMU)      | Mantener el robot en equilibrio (lazo crítico, más rápido)                         |
| Velocidad | PI   | Encoders (suma de pulsos izq+der)         | Controlar velocidad lineal, actúa como sesgo sobre el balance                      |
| Giro      | PD   | Giroscopio (velocidad angular $\dot\psi$) | Amortiguar oscilaciones de giro; el comando de giro real es feedforward (`Move_Z`) |

El objetivo de este trabajo fue obtener las ganancias de cada lazo mediante un **modelo linealizado del sistema**, en vez de sintonizar puramente por prueba y error.

---

## 2. Modelo dinámico linealizado

### 2.1 Parámetros físicos

Los siguientes parámetros físicos fueron obtenidos de datos de simulación y código proporcionado por el fabricante.

| Parámetro                  | Símbolo             | Valor                      |
| -------------------------- | ------------------- | -------------------------- |
| Masa de cada rueda         | $m$                 | 0.035 kg                   |
| Radio de rueda             | $r$                 | 0.0336 m                   |
| Inercia de la rueda        | $I_{rueda}=0.5mr^2$ | $1.976\times10^{-5}$ kg·m² |
| Masa del cuerpo            | $M$                 | 0.930 kg                   |
| Distancia CM al chasis     | $L$                 | 0.0383 m                   |
| Inercia del cuerpo (pitch) | $J_{centroide}$     | $7.110\times10^{-4}$ kg·m² |
| Ancho de vía               | $d$                 | 0.1612 m                   |
| Gravedad                   | $g$                 | 9.8 m/s²                   |

### 2.2 Espacio de estados

Estado: $x=[\text{posición},\ v,\ \theta,\ \dot\theta,\ \psi,\ \dot\psi]^T$. Las matrices $A$, $B$ se derivaron por Lagrange.

---

## 3. Lazo de balance (PD) — Ángulo de inclinación

### 3.1 Primer modelo (simplificado, 2 estados)

Como primera aproximación, se modeló el sistema como un péndulo invertido clásico sobre un carro, con ecuaciones de Lagrange linealizadas para $x$ (posición del eje) y $\theta$ (inclinación):

$$(M_w+M)\ddot x + ML\ddot\theta = F, \qquad ML\ddot x+(J+ML^2)\ddot\theta = MgL\theta$$

con $M_w=3m=0.105$ kg (masa efectiva de traslación de ambas ruedas, incluyendo inercia rotacional reflejada). Resolviendo para $\Theta(s)/F(s)$:

$$\frac{\Theta(s)}{F(s)} = \frac{-K}{s^2-a^2}, \qquad a = 20.27 \text{ rad/s}, \quad K = 40.51$$

Diseñando por asignación de polos con $\zeta=0.7$, $\omega_n=25$ rad/s:

$$K_{p} = 25.57 \qquad K_{d} = 0.864$$

### 3.2 Modelo refinado (usando las matrices A, B completas del proyecto)

Para mayor rigor, se repitió el análisis extrayendo directamente el subsistema de $\theta$ de las matrices A, B de 6 estados usadas en el LQR real (`A_43`, `B_41`, `B_42`):

$$\ddot\theta = A_{43}\,\theta + 2B_{41,actual}\,u, \qquad A_{43}=410.97\ (a=20.27\text{ rad/s}), \quad K=2.8028$$

donde $u$ es el torque común aplicado a cada rueda (N·m). Con los mismos $\zeta=0.7$, $\omega_n=25$ rad/s:

$$
K_{p}^{(2)} = 369.64 \text{ N·m/rad} \qquad K_{d}^{(2)} = 12.49 \text{ N·m·s/rad}
$$

**Ganancia mínima de estabilidad**: $K_{p} > a^2/K = 146.64$ N·m/rad — cualquier valor por debajo de este mínimo no puede balancear el robot, independiente de $K_d$.

> [!IMPORTANT] Para tener en cuenta:
> Ya que en el mísmo código proporcionado por el fabricante, se dan límites para los K, nos apoyamos de estos para la elección de cuáles constantes usar.
> Nos inclinamos por $K_p$ y $K_d$ obtenidas en el primer modelo, ya que éstas cumplen dichos límites.

### 3.3 Simulación

Con condición inicial de 5° de inclinación, el diseño simplificado (modelo 1) predice:
- Tiempo de asentamiento = 0.235 s (criterio 2%)
- Sobreimpulso = 4.60 %

---

## 4. Lazo de velocidad (PI)

### 4.1 Reducción de orden

Con el lazo de ángulo ya cerrado (usando $K_{p}^{(1)}, K_{d}^{(1)}$), se aplicó separación de escalas de tiempo para obtener el modelo "visto" por el lazo de velocidad. Extrayendo el subsistema $[\theta,\dot\theta,v]$ con entrada $u_{vel}$ (par adicional sumado directamente al PWM total, igual que en el firmware):

$$\frac{V(s)}{U_{vel}(s)} \approx \frac{K_v}{s}, \qquad K_v = -0.02224$$

El sistema se comporta como un **integrador puro**: un torque adicional sostenido produce una aceleración lineal constante.

### 4.2 Diseño PI

Con $U_{vel}=K_{p}(V_t-V)+K_{i}\int(V_t-V)\,dt$ y ecuación característica $s^2+K_vK_{p,v}s+K_vK_{i,v}=0$, eligiendo $\zeta_v=0.8$, $\omega_{n,v}=1.0$ rad/s (deliberadamente ~25 veces más lento que el lazo de ángulo, condición necesaria para que la reducción de orden sea válida):

$$K_{p} = 71.95 \text{ N·m/(m/s)} \qquad K_{i} = 35.975 \text{ N·m/m}$$

Se verificó que elegir $\omega_{n,v}$ más rápido (ej. 3 rad/s) degrada el amortiguamiento del lazo interno de ángulo (interacción entre lazos), confirmando la necesidad de esta separación conservadora de anchos de banda.

### 4.3 Verificación de estabilidad del sistema completo

Con el sistema aumentado de 4 estados $[\theta,\dot\theta,v,\int e]$, los 4 polos en lazo cerrado resultaron con parte real negativa (estable). Simulando un escalón de referencia de 0.2 m/s: ángulo máximo inducido ≈ 3.9°, asentamiento ≈ 4.5 s, lo que es consistente con la hipótesis de ángulos pequeños usada en toda la linealización.

---

## 5. Implementación final en hardware

Resultado final, funcionando establemente con oscilación leve:

```c
float Balance_Kp = 255.7;
float Balance_Kd = 0.864;
float Velocity_Kp = 71.95;
float Velocity_Ki = 44.97;
float Turn_Kp = 1400;   // valor de fábrica, sin modificar
float Turn_Kd = 10;     // valor de fábrica, sin modificar
```