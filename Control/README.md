# MicroROS Self-balancing robot

> Robot auto balanceable MicroROS

## Funcionamiento

```mermaid
flowchart TD

    a["STM32"]
    b["ESP32"]

    A["Control PID"]
    B["Cambio de parámetros"]

    AA["C: Keil MDK / STM32CubeIDE"]
    BB["C++: ArduinoIDE / PlatformIO"]
    
a --UART serial--- b
A ~~~ B
AA ~~~ BB
```

## Recursos de apoyo

### [Página oficial](https://www.yahboom.net/study/SBR-microROS)

**Unidad 12** - "STM32 Balancing case": Control PID y LQR

### Firmware

#### Balance STM32

#### Firmware de fábrica

### Códigos

#### Modelo matemático

#### MatLab

#### Julia