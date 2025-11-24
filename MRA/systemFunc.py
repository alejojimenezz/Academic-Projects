def mainFunction(omega, m, b, k):
    return m*omega**2 + b*omega - k

if __name__=="__main__":
    
    m = 1.2
    b = 0
    k = 350

    result = mainFunction(0, m, b, k)
    print(result)