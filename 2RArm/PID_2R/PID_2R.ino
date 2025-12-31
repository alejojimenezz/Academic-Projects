#include <Arduino.h>
#include <driver/ledc.h>

const int IN1 = 16;
const int IN2 = 17;
const int IN3 = 19;
const int IN4 = 18;
const int ENA = 4; // pin PWM
const int ENB = 5; // pin PWM
const int encAL = 32;
const int encBL = 33;
const int encAP = 25;
const int encBP = 26;

volatile long ticksL = 0;
volatile long ticksP = 0;
portMUX_TYPE muxL = portMUX_INITIALIZER_UNLOCKED;
portMUX_TYPE muxP = portMUX_INITIALIZER_UNLOCKED;

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

volatile uint8_t prevStateL = 0;
volatile uint8_t prevStateP = 0;

const ledc_mode_t pwmSpeed = LEDC_LOW_SPEED_MODE;
const ledc_timer_t pwmTimer = (ledc_timer_t)LEDC_TIMER_0;
const int pwmFreq = 20000;       // 20 kHz
const ledc_timer_bit_t pwmResolution = LEDC_TIMER_8_BIT; // 0..255

const ledc_channel_t pwmChannelL = (ledc_channel_t)LEDC_CHANNEL_0;
const ledc_channel_t pwmChannelP = (ledc_channel_t)LEDC_CHANNEL_1;

void setupPWMChannels() {
  ledc_timer_config_t timer_cfg = {
    .speed_mode = pwmSpeed,
    .duty_resolution = pwmResolution,
    .timer_num = pwmTimer,
    .freq_hz = pwmFreq,
    .clk_cfg = LEDC_AUTO_CLK
  };
  ledc_timer_config(&timer_cfg);

  // canal para ENA (motor L)
  ledc_channel_config_t chL = {
    .gpio_num = ENA,
    .speed_mode = pwmSpeed,
    .channel = pwmChannelL,
    .intr_type = LEDC_INTR_DISABLE,
    .timer_sel = pwmTimer,
    .duty = 0,
    .hpoint = 0
  };
  ledc_channel_config(&chL);

  // canal para ENB (motor P)
  ledc_channel_config_t chP = {
    .gpio_num = ENB,
    .speed_mode = pwmSpeed,
    .channel = pwmChannelP,
    .intr_type = LEDC_INTR_DISABLE,
    .timer_sel = pwmTimer,
    .duty = 0,
    .hpoint = 0
  };
  ledc_channel_config(&chP);
}

void setPWML(uint32_t value) {
  if(value > 255) value = 255;
  ledc_set_duty(pwmSpeed, pwmChannelL, value);
  ledc_update_duty(pwmSpeed, pwmChannelL);
}

void setPWMP(uint32_t value) {
  if(value > 255) value = 255;
  ledc_set_duty(pwmSpeed, pwmChannelP, value);
  ledc_update_duty(pwmSpeed, pwmChannelP);
}

void IRAM_ATTR isrAL() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  uint8_t idx = (prevStateL << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&muxL);
    ticksL += delta;
    portEXIT_CRITICAL_ISR(&muxL);
  }
  prevStateL = s;
}

void IRAM_ATTR isrBL() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  uint8_t idx = (prevStateL << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&muxL);
    ticksL += delta;
    portEXIT_CRITICAL_ISR(&muxL);
  }
  prevStateL = s;
}

void IRAM_ATTR isrAP() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAP) << 1) | gpio_get_level((gpio_num_t)encBP);
  uint8_t idx = (prevStateP << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&muxP);
    ticksP += delta;
    portEXIT_CRITICAL_ISR(&muxP);
  }
  prevStateP = s;
}

void IRAM_ATTR isrBP() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAP) << 1) | gpio_get_level((gpio_num_t)encBP);
  uint8_t idx = (prevStateP << 2) | s;
  int8_t delta = transTable[idx];
  if (delta != 0) {
    portENTER_CRITICAL_ISR(&muxP);
    ticksP += delta;
    portEXIT_CRITICAL_ISR(&muxP);
  }
  prevStateP = s;
}

// PID Motor ligero______________________________________________________________
float kpL = 1.75;
float kiL = 0.02;
float kdL = 0.6;

volatile float setPointL;
volatile int lastCmdDirL = 0;

const unsigned long sampleTimeL = 10; // Ejecuta PID cada 10ms
unsigned long lastTimeL = 0;

unsigned long currentTimeL, previousTimeL;
double elapsedTimeL;
double errorL, lastErrorL, cumErrorL, rateErrorL;

// Limites
const float integralMaxL = 200.0;
const int pwmMaxL = 50;
const int pwmMinL = 0;

const float angleTolL = 1.0f;

// PID Motor pesado______________________________________________________________
float kpP = 11.0;
float kiP = 0.1;
float kdP = 0.0;

volatile float setPointP;
volatile int lastCmdDirP = 0;

const unsigned long sampleTimeP = 10; // Ejecuta PID cada 10ms
unsigned long lastTimeP = 0;

unsigned long currentTimeP, previousTimeP;
double elapsedTimeP;
double errorP, lastErrorP, cumErrorP, rateErrorP;

// Limites
const float integralMaxP = 200.0;
const int pwmMaxP = 150;
const int pwmMinP = 0;

const float angleTolP = 1.0f;

void setup() {
  Serial.begin(115200);
  delay(10);

  pinMode(IN1, OUTPUT);
  pinMode(IN2, OUTPUT);
  pinMode(IN3, OUTPUT);
  pinMode(IN4, OUTPUT);
  pinMode(ENA, OUTPUT);
  pinMode(ENB, OUTPUT);
  pinMode(encAL, INPUT_PULLUP);
  pinMode(encBL, INPUT_PULLUP);
  pinMode(encAP, INPUT_PULLUP);
  pinMode(encBP, INPUT_PULLUP);
  
  prevStateL = (gpio_get_level((gpio_num_t)encAL) << 1) | gpio_get_level((gpio_num_t)encBL);
  attachInterrupt(digitalPinToInterrupt(encAL), isrAL, CHANGE);
  attachInterrupt(digitalPinToInterrupt(encBL), isrBL, CHANGE);

  prevStateP = (gpio_get_level((gpio_num_t)encAP) << 1) | gpio_get_level((gpio_num_t)encBP);
  attachInterrupt(digitalPinToInterrupt(encAP), isrAP, CHANGE);
  attachInterrupt(digitalPinToInterrupt(encBP), isrBP, CHANGE);

  setupPWMChannels();
  setPWML(0);
  setPWMP(0);

  digitalWrite(IN1, LOW);
  digitalWrite(IN2, LOW);
  digitalWrite(IN3, LOW);
  digitalWrite(IN4, LOW);

  //setPointL = 45.0;
  //setPointP = 45.0;

  float initialAngleL = getEncDegreesL();
  float initialErrL = wrap180(setPointL - initialAngleL);
  float initialAngleP = getEncDegreesP();
  float initialErrP = wrap180(setPointP - initialAngleP);

  previousTimeL = millis();
  cumErrorL = 0.0;
  lastErrorL = initialErrL;
  previousTimeP = millis();
  cumErrorP = 0.0;
  lastErrorP = initialErrP;

  Serial.print("Controlador PID para motor ligero (ESP32) a ");
  Serial.print(setPointL);
  Serial.println(" grados");
  Serial.print("Controlador PID para motor pesado (ESP32) a ");
  Serial.print(setPointP);
  Serial.println(" grados");
}

unsigned long lastToggleMs = 0;
bool pointSetter = 0;

void loop() {

  if (Serial.available()) {
    char c = Serial.read();
    if (c == 's' || c == 'S') {

      // Apaga motor
      digitalWrite(IN1, LOW);
      digitalWrite(IN2, LOW);
      digitalWrite(IN3, LOW);
      digitalWrite(IN4, LOW);
      setPWML(0);
      setPWMP(0);

      Serial.println(">>> EMERGENCIA ACTIVADA: Motor detenido <<<");

      // Bucle infinito
      while (true) {
        //Serial.println("Sistema detenido por EMERGENCIA.");
        delay(500);
      }
    }
  }

  if (millis() - lastToggleMs >= 5000) {
    pointSetter = !pointSetter;
    lastToggleMs = millis();
  }

  if (pointSetter) {
    setPointL = 140;
    setPointP = 0;
  } else {
    setPointL = 0;
    setPointP = 130;
  }

  unsigned long now = millis();
  if(now - previousTimeL >= sampleTimeL) {

    float inputL = getEncDegreesL();  // Input para el PID
    double dtL = (now-previousTimeL)/1000.0;
    float outputL = computePIDL(inputL, dtL);
    Serial.print("Angulo ligero: ");
    Serial.print(inputL, 2);
    Serial.print(" Output ligero: ");
    Serial.print(outputL, 2);
    // Saturación
    if (outputL > pwmMaxL) outputL = pwmMaxL;
    if (outputL < -pwmMaxL) outputL = -pwmMaxL;

    applyMotorOutputL(outputL);

    previousTimeL = now;

  }
  if(now - previousTimeP >= sampleTimeP) {

    float inputP = getEncDegreesP();  // Input para el PID
    double dtP = (now-previousTimeP)/1000.0;
    float outputP = computePIDP(inputP, dtP);
    Serial.print(" | Angulo pesado: ");
    Serial.print(inputP, 2);
    Serial.print(" Output pesado: ");
    Serial.println(outputP, 2);
    // Saturación
    if (outputP > pwmMaxP) outputP = pwmMaxP;
    if (outputP < -pwmMaxP) outputP = -pwmMaxP;

    applyMotorOutputP(outputP);

    previousTimeP = now;

  }

}

// Función para obtener lectura de encoder en grados (MOTOR LIGERO)_________________________________________
float getEncDegreesL() {
  long ticksActual;
  portENTER_CRITICAL(&muxL);
  ticksActual = ticksL;
  portEXIT_CRITICAL(&muxL);

  long ticksMod = ((ticksActual % PULSOS_POR_REV) + PULSOS_POR_REV) % PULSOS_POR_REV;
  float angulo = (float)ticksMod * GRADOS_POR_PULSO;

  return angulo;
}

// Función para obtener lectura de encoder en grados (MOTOR PESADO)_________________________________________
float getEncDegreesP() {
  long ticksActual;
  portENTER_CRITICAL(&muxP);
  ticksActual = ticksP;
  portEXIT_CRITICAL(&muxP);

  long ticksMod = ((ticksActual % PULSOS_POR_REV) + PULSOS_POR_REV) % PULSOS_POR_REV;
  float angulo = (float)ticksMod * GRADOS_POR_PULSO;

  return angulo;
}

// envuelve ángulo a [-180, +180]
float wrap180(float ang) {
  while (ang > 180.0f) ang -= 360.0f;
  while (ang <= -180.0f) ang += 360.0f;
  return ang;
}

// Función del controlador PID LIGERO_______________________________________________
float computePIDL(float inp, double dt) {
  if (dt <= 0.0) return 0.0;

  float rawErr = setPointL - inp;
  float error = wrap180(rawErr);
  // float error = rawErr;

  // Integración (con anti-windup por saturación)
  cumErrorL += error * dt;
  // Limitar integral para evitar windup
  if (cumErrorL > integralMaxL) cumErrorL = integralMaxL;
  if (cumErrorL < -integralMaxL) cumErrorL = -integralMaxL;

  // Derivada
  double deriv = (error - lastErrorL) / dt;

  // Salida PID en unidades de PWM
  double output = kpL * error + kiL * cumErrorL + kdL * deriv;
  
  lastErrorL = error;

  return (float)output;
}

// Función del controlador PID PESADO_______________________________________________
float computePIDP(float inp, double dt) {
  if (dt <= 0.0) return 0.0;

  float rawErr = setPointP - inp;
  float error = wrap180(rawErr);
  // float error = rawErr;

  // Integración (con anti-windup por saturación)
  cumErrorP += error * dt;
  // Limitar integral para evitar windup
  if (cumErrorP > integralMaxP) cumErrorP = integralMaxP;
  if (cumErrorP < -integralMaxP) cumErrorP = -integralMaxP;

  // Derivada
  double deriv = (error - lastErrorP) / dt;

  // Salida PID en unidades de PWM
  double output = kpP * error + kiP * cumErrorP + kdP * deriv;
  
  lastErrorP = error;

  return (float)output;
}

// Función para aplicar salida al puente H LIGERO_________________________________
void applyMotorOutputL(float out) {

  int pwmVal = (int)abs(out);
  if (pwmVal > pwmMaxL) pwmVal = pwmMaxL;

  if (out > 1.0) {
    digitalWrite(IN1, HIGH);
    digitalWrite(IN2, LOW);
    setPWML(pwmVal);
    lastCmdDirL = +1;
  } else if (out < -1.0) {
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, HIGH);
    setPWML(pwmVal);
    lastCmdDirL = -1;
  } else {
    // stop / coast
    digitalWrite(IN1, LOW);
    digitalWrite(IN2, LOW);
    setPWML(0);
    lastCmdDirL = 0;
    return;
  }

}

// Función para aplicar salida al puente H PESADO_________________________________
void applyMotorOutputP(float out) {

  int pwmVal = (int)abs(out);
  if (pwmVal > pwmMaxP) pwmVal = pwmMaxP;

  if (out > 1.0) {
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, HIGH);
    setPWMP(pwmVal);
    lastCmdDirP = +1;
  } else if (out < -1.0) {
    digitalWrite(IN3, HIGH);
    digitalWrite(IN4, LOW);
    setPWMP(pwmVal);
    lastCmdDirP = -1;
  } else {
    // stop / coast
    digitalWrite(IN3, LOW);
    digitalWrite(IN4, LOW);
    setPWMP(0);
    lastCmdDirP = 0;
    return;
  }

}
