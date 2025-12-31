#include <Arduino.h>
#include <driver/ledc.h>

#define LED 2

//  PINES 
const int IN1 = 17; const int IN2 = 16;
const int IN3 = 18; const int IN4 = 19;
const int ENA = 4;  const int ENB = 5; 
const int encAL = 33; const int encBL = 32;
const int encAP = 26; const int encBP = 25;

//  VARIABLES ENCODER 
volatile long ticksL = 0;
volatile long ticksP = 0;
portMUX_TYPE muxL = portMUX_INITIALIZER_UNLOCKED;
portMUX_TYPE muxP = portMUX_INITIALIZER_UNLOCKED;

//  AJUSTES DE FÍSICA 
const int PPR_ENCODER = 12;
const int GEAR_RATIO = 64;
const int PULSOS_POR_REV = PPR_ENCODER * 4 * GEAR_RATIO;
const float GRADOS_POR_PULSO = 360.0f / PULSOS_POR_REV;

const int8_t transTable[16] = {0,-1,1,0,1,0,0,-1,-1,0,0,1,0,1,-1,0};
volatile uint8_t prevStateL = 0;
volatile uint8_t prevStateP = 0;

//  PID 
float kpL = 20.0, kiL = 0.02, kdL = 0.8;
volatile float setPointL = 0.0f;
double cumErrorL = 0, lastErrorL = 0;

float kpP = 55.0, kiP = 0.1, kdP = 0.2;
volatile float setPointP = 0.0f;
double cumErrorP = 0, lastErrorP = 0;

//  PWM 
const int pwmMaxL = 80;
const int pwmMaxP = 212; 
const float scaleL = 3.0f;
const float scaleP = 1.5f;

//  CONFIG PWM 
const ledc_mode_t pwmSpeed = LEDC_LOW_SPEED_MODE;
const ledc_timer_t pwmTimer = LEDC_TIMER_0;
const int pwmFreq = 20000;       
const ledc_channel_t pwmChannelL = LEDC_CHANNEL_0;
const ledc_channel_t pwmChannelP = LEDC_CHANNEL_1;

//  PROTOTIPOS 
void setPWML(int v) { ledc_set_duty(pwmSpeed, pwmChannelL, constrain(v,0,255)); ledc_update_duty(pwmSpeed, pwmChannelL); }
void setPWMP(int v) { ledc_set_duty(pwmSpeed, pwmChannelP, constrain(v,0,255)); ledc_update_duty(pwmSpeed, pwmChannelP); }
float getAngL() { portENTER_CRITICAL(&muxL); long t=ticksL; portEXIT_CRITICAL(&muxL); return t * GRADOS_POR_PULSO; }
float getAngP() { portENTER_CRITICAL(&muxP); long t=ticksP; portEXIT_CRITICAL(&muxP); return t * GRADOS_POR_PULSO; }

void IRAM_ATTR isrAL() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAL)<<1)|gpio_get_level((gpio_num_t)encBL);
  int8_t d = transTable[(prevStateL<<2)|s];
  if(d!=0){ portENTER_CRITICAL_ISR(&muxL); ticksL+=d; portEXIT_CRITICAL_ISR(&muxL); }
  prevStateL=s;
}
void IRAM_ATTR isrBL() { isrAL(); }
void IRAM_ATTR isrAP() {
  uint8_t s = (gpio_get_level((gpio_num_t)encAP)<<1)|gpio_get_level((gpio_num_t)encBP);
  int8_t d = transTable[(prevStateP<<2)|s];
  if(d!=0){ portENTER_CRITICAL_ISR(&muxP); ticksP+=d; portEXIT_CRITICAL_ISR(&muxP); }
  prevStateP=s;
}
void IRAM_ATTR isrBP() { isrAP(); }

//  MOTORES 
void runL(float out) {
  int pwm = constrain((int)round(fabs(out * scaleL)), 0, pwmMaxL);
  if (out > 1.0) { digitalWrite(IN1, HIGH); digitalWrite(IN2, LOW); setPWML(pwm); }
  else if (out < -1.0) { digitalWrite(IN1, LOW); digitalWrite(IN2, HIGH); setPWML(pwm); }
  else { digitalWrite(IN1, LOW); digitalWrite(IN2, LOW); setPWML(0); }
}
void runP(float out) {
  int pwm = constrain((int)round(fabs(out * scaleP)), 0, pwmMaxP);
  if (out > 1.0) { digitalWrite(IN3, LOW); digitalWrite(IN4, HIGH); setPWMP(pwm); }
  else if (out < -1.0) { digitalWrite(IN3, HIGH); digitalWrite(IN4, LOW); setPWMP(pwm); }
  else { digitalWrite(IN3, LOW); digitalWrite(IN4, LOW); setPWMP(0); }
}

//  PROCESAR COMANDOS 
void process(char* str) {
  while(*str==' '||*str=='\r'||*str=='\n') str++;
  if(strlen(str)==0) return;

  if (strlen(str) == 1) {
    if (str[0] == '1') {
      digitalWrite(LED, HIGH);
      Serial.println("LED ON");
      return;
    }
    if (str[0] == '0') {
      digitalWrite(LED, LOW);
      Serial.println("LED OFF");
      return;
    }
    if (str[0] == 's' || str[0] == 'S') {
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

  // 1. PRESET (P): Forzar posición
  if(str[0]=='P' || str[0]=='p') {
    float a, b;
    if(sscanf(str+2, "%f,%f", &a, &b)==2) {
      setPointL = a; setPointP = b;
      // Calculo ticks inversos
      long newTicksL = (long)(a / GRADOS_POR_PULSO);
      long newTicksP = (long)(b / GRADOS_POR_PULSO);
      
      portENTER_CRITICAL(&muxL); ticksL = newTicksL; portEXIT_CRITICAL(&muxL);
      portENTER_CRITICAL(&muxP); ticksP = newTicksP; portEXIT_CRITICAL(&muxP);
      
      cumErrorL=0; lastErrorL=0; cumErrorP=0; lastErrorP=0;
      Serial.println("ACK_PRESET");
    }
    return;
  }
  
  // 2. TARGET (T): Moverse
  float ta, tb;
  if(sscanf(str, "T,%f,%f", &ta, &tb)==2) {
    setPointL = ta; setPointP = tb;
    Serial.print("D,"); Serial.print(getAngL()); Serial.print(","); Serial.println(getAngP());
  }
}

void setup() {
  Serial.begin(115200);
  pinMode(LED,OUTPUT);
  pinMode(IN1,OUTPUT); pinMode(IN2,OUTPUT); pinMode(IN3,OUTPUT); pinMode(IN4,OUTPUT);
  pinMode(ENA,OUTPUT); pinMode(ENB,OUTPUT);
  pinMode(encAL,INPUT_PULLUP); pinMode(encBL,INPUT_PULLUP);
  pinMode(encAP,INPUT_PULLUP); pinMode(encBP,INPUT_PULLUP);
  
  prevStateL = (gpio_get_level((gpio_num_t)encAL)<<1)|gpio_get_level((gpio_num_t)encBL);
  attachInterrupt(digitalPinToInterrupt(encAL), isrAL, CHANGE); attachInterrupt(digitalPinToInterrupt(encBL), isrBL, CHANGE);
  prevStateP = (gpio_get_level((gpio_num_t)encAP)<<1)|gpio_get_level((gpio_num_t)encBP);
  attachInterrupt(digitalPinToInterrupt(encAP), isrAP, CHANGE); attachInterrupt(digitalPinToInterrupt(encBP), isrBP, CHANGE);

  ledc_timer_config_t tcfg = {.speed_mode=pwmSpeed, .duty_resolution=LEDC_TIMER_8_BIT, .timer_num=pwmTimer, .freq_hz=pwmFreq, .clk_cfg=LEDC_AUTO_CLK};
  ledc_timer_config(&tcfg);
  ledc_channel_config_t cL = {.gpio_num=ENA, .speed_mode=pwmSpeed, .channel=pwmChannelL, .timer_sel=pwmTimer, .duty=0}; ledc_channel_config(&cL);
  ledc_channel_config_t cP = {.gpio_num=ENB, .speed_mode=pwmSpeed, .channel=pwmChannelP, .timer_sel=pwmTimer, .duty=0}; ledc_channel_config(&cP);
}

unsigned long lastTime = 0;
void loop() {
  static char buf[64]; static int pos=0;
  while(Serial.available()){
    char c=Serial.read();
    if(c=='\n'){
      buf[pos]=0;
      process(buf);
      pos=0;
    } else if(pos<63) buf[pos++]=c;
  }

  unsigned long now = millis();
  if(now - lastTime >= 10) { // 100Hz PID
    float dt = (now - lastTime)/1000.0;
    
    // PID L
    float errL = setPointL - getAngL();
    cumErrorL += errL*dt;
    if(cumErrorL>200) cumErrorL=200; if(cumErrorL<-200) cumErrorL=-200;
    float outL = kpL*errL + kiL*cumErrorL + kdL*((errL-lastErrorL)/dt);
    lastErrorL = errL;
    runL(outL);

    // PID P
    float errP = setPointP - getAngP();
    cumErrorP += errP*dt;
    if(cumErrorP>200) cumErrorP=200; if(cumErrorP<-200) cumErrorP=-200;
    float outP = kpP*errP + kiP*cumErrorP + kdP*((errP-lastErrorP)/dt);
    lastErrorP = errP;
    runP(outP);

    lastTime = now;
  }
}