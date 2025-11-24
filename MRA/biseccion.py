import systemFunc

def bisect(maxIter, tolerance, limInf, limSup, m, b, k):
    errors = []
    iters = []
    i = 0

    infRes = systemFunc.mainFunction(limInf, m, b, k)
    supRes = systemFunc.mainFunction(limSup, m, b, k)

    eval = infRes * supRes

    if eval == 0:
        if systemFunc.mainFunction(limInf, m, b, k) == 0:
            return limInf
        else:
            return limSup
    elif eval > 0:
        return None
    else:
        while i < maxIter:

            error = (limSup-limInf)/2**(i+1)

            errors.append(error)
            iters.append(i+1)

            midPoint = (limInf+limSup)/2
            newRes = systemFunc.mainFunction(midPoint, m, b, k)

            if error < tolerance:
                return midPoint, errors, iters

            i += 1
            if i == maxIter or newRes == 0:
                return midPoint, errors, iters
            elif newRes * infRes < 0:
                limSup = midPoint
                supRes = newRes
                continue
            else:
                limInf = midPoint
                infRes = newRes
                continue

if __name__ == "__main__":

    maxIter = 50
    tolerance = 1e-5
    limInf = 0
    limSup = 50

    m = 1.2
    b = 0       # Sin amortiguamiento
    k = 350

    testRes, errors, iters = bisect(maxIter, tolerance, limInf, limSup, m, b, k)
    print(testRes)
    print(errors.pop(len(errors)-1))
    print(iters.pop(len(iters)-1))