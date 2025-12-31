#include <Arduino.h>

// CONFIGURACIÓN MECÁNICA / ENCODER
// Dimensiones del robot (en mm)
const float L1 = 180.0; // longitud del primer brazo
const float L2 = 220.0; // longitud del segundo brazo

// Parámetros del encoder / motor
const float ENCODER_PPR = 12; // pulses per revolution del encoder (si es CPR o PPR, usar apropiado)
const float GEAR_RATIO = 64;     // relación de reducción: 1.0 si directo, si 100:1 -> 100.0

// Conversión: radianes a conteo de encoder
const float COUNTS_PER_RAD = (ENCODER_PPR * GEAR_RATIO) / (2.0 * PI);

// PINS (ajustar según cableado)
// Motor 1
const int M1_PWM = 9;   // PWM pin
const int M1_DIR = 8;   // Dir pin (HIGH/LOW para sentido)
const int ENC1_A = 2;   // Encoder A -> usar attachInterrupt(0)
const int ENC1_B = 4;   // Encoder B -> leída en ISR

// Motor 2
const int M2_PWM = 10;  // PWM pin
const int M2_DIR = 7;   // Dir pin
const int ENC2_A = 3;   // Encoder A -> attachInterrupt(1)
const int ENC2_B = 5;   // Encoder B

// CONTROL / PID
volatile long encCount1 = 0;
volatile long encCount2 = 0;

// PID parameters (ajustar)
float Kp1 = 1.2, Ki1 = 0.01, Kd1 = 0.02;
float Kp2 = 1.0, Ki2 = 0.01, Kd2 = 0.02;

// Estados PID
float err1_prev = 0, integ1 = 0;
float err2_prev = 0, integ2 = 0;

// Límite PWM
const int PWM_MAX = 255;
const int PWM_MIN = -255;

// Trayectoria (trebol)
float a_par = 150.0; // unidades en las mismas que L1,L2 (ej mm)
float b_par = 30.0;
int n_par = 4;      // número de lóbulos del trébol
float f_par = 1.2;
float gamma_par = 0.0; // en radianes

// Velocidad de barrido (paso angular por iteración)
const float dtheta = 0.01; // rad
const unsigned long loopDelayMs = 20; // control loop timing en ms (ajustar)

// Variables internas
float theta_traj = 0.0; // parámetro de trayectoria
long targetCount1 = 0, targetCount2 = 0; // objetivos en counts

// PROTOTIPOS
void motorSetPWM(int pwmPin, int dirPin, int pwmValue);
void setMotorOutput1(int pwmVal);
void setMotorOutput2(int pwmVal);
void computeIK(float x, float y, float &q1, float &q2);
void goToJointAngles(float q1, float q2); // q en rad
void updateControlLoop();
void ISR_enc1();
void ISR_enc2();

// SETUP
void setup() {
  Serial.begin(115200);
  // Pines motores
  pinMode(M1_PWM, OUTPUT);
  pinMode(M1_DIR, OUTPUT);
  pinMode(M2_PWM, OUTPUT);
  pinMode(M2_DIR, OUTPUT);

  // Pins encoder
  pinMode(ENC1_A, INPUT_PULLUP);
  pinMode(ENC1_B, INPUT_PULLUP);
  pinMode(ENC2_A, INPUT_PULLUP);
  pinMode(ENC2_B, INPUT_PULLUP);

  // Attach interrupts: enc A rising/falling -> evaluar B
  attachInterrupt(digitalPinToInterrupt(ENC1_A), ISR_enc1, CHANGE);
  attachInterrupt(digitalPinToInterrupt(ENC2_A), ISR_enc2, CHANGE);

  // Inicializar salidas a 0
  analogWrite(M1_PWM, 0);
  analogWrite(M2_PWM, 0);
  digitalWrite(M1_DIR, LOW);
  digitalWrite(M2_DIR, LOW);

  delay(200);
  Serial.println("Trebol Merequetengue - inicio");
}

// LOOP principal
void loop() {
  // 1) Generar punto de trayectoria (x,y)
  float r = a_par + b_par * cos(n_par * theta_traj);
  float x = f_par * r * cos(theta_traj + gamma_par);
  float y = f_par * r * sin(theta_traj + gamma_par);

  // 2) Cinemática inversa -> obtener q1,q2 (en rad)
  float q1_target, q2_target;
  computeIK(x, y, q1_target, q2_target);

  // 3) Convertir a counts objetivo y actualizar control
  goToJointAngles(q1_target, q2_target);

  // 4) Ejecutar control PID para mover motores (en updateControlLoop se usan encCount*)
  updateControlLoop();

  // 5) Avanzar parámetro de trayectoria
  theta_traj += dtheta;
  if (theta_traj > TWO_PI) theta_traj -= TWO_PI;

  delay(loopDelayMs); // ritmo de actualización
}

// Cinemática inversa 2R (codo abajo)
void computeIK(float x, float y, float &q1, float &q2) {
  // Asume x,y en mismas unidades que L1,L2
  float D = (x*x + y*y - L1*L1 - L2*L2) / (2.0 * L1 * L2);

  // Protección numérica
  if (D > 1.0) D = 1.0;
  if (D < -1.0) D = -1.0;

  // q2 (ángulo entre L1 y L2). Dos soluciones; elegimos "codo abajo" => -acos(D)
  q2 = atan2(-sqrt(max(0.0, 1.0 - D*D)), D); // o +sqrt para codo-up

  // q1
  float phi = atan2(y, x);
  float psi = atan2(L2 * sin(q2), L1 + L2 * cos(q2));
  q1 = phi - psi;
}

// Convertir ángulo (rad) a encoder counts
long angleRadToCounts(float angleRad) {
  return lround(angleRad * COUNTS_PER_RAD);
}

// Establecer objetivos en counts
void goToJointAngles(float q1, float q2) {
  targetCount1 = angleRadToCounts(q1);
  targetCount2 = angleRadToCounts(q2);
}

// ISR encoders (flanco en A, leo B para sentido)
void ISR_enc1() {
  bool A = digitalRead(ENC1_A);
  bool B = digitalRead(ENC1_B);
  // Si A == B -> dirección - o + según encoder (prueba en tu hardware)
  if (A == B) encCount1++;
  else encCount1--;
}

void ISR_enc2() {
  bool A = digitalRead(ENC2_A);
  bool B = digitalRead(ENC2_B);
  if (A == B) encCount2++;
  else encCount2--;
}

// Control PID y salida motores
unsigned long lastTimePID = 0;
void updateControlLoop() {
  unsigned long now = millis();
  float dt = (now - lastTimePID) / 1000.0;
  if (dt <= 0) dt = 0.001;
  lastTimePID = now;

  // Leer contadores (usar copia atómica)
  long c1, c2;
  noInterrupts();
  c1 = encCount1;
  c2 = encCount2;
  interrupts();

  // Error en counts
  float err1 = (float)(targetCount1 - c1);
  float err2 = (float)(targetCount2 - c2);

  // PID motor1
  integ1 += err1 * dt;
  float deriv1 = (err1 - err1_prev) / dt;
  float out1 = Kp1 * err1 + Ki1 * integ1 + Kd1 * deriv1;
  err1_prev = err1;

  // PID motor2
  integ2 += err2 * dt;
  float deriv2 = (err2 - err2_prev) / dt;
  float out2 = Kp2 * err2 + Ki2 * integ2 + Kd2 * deriv2;
  err2_prev = err2;

  // Mapear a PWM (limitar)
  if (out1 > PWM_MAX) out1 = PWM_MAX;
  if (out1 < PWM_MIN) out1 = PWM_MIN;
  if (out2 > PWM_MAX) out2 = PWM_MAX;
  if (out2 < PWM_MIN) out2 = PWM_MIN;

  setMotorOutput1((int)out1);
  setMotorOutput2((int)out2);

  // Telemetría opcional
  static unsigned long lastPrint = 0;
  if (millis() - lastPrint > 200) {
    Serial.print("T1_counts:"); Serial.print(targetCount1);
    Serial.print(" enc1:"); Serial.print(c1);
    Serial.print(" T2_counts:"); Serial.print(targetCount2);
    Serial.print(" enc2:"); Serial.print(c2);
    Serial.print(" out1:"); Serial.print((int)out1);
    Serial.print(" out2:"); Serial.println((int)out2);
    lastPrint = millis();
  }
}

// Helpers: set motor PWM and dir
void motorSetPWM(int pwmPin, int dirPin, int pwmValue) {
  if (pwmValue >= 0) {
    digitalWrite(dirPin, HIGH); // ajustar según driver/hardware
    int v = constrain(pwmValue, 0, 255);
    analogWrite(pwmPin, v);
  } else {
    digitalWrite(dirPin, LOW);
    int v = constrain(-pwmValue, 0, 255);
    analogWrite(pwmPin, v);
  }
}

void setMotorOutput1(int pwmVal) {
  motorSetPWM(M1_PWM, M1_DIR, pwmVal);
}

void setMotorOutput2(int pwmVal) {
  motorSetPWM(M2_PWM, M2_DIR, pwmVal);
}
