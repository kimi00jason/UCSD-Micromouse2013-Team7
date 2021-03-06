#include "global.h"
#include "pinMap.h"
#include "config.h"
#include "Wire.h"
#include <stdio.h>


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
  
  motorLeft_go(0);
  motorRight_go(0);
  
//  Wire.begin(0,1);
//  delay(1000);
//  set_compass();
  
  setup_maze(16);
  reset_position();
  priorityRight = true;
  
  PIDmode = modeStop;
  modeFollow = followEncoder;
}

void loop()
{
  
  if(systemMode != board_switch()) delay(5000);
  
  systemMode = board_switch();
  board_display();
  
  switch(systemMode)
  {
    case 3:
    { //Not currently used
      motorFloat();
      delay(500);
      runAllSensor();
      sensor_read();
      sensor_calibration();
//      SerialUSB.print(wheelCountLeft);
//      SerialUSB.print("\t");
//      SerialUSB.println(wheelCountRight);
      break;
    }
    case 2:
    {
      motorFloat();
      restore_maze();
      break;
    }
    case 1:
    {
      motorFloat();
      PIDmode = modeStop;
      reset_position();
      break;
    }
  
    case 0:  //main searching mode input by user
    {
      runAllSensor();
      
      if(PIDmode == modeStraight)
      {
        //PID_follower();
        PID();
//        if(((wheelCountRight + wheelCountLeft)/2) >= 435)
//          quick_solve();
        if(distFront < 100) PIDmode = modeFrontFix;
      }
      
      if(PIDmode == modeStraightOne)
      {  //Goes Straight One Cell, Will Activate First Everytime
        PIDmode = modeStraight;
        PID_follower();
        PID();
        PIDmode = modeStraightOne;
        if(wheelCountRight >= 450 && wheelCountLeft >= 450)
        {
          if(distFront < 100)
            PIDmode = modeFrontFix;
          else
            PIDmode = modeStop;
        }
        if(distFront < 120) PIDmode = modeFrontFix;
      }

       ///////////////////TURNING///////////////////////////////
      if(PIDmode == modeTurnRight)
      {
        motorLeft_go (20000);
        motorRight_go (-20000);
        if (wheelCountLeft >= 168)
        {
          motorLeft_go(0);
        }
        if(wheelCountRight <= -168)
        {
          motorRight_go(0);
        }
        if(wheelCountRight <= -168 && wheelCountLeft >= 168)
        {
          motorRight_go(0);
          motorLeft_go(0);
          countsNeededLeft = 168;
          countsNeededRight = -168;
          PIDmode = modeCountFix;
        }
       }
      
      if(PIDmode == modeTurnLeft)
      {
        motorRight_go (20000);
        motorLeft_go (-20000);
        if (wheelCountRight >= 160)
        {
          motorRight_go(0);
        }
        if(wheelCountLeft <= -160)
        {
          motorLeft_go(0);
        }
        if(wheelCountRight >= 160 && wheelCountLeft <= -160)
        {
          motorRight_go(0);
          motorLeft_go(0);
          countsNeededLeft = -160;
          countsNeededRight = 160;
          PIDmode = modeCountFix;
        }
      }
      
      if(PIDmode == modeTurnBack)
      {
        if(distLeft < 40)
        {
          turnAgain = modeTurnLeft;
          PIDmode = modeTurnLeft;
        }
        else
        {
          turnAgain = modeTurnRight;
          PIDmode = modeTurnRight;
        }
      }
      
      if(PIDmode == modeCountFix)
      {
        runAllSensor();
        PID();
        if(wheelCountRight == countsNeededRight && wheelCountLeft == countsNeededLeft)
        {
          motorLeft_go(0);
          motorRight_go(0);
          //delay(100);
          if(wheelCountRight == countsNeededRight && wheelCountLeft == countsNeededLeft)
          {
            if(distFront < 80)
              PIDmode = modeFrontFix;
            else
            {
              PIDmode = modeStop;
              if(turnAgain)
              {
                motorLeft_go(0);
                motorRight_go(0);
                //delay(100);
                wheelCountLeft = 0;
                wheelCountRight = 0;
                errorStopRightTotal = 0;
                errorStopLeftTotal = 0;
                if(turnAgain == modeTurnRight)
                  PIDmode = modeTurnRight;
                else if(turnAgain == modeTurnLeft)
                  PIDmode = modeTurnLeft;
                turnAgain = false;
              }
            }
          }
        }
      }
      
      if(PIDmode == modeFrontFix)
      {
        runAllSensor();
        if(abs(errorFront) >= 1)
          modeFix = fixFront;
        else if(abs(errorDiagonal) >= 1)
          modeFix = fixDiagonals;
        PID();
        if (abs(errorFront) <= 1 && abs(errorDiagonal) <= 1)
        {
          modeFix = fixFront; //Always Starts with Front Fix Next Time
          PIDmode = modeStop;
          if(turnAgain)
          {
            motorLeft_go(0);
            motorRight_go(0);
            //delay(100);
            wheelCountLeft = 0;
            wheelCountRight = 0;
            errorStopRightTotal = 0;
            errorStopLeftTotal = 0;
            if(turnAgain == modeTurnRight)
              PIDmode = modeTurnRight;
            else if(turnAgain == modeTurnLeft)
              PIDmode = modeTurnLeft;
            turnAgain = false;
          }
        }
      }
        
      if(PIDmode == modeStop)
      {
        motorLeft_go(0);
        motorRight_go(0);
        //delay(50);
        wheelCountLeft = 0;
        wheelCountRight = 0;
        errorCountTotal = 0;
        errorStopRightTotal = 0;
        errorStopLeftTotal = 0;
        countOffset = 0;
        
        if(modeSave)
        { //For Reverting Back to Original Turn Needed
          PIDmode = modeSave;
          modeSave = false;
          break;
        }
        
        if(PIDmode == modeStop) solve_maze();
        
        if(PIDmode == modeTurnRight)
        { //For Fixing Position If Offsetted
          if((distLeft < 130) && (distLeft > 35))
          {
            modeSave = PIDmode;
            PIDmode = modeTurnLeft;
            turnAgain = modeTurnRight;
          }
        }
        if(PIDmode == modeTurnLeft)
        { //For Fixing Position If Offsetted
          if((distRight < 80) && (distRight > 25))
          {
            modeSave = PIDmode;
            PIDmode = modeTurnRight;
            turnAgain = modeTurnLeft;
          }
        }
        //If At Goal, will Stop Indefinitely Until Switch Case
        //PIDmode = modeTurnBack ;
      }
      break;
    }
  }//end switch
}//end loop
