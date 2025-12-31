#include <Arduino.h>
#include <driver/ledc.h>

const int IN1 = 16;
const int IN2 = 17;
const int ENA = 4; // pin PWM
const int encAL = 32;
const int encBL = 33;

volatile long ticks = 0;
portMUX_TYPE mux = portMUX_INITIALIZER_UNLOCKED;

const int PPR_ENCODER = 12;
const int GEAR_RATIO = 64;
const int PULSOS_POR_REV = PPR_ENCODER * 4 * GEAR_RATIO;
const float GRADOS_POR_PULSO = 360.0f / PULSOS_POR_REV;

const int8_t transTable[16] = {
  0,  -1,  +1,  0,
  +1,  0,   0, -1,
  -1,  0,   0, +1,
  0,  +1,  -1,  0
};

volatile uint8_t prevState = 0;

const ledc_mode_t pwmSpeed = LEDC_LOW_SPEED_MODE;
const ledc_channel_t pwmChannel = (ledc_channel_t)LEDC_CHANNEL_0;
const ledc_timer_t pwmTimer = (ledc_timer_t)LEDC_TIMER_0;
const int pwmFreq = 20000;       // 20 kHz
const ledc_timer_bit_t pwmResolution = LEDC_TIMER_8_BIT; // 0..255

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
  if(value > 255) value = 255;
  ledc_set_duty(pwmSpeed, pwmChannel, value);
  ledc_update_duty(pwmSpeed, pwmChannel);
}

void IRAM_ATTR isrAL() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    ticks += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

void IRAM_ATTR isrBL() {
  // misma rutina: recomputa el estado y aplica delta
  uint8_t s = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  uint8_t idx = (prevState << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&mux);
    ticks += delta;
    portEXIT_CRITICAL_ISR(&mux);
  }
  prevState = s;
}

// PID ______________________________________________________________
float kp = 1.8;
float ki = 0.0;
float kd = 0.0;

volatile float setPoint;
volatile int lastCmdDir = 0;

const unsigned long sampleTime = 10; // Ejecuta PID cada 10ms
unsigned long lastTime = 0;

unsigned long currentTime, previousTime;
double elapsedTime;
double error, lastError, cumError, rateError;

// Limites
const float integralMax = 200.0;
const int pwmMax = 255;
const int pwmMin = 0;

const float angleTol = 1.0f;

void setup() {
  Serial.begin(115200);
  delay(10);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(encAL, INPUT_PULLUP);
  pinMode(encBL, INPUT_PULLUP);
  
  prevState = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  attachInterrupt(digitalPinToInterrupt(encAL), isrAL, CHANGE);
  attachInterrupt(digitalPinToInterrupt(encBL), isrBL, CHANGE);

  setupPWM();
  setPWM(0);

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);

  setPoint = 45.0;

  float initialAngle = getEncDegrees();
  float initialErr = wrap180(setPoint - initialAngle);
  // float initialErr = setPoint - initialAngle;

  previousTime = millis();
  cumError = 0.0;
  lastError = initialErr;

  Serial.print("Controlador PID para motor ligero (ESP32) a ");
  Serial.print(setPoint);
  Serial.println(" grados");
}

void loop() {

  if (Serial.available()) {
    char c = Serial.read();
    if (c == 's' || c == 'S') {

      // Apaga motor
      digitalWrite(IN1, LOW);
      digitalWrite(IN2, LOW);
      setPWM(0);

      Serial.println(">>> EMERGENCIA ACTIVADA: Motor detenido <<<");

      // Bucle infinito
      while (true) {
        Serial.println("Sistema detenido por EMERGENCIA.");
        delay(500);
      }
    }
  }

  unsigned long now = millis();
  if(now - previousTime >= sampleTime) {

    float input = getEncDegrees();  // Input para el PID
    double dt = (now-previousTime)/1000.0;
    float output = computePID(input, dt);
    Serial.print("Angulo: ");
    Serial.print(input, 2);
    Serial.print(" Output: ");
    Serial.println(output, 2);
    // Saturación
    if (output > pwmMax) output = pwmMax;
    if (output < -pwmMax) output = -pwmMax;

    applyMotorOutput(output);

    previousTime = now;

  }

}

// Función para obtener lectura de encoder en grados_________________________________________
float getEncDegrees() {
  long ticksActual;
  portENTER_CRITICAL(&mux);
  ticksActual = ticks;
  portEXIT_CRITICAL(&mux);

  long ticksMod = ((ticksActual % PULSOS_POR_REV) + PULSOS_POR_REV) % PULSOS_POR_REV;
  float angulo = (float)ticksMod * GRADOS_POR_PULSO;

  // Serial.print("Pulsos: ");
  // Serial.print(ticksActual);
  // Serial.print("  Angulo: ");
  // Serial.print(angulo, 2);
  // Serial.println(" deg");

  return angulo;
}

// envuelve ángulo a [-180, +180]
float wrap180(float ang) {
  while (ang > 180.0f) ang -= 360.0f;
  while (ang <= -180.0f) ang += 360.0f;
  return ang;
}

// Función del controlador PID_______________________________________________
float computePID(float inp, double dt) {
  if (dt <= 0.0) return 0.0;

  float rawErr = setPoint - inp;
  float error = wrap180(rawErr);
  // float error = rawErr;

  // Integración (con anti-windup por saturación)
  cumError += error * dt;
  // Limitar integral para evitar windup
  if (cumError > integralMax) cumError = integralMax;
  if (cumError < -integralMax) cumError = -integralMax;

  // Derivada
  double deriv = (error - lastError) / dt;

  // Salida PID en unidades de PWM
  double output = kp * error + ki * cumError + kd * deriv;
  
  lastError = error;

  return (float)output;
}

// Función para aplicar salida al puente H_________________________________
void applyMotorOutput(float out) {

  int pwmVal = (int)abs(out);
  if (pwmVal > pwmMax) pwmVal = pwmMax;

  if (out > 1.0) {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
    setPWM(pwmVal);
    lastCmdDir = +1;
  } else if (out < -1.0) {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
    setPWM(pwmVal);
    lastCmdDir = -1;
  } else {
    // stop / coast
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    setPWM(0);
    lastCmdDir = 0;
    return;
  }

}
