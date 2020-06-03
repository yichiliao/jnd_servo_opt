#include <Servo.h>
Servo servo;
const int servo_pin = 11;

// Handling data from processing
char charin;
int valuein, value_sum;
bool received = false;

int servo_pos = 0;       // current motor degree
int servo_target_1 = 0;  // target degree for the first cue
int servo_target_2 = 0;  // target degree for the second cue

void setup() 
{
  // setup servo
  servo.attach(servo_pin);
  servo.write(0);
}

void loop() 
{
  // expecting data sent from processing
  if (Serial.available()) 
  {
    charin = Serial.read();
    delay(10);
    if (charin == 'a') // When the message begin with a, we set the first target degree
    {
      value_sum = 0;
      received = true;
      delay(10);
      while(true)
      {
        charin = Serial.read(); // read it and store it in val
        if (charin != 'e')
        {
          value_sum *= 10;
          valuein = charin - '0';
          value_sum += valuein;
          delay(10);   // Must have this delay to ensure the reading are correct!
        }
        else
        {
          servo_target_1 = value_sum; 
          servo_target_2 = value_sum;
          break;
        }
      }
    }

    else if (charin == 'b') // When the message begin with b, we set the second target degree
    {
      value_sum = 0;
      received = true;
      while(true)
      {
        charin = Serial.read(); // read it and store it in val
        delay(10);
        if (charin != 'e')
        {
          value_sum *= 10;
          valuein = charin - '0';
          value_sum += valuein;
          delay(10);   // Must have this delay to ensure the reading are correct!
        }
        else
        {
          servo_target_2 -= value_sum; 
          if (servo_target_2 < 0)
          {servo_target_2 = 1;}
          else if (servo_target_2 > 180)
          {servo_target_2 = 179;}
          break;
        }
      }
    }
    
    else if (charin == 'c')  // When the message is c, generate the same haptic cue twice
    {hit_same();delay(10);}

    else if (charin == 'd')  // When the message is d, generate different haptic cues
    {hit_diff();delay(10);}
  }
}


// Drive the servo to generate cues
void hit_same()
{
  for (int i = 0; i<2; i+=1)
  {
    for (servo_pos = 0; servo_pos <= servo_target_1; servo_pos += 1) 
    { 
      servo.write(servo_pos);
      delay(5);
    }
    for (servo_pos = servo_target_1; servo_pos >= 0; servo_pos -= 1) 
    {
      servo.write(servo_pos);
      delay(5);
    }
    delay(1000);
  }
}

void hit_diff()
{
  for (servo_pos = 0; servo_pos <= servo_target_1; servo_pos += 1) 
  { 
    servo.write(servo_pos);
    delay(5);
  }
  for (servo_pos = servo_target_1; servo_pos >= 0; servo_pos -= 1) 
  {
    servo.write(servo_pos);
    delay(5);
  }
  delay(1000);
  
  for (servo_pos = 0; servo_pos <= servo_target_2; servo_pos += 1) 
  { 
    servo.write(servo_pos);
    delay(5);
  }
  for (servo_pos = servo_target_2; servo_pos >= 0; servo_pos -= 1) 
  {
    servo.write(servo_pos);
    delay(5);
  }
}
