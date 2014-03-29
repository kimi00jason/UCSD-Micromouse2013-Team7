#include "global.h"
#include "pinMap.h"
#include "config.h"
#include "Wire.h"


void setup()
{
  //LED display
  pinMode(Led1,OUTPUT);
  pinMode(Led2,OUTPUT);
  pinMode(Led3,OUTPUT);
  //motor
  pinMode(motorLeft1, OUTPUT);
  pinMode(motorLeft2, OUTPUT);
  pinMode(motorLeftSTBY, OUTPUT);
  pinMode(motorLeftPWM, PWM);
  pinMode(motorRight1, OUTPUT);
  pinMode(motorRight2, OUTPUT);
  pinMode(motorRightSTBY, OUTPUT);
  pinMode(motorRightPWM, PWM);
  
  //Encoder
  pinMode(encoderLeftCLK, INPUT);
  pinMode(encoderLeftDir, INPUT);
  pinMode(encoderRightCLK, INPUT);
  pinMode(encoderRightDir, INPUT);
  //Board I/O
  pinMode(BOARD_LED_PIN, OUTPUT);
  pinMode(BOARD_BUTTON_PIN, INPUT);
  
  attachInterrupt(encoderLeftCLK, encoderLeft_interrupts, RISING);
  attachInterrupt(encoderRightCLK, encoderRight_interrupts, RISING);
  
  Wire.begin(0,1);
  mode = modeStraight;
}

void loop()
{  
 
  //Go Straight
//  if(mode == modeDecide)
//  {
//    goStraight(10000);
//  }
  
  if(mode == modeStraight)
  {
    speedLeft = 10000;
    speedRight = 10000;
    runAllSensor(); 
    PID();
    SerialUSB.println(distFront);
    if (distFront < 5) mode = modeStop;
  }
  
  if(mode == modeStop)
  {
    motorLeft_go(0);
    motorRight_go(0);
  }
    



}