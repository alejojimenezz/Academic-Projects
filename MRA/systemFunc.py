def mainFunction(omega, m, b, k):
    return m*omega**2 + b*omega - k

def diff1Function(omega, m, b):
    return 2*m*omega + b

if __name__=="__main__":
    
    m = 1.2
    b = 0
    k = 350

    result = mainFunction(0, m, b, k)
    print(result)