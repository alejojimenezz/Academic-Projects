import systemFunc
import biseccion
import tkinter as tk

mainWindow = tk.Tk()

mainWindow.title("Proyecto Métodos Numéricos")
mainWindow.geometry()

# LEFT PANEL

leftFrame = tk.Frame(mainWindow)
leftFrame.grid(row=0, column=0, padx=5, pady=5)

tk.Label(leftFrame, text="Left frame").pack()

## Variables frame

varFrame = tk.Frame(leftFrame)
varFrame.pack()

mValue = tk.StringVar(value="1.2")
kValue = tk.StringVar(value="350")

m = float(mValue.get())
k = float(kValue.get())

tk.Label(varFrame, text="Ingrese valor de masa (m)").grid(row=0, column=0, padx=10, pady=5)
tk.Entry(varFrame, textvariable=mValue, font=("Segoe UI", 12)).grid(row=0, column=1, pady=5)

tk.Label(varFrame, text="Ingrese constante de rigidez (k)").grid(row=1, column=0, padx=10, pady=5)
tk.Entry(varFrame, textvariable=kValue, font=("Segoe UI", 12)).grid(row=1, column=1, pady=5)

## Parameters frame

paramsFrame = tk.Frame(leftFrame)
paramsFrame.pack()

maxIter = 20
tolerance = 1e-5
limInf = 0
limSup = 50

tk.Label(paramsFrame, text="Máximo # de iteraciones").grid(row=0, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=maxIter, font=("Segoe UI", 12)).grid(row=0, column=1, pady=5)

tk.Label(paramsFrame, text="Tolerancia de error").grid(row=1, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=tolerance, font=("Segoe UI", 12)).grid(row=1, column=1, pady=5)

tk.Label(paramsFrame, text="Límite inferior").grid(row=2, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=limInf, font=("Segoe UI", 12)).grid(row=2, column=1, pady=5)

tk.Label(paramsFrame, text="Límite superior").grid(row=3, column=0, padx=10, pady=5)
tk.Entry(paramsFrame, textvariable=limSup, font=("Segoe UI", 12)).grid(row=3, column=1, pady=5)

## Methods frame

methodFrame = tk.Frame(leftFrame)
methodFrame.pack()

tk.Button(methodFrame, text="Bisección", command=biseccion.bisect(maxIter, tolerance, limInf, limSup, m, 0, k)).grid(row=0, column=0)

# RIGHT PANEL

graphFrame = tk.Frame(mainWindow)
graphFrame.grid(row=0, column=1, padx=5, pady=5)

tk.Label(graphFrame, text="Right frame").pack()

mainWindow.grid_rowconfigure(0, weight=1)
mainWindow.grid_columnconfigure(0, weight=1)

mainWindow.mainloop()
