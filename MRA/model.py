import numpy as np
import matplotlib.pyplot as plt

m = 1.2
b = 0.5
k = 350

# omega_n = np.sqrt(k/m)
omega_n = 17.0783
print("Frecuencia natural (rad/s):", omega_n)

omega = np.linspace(0.1, 50, 2000)

def amplitude(omega, m, b, k):
    num = 1
    den = np.sqrt((k - m*omega**2)**2 + (b*omega)**2)
    return num / den

X = amplitude(omega, m, b, k)

plt.figure(figsize=(10,5))
plt.plot(omega, X, linewidth=2)
plt.axvline(omega_n, color='r', linestyle='--', label=f"{omega_n:.2f} rad/s")
plt.title("Respuesta en amplitud del sistema vs frecuencia", fontsize=14)
plt.xlabel("Frecuencia (rad/s)")
plt.ylabel("Amplitud")
plt.grid(True)
plt.legend()
plt.show()
