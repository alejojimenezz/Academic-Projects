import systemFunc
import biseccion
import posFalsa
import tkinter as tk
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

mainWindow = tk.Tk()

mainWindow.title("Proyecto Métodos Numéricos")
mainWindow.geometry()

# LEFT PANEL

leftFrame = tk.Frame(mainWindow)
leftFrame.grid(row=0, column=0, padx=5, pady=5)

tk.Label(leftFrame, text="Left frame").pack()

## Result Frame

resultFrame = tk.Frame(leftFrame)
resultFrame.pack(fill="x")

resultLabel = tk.Label(resultFrame, text="Raíz: ", font=("Segoe UI", 14, "bold"))
resultLabel.pack(pady=15)

## Variables frame

varFrame = tk.Frame(leftFrame)
varFrame.pack(pady=15)

mValue = tk.StringVar(value="1.2")
kValue = tk.StringVar(value="350")

tk.Label(varFrame, text="Ingrese valor de masa (m)").grid(row=0, column=0, padx=10, pady=5)
tk.Entry(varFrame, textvariable=mValue, font=("Segoe UI", 12)).grid(row=0, column=1, pady=5)

tk.Label(varFrame, text="Ingrese constante de rigidez (k)").grid(row=1, column=0, padx=10, pady=5)
tk.Entry(varFrame, textvariable=kValue, font=("Segoe UI", 12)).grid(row=1, column=1, pady=5)

## Parameters frame

paramsFrame = tk.Frame(leftFrame)
paramsFrame.pack(pady=15)

maxIterEntry = tk.StringVar(value="20")
toleranceEntry = tk.StringVar(value="1e-5")
limInfEntry = tk.StringVar(value="0")
limSupEntry = tk.StringVar(value="50")

tk.Label(paramsFrame, text="Máximo # de iteraciones").grid(row=0, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=maxIterEntry, font=("Segoe UI", 12)).grid(row=0, column=1, pady=5)

tk.Label(paramsFrame, text="Tolerancia de error").grid(row=1, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=toleranceEntry, font=("Segoe UI", 12)).grid(row=1, column=1, pady=5)

tk.Label(paramsFrame, text="Límite inferior").grid(row=2, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=limInfEntry, font=("Segoe UI", 12)).grid(row=2, column=1, pady=5)

tk.Label(paramsFrame, text="Límite superior").grid(row=3, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=limSupEntry, font=("Segoe UI", 12)).grid(row=3, column=1, pady=5)

## Methods frame

methodFrame = tk.Frame(leftFrame)
methodFrame.pack(pady=15)

canvas_widget = None

def runNumericalMethod(methodFunc, methodName):
    global canvas_widget

    maxIter = int(maxIterEntry.get())
    tolerance = float(toleranceEntry.get())
    limInf = float(limInfEntry.get())
    limSup = float(limSupEntry.get())
    m = float(mValue.get())
    b = 0
    k = float(kValue.get())

    result = methodFunc(maxIter, tolerance, limInf, limSup, m, b, k)

    if result is None:
        resultLabel.config(text="No hay cambio de signo en el intervalo")
        return
    
    try:
        root, errors, iters = result
        last_error = errors[-1] if errors else 0
        last_iter = iters[-1] if iters else 0
        resultLabel.config(text=f"Raíz: {root:.6f} ± {last_error:.2e}   (Iteraciones): {last_iter}")

        updateGraph(iters, errors)

    except Exception:
        if isinstance(result, (int, float)):
            resultLabel.config(text=f"Raíz: {result:.6f}")
        else:
            resultLabel.config(text=f"Resultado inesperado de {methodName}")

def updateGraph(iters, errors):
    global canvas_widget

    if canvas_widget is not None:
        canvas_widget.get_tk_widget().destroy()
        canvas_widget = None
    
    fig = Figure(figsize=(5.5, 4), dpi=100)
    ax = fig.add_subplot(111)
    ax.plot(iters, errors, marker='o', linestyle='-', linewidth=2, markersize=4)
    ax.set_title("Error vs Iteración", fontsize=12, fontweight='bold')
    ax.set_xlabel("Iteración", fontsize=10)
    ax.set_ylabel("Error", fontsize=10)
    ax.grid(True, alpha=0.3)
    ax.set_yscale('log')
    
    fig.tight_layout()

    canvas_widget = FigureCanvasTkAgg(fig, master=graphFrame)
    canvas_widget.draw()
    canvas_widget.get_tk_widget().pack(fill="both", expand=True)

runBisect = lambda: runNumericalMethod(biseccion.bisect, "bisección")
runFalsePos = lambda: runNumericalMethod(posFalsa.falsePos, "posición falsa")

bisectButton = tk.Button(methodFrame, text="Bisección", command=runBisect).grid(row=0, column=0)

falsePosButton = tk.Button(methodFrame, text="Posición falsa", command=runFalsePos).grid(row=0, column=1)

# RIGHT PANEL

graphFrame = tk.Frame(mainWindow)
graphFrame.grid(row=0, column=1, padx=5, pady=5)

tk.Label(graphFrame, text="Right frame").pack()

mainWindow.grid_rowconfigure(0, weight=1)
mainWindow.grid_columnconfigure(0, weight=1)

mainWindow.mainloop()
