#include <Arduino.h>
#include <driver/ledc.h>

// Pines
const int IN1 = 17;
const int IN2 = 16;
const int ENA = 4; // PWM
const int encA = 32;
const int encB = 33;

// Encoder + protección
volatile long ticks = 0;
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

const int PPR_ENCODER = 12;
const int GEAR_RATIO = 64;
const long PULSOS_POR_REV = (long)PPR_ENCODER * 4L * (long)GEAR_RATIO;
const float GRADOS_POR_PULSO = 360.0f / (float)PULSOS_POR_REV;

const int8_t transTable[16] = {
  0,  -1,  +1,  0,
  +1,  0,   0, -1,
  -1,  0,   0, +1,
  0,  +1,  -1,  0
};
volatile uint8_t prevState = 0;

// PWM (LEDC)
const ledc_mode_t pwmSpeed = LEDC_LOW_SPEED_MODE;
const ledc_channel_t pwmChannel = (ledc_channel_t)LEDC_CHANNEL_0;
const ledc_timer_t pwmTimer = (ledc_timer_t)LEDC_TIMER_0;
const int pwmFreq = 20000;
const ledc_timer_bit_t pwmResolution = LEDC_TIMER_8_BIT;

void setupPWM() {
  ledc_timer_config_t timer_cfg = {
    .speed_mode = pwmSpeed,
    .duty_resolution = pwmResolution,
    .timer_num = pwmTimer,
    .freq_hz = pwmFreq,
    .clk_cfg = LEDC_AUTO_CLK
  };
  ledc_timer_config(&timer_cfg);

  ledc_channel_config_t ch_cfg = {
    .gpio_num = ENA,
    .speed_mode = pwmSpeed,
    .channel = pwmChannel,
    .intr_type = LEDC_INTR_DISABLE,
    .timer_sel = pwmTimer,
    .duty = 0,
    .hpoint = 0
  };
  ledc_channel_config(&ch_cfg);
}

void setPWM(uint32_t value) {
  if (value > 255) value = 255;
  ledc_set_duty(pwmSpeed, pwmChannel, value);
  ledc_update_duty(pwmSpeed, pwmChannel);
}

// ISR cuadratura
void IRAM_ATTR isrA() {
  uint8_t s = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    ticks += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

void IRAM_ATTR isrB() {
  uint8_t s = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    ticks += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

void setup() {
  Serial.begin(115200);
  delay(10);

  // Pines
  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(encA, INPUT_PULLUP);
  pinMode(encB, INPUT_PULLUP);

  // Encoder
  prevState = (gpio_get_level((gpio_num_t)encA) << 1) | gpio_get_level((gpio_num_t)encB);
  attachInterrupt(digitalPinToInterrupt(encA), isrA, CHANGE);
  attachInterrupt(digitalPinToInterrupt(encB), isrB, CHANGE);

  // PWM
  setupPWM();

  // Dirección y PWM fijo
  digitalWrite(IN1, LOW);
  digitalWrite(IN2, HIGH);
  setPWM(50);

  // Cabecera opcional (el plotter suele ignorar texto)
  Serial.println("time_s angle_deg");
  Serial.println("---- Serial Monitor below (human-readable) ----");
}

// ---------- parámetros de muestreo y control del tiempo ----------
const unsigned long printIntervalMs = 10; // ms entre puntos del plot (ajusta)
unsigned long lastPrint = 0;
unsigned long startTimeMs = 0;      // tiempo base que puede reiniciarse

void loop() {
  unsigned long now = millis();

  // Leer Serial para comandos:
  // 's' o 'S' -> parada emergencia (detiene motor y bloquea)
  // 'r' o 'R' -> reset tiempo acumulado (startTimeMs = now)
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 's' || c == 'S') {
      setPWM(0);
      digitalWrite(IN1, LOW);
      digitalWrite(IN2, LOW);
      Serial.println("EMERGENCIA: motor detenido.");
      while (true) { delay(500); } // bloqueo seguro
    } else if (c == 'r' || c == 'R') {
      startTimeMs = now;
      Serial.println("Reset tiempo: START = now");
    }
  }

  // Inicializar startTime en el primer loop
  if (startTimeMs == 0) startTimeMs = now;

  // muestreo y envío al Serial Plotter + Monitor
  if (now - lastPrint >= printIntervalMs) {
    lastPrint = now;
    float time_s = (now - startTimeMs) / 1000.0f;

    // leer ticks protegido
    long ticksActual;
    portENTER_CRITICAL(&mux);
    ticksActual = ticks;
    portEXIT_CRITICAL(&mux);

    long ticksMod = ((ticksActual % PULSOS_POR_REV) + PULSOS_POR_REV) % PULSOS_POR_REV;
    float angle = (float)ticksMod * GRADOS_POR_PULSO;

    // 1) Línea numérica simple para Serial Plotter (time angle)
    Serial.print(time_s, 3);
    Serial.print(' ');
    Serial.println(angle, 3);

    // 2) Línea legible para Serial Monitor
    Serial.print("Pulsos: ");
    Serial.print(ticksActual);
    Serial.print("  Ángulo: ");
    Serial.print(angle, 3);
    Serial.print(" °  Tiempo: ");
    Serial.print(time_s, 3);
    Serial.println(" s");
  }
}
