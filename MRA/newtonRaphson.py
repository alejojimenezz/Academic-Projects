# TODO: Throw exception for diffValueRes == 0

import systemFunc

def newtonRaphson(maxIter, tolerance, value, unused, m, b, k):
    errors = []
    iters = []
    i = 0

    valueRes = systemFunc.mainFunction(value, m, b, k)
    diffValueRes = systemFunc.diff1Function(value, m, b)

    if diffValueRes == 0:
        print("Seleccionar otro valor inicial")
        return value, errors, iters
    
    while i < maxIter:

        newRaphValue = value-(valueRes/diffValueRes)

        error = abs(newRaphValue - value)

        errors.append(error)
        iters.append(i+1)

        newRaphValueRes = systemFunc.mainFunction(newRaphValue, m, b, k)

        if error < tolerance:
            return newRaphValue, errors, iters

        i += 1
        if i == maxIter or newRaphValueRes == 0:
            return newRaphValue, errors, iters
        else:
            value = newRaphValue
            valueRes = newRaphValueRes
            diffValueRes = systemFunc.diff1Function(value, m, b)
            continue

if __name__ == "__main__":

    maxIter = 50
    tolerance = 1e-5
    value = 0

    m = 1.2
    b = 0       # Sin amortiguamiento
    k = 350

    testRes, errors, iters = newtonRaphson(maxIter, tolerance, value, m, b, k)
    print(testRes)
    print(errors[-1])
    print(iters[-1])