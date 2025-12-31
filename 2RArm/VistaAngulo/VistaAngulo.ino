#include <Arduino.h>

const int encA = 25;
const int encB = 26;

volatile long pos = 0;
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

const int PPR_ENCODER = 12;
const int GEAR_RATIO = 64;
const int PULSOS_POR_REV = PPR_ENCODER * 4 * GEAR_RATIO; // base por revolución salida
const float GRADOS_POR_PULSO = 360.0f / PULSOS_POR_REV;

// tabla de cambios: index = (prevState << 2) | currState
// valores: -1, 0, +1 (0 significa no cambio o error)
const int8_t transTable[16] = {
  0,  -1,  +1,  0,   // 00 -> 00,01,10,11
  +1,  0,   0, -1,   // 01 -> ...
  -1,  0,   0, +1,
  0,  +1,  -1,  0
};

volatile uint8_t prevState = 0;

void IRAM_ATTR isrA() {
  uint8_t s = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    pos += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

void IRAM_ATTR isrB() {
  // misma rutina: recomputa el estado y aplica delta
  uint8_t s = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    pos += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

void setup() {
  pinMode(encA, INPUT_PULLUP);
  pinMode(encB, INPUT_PULLUP);
  // inicializar prevState
  prevState = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  attachInterrupt(digitalPinToInterrupt(encA), isrA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(encB), isrB, CHANGE);
  Serial.begin(115200);
  Serial.println("=== Encoder Cuadratura ===");
}

void loop() {
  long posActual;
  portENTER_CRITICAL(&mux);
  posActual = pos;
  portEXIT_CRITICAL(&mux);

  long posMod = ((posActual % PULSOS_POR_REV) + PULSOS_POR_REV) % PULSOS_POR_REV;
  float angulo = (float)posMod * GRADOS_POR_PULSO;

  Serial.print("Pos: ");
  Serial.print(posActual);
  Serial.print("   Angulo: ");
  Serial.print(angulo, 2);
  Serial.println("°");

  delay(100);
}
