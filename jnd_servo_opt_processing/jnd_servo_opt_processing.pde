import processing.net.*; 
import processing.serial.*;
import java.util.*; 
Serial arduino;  // serial connection
Client myClient; // server connection

// Parameters for drawing basic components
int new_button_x = 200;
int new_button_y = 200;
int new_button_width = 180;
int new_button_height = 100;
int re_button_x = new_button_x+ 220;
int re_button_y = new_button_y;
int re_button_width = new_button_width;
int re_button_height = new_button_height;

int res_0_x = 160;
int res_1_x = 360;
int res_2_x = 560;
int res_y = 400;
int res_width = 80;

// hit_array decides to render the same rotation of different rotations for this trial
int[] hit_array = {1,1,1,1,2,2,2,2};  // 1 for generating the same feedback, 2 for different cues
// count the trials, and there are 8 trials per iteration
int trial_total = 8;
int trial_count = -1;

// For reading the data sent from python server
// After receiving the data, we set the motor degress and send them to arduino
int dataIn = 0;
int set_motor_1 = 83;
int set_motor_2 = 15;

// For gathering user's response and send the correctness to python
int[] user_response = {0,0,0,0,0,0,0,0};    // which records user's feedback
int[] send_to_python = {0,0,0,0,0,0,0,0};   // this records correctness of each trial
boolean if_new = false;     // The flag turns to true as the user presses "New trial", expect to receive answer
boolean if_answered = true; // The flag turns to true if the user has given the answer
boolean calculated = true;  // If the iteration is done (after 8 trials) and the program will calculate the correctness

// In case there's no python connection, still send the initial parameters to arduino
boolean sent = false;

// Parameters for dealing with python
boolean ready_to_send_py = false;
boolean if_connect_python = true;


void setup() 
{
  size(800, 600);
  // Just print out all the serial
  println ("<START>");
  println (Serial.list());
  println ("<END>");
  
  // Setting the arduino communication via serial port
  arduino = new Serial (this, "/dev/cu.usbmodem146201", 9600);
  if (if_connect_python)
  {myClient = new Client(this, "127.0.0.1", 50007);} // Starting connection with python
  
  hit_array = RandomizeArray(hit_array);
}

void draw() 
{
  // draw basic components
  background(220);
  fill(255,255,255);
  rect(new_button_x, new_button_y, new_button_width, new_button_height);
  rect(re_button_x, re_button_y, re_button_width, re_button_height);
  
  rect(res_0_x, res_y, res_width, res_width);
  rect(res_1_x, res_y, res_width, res_width);
  rect(res_2_x, res_y, res_width, res_width);
  fill(0,0,0);
  textSize(32);
  text("New trial", new_button_x+20, new_button_y+60);
  text("Repeat", re_button_x+32, re_button_y+60);
  text("0", res_0_x+30, res_y+52);
  text("1", res_1_x+30, res_y+52);
  text("2", res_2_x+30, res_y+52);
  
  textSize(25);
  if(if_answered)
  {text("Press New trial", 300, 150);}
  else
  {text("Repeat or answer", 300, 150);}
  
  
  // Expecting to receive parameters sent by python server
  if (if_connect_python)  // Only when online mode is on
  {
    if (myClient.available() > 0) 
    {
      // read in the gain function
      dataIn = myClient.read();
      set_motor_1 = dataIn;
      print("set_motor_1: ");
      println(set_motor_1);
      // read in the hit_threshold
      dataIn = myClient.read();
      set_motor_2 = dataIn;
      print("set_motor_2: ");
      println(set_motor_2);
      
      send_to_arduino(set_motor_1,1);
      delay(1000);
      send_to_arduino(set_motor_2,2);
      delay(100); 
      
      // reset everything
      for (int i =0; i< trial_total; i+=1)
      {user_response[i] = 0;}
      trial_count = -1;
      if_answered = true;
      hit_array = RandomizeArray(hit_array);
      println ("array shuffled, everything has been reset");
    }
  }
  if (!sent)
  {
    send_to_arduino(set_motor_1,1);
    delay(1000);
    send_to_arduino(set_motor_2,2);
    println("sent");
    sent = true;
  }
  
  // Handling mouse presses
  if(mousePressed)
  {
    // move on to a new trial
    if(mouseX>new_button_x && mouseX <new_button_x + new_button_width 
    && mouseY>new_button_y && mouseY <new_button_y+new_button_height && if_answered)
    {
      trial_count = (trial_count+1)%trial_total;
      println(trial_count);
      if (hit_array[trial_count] ==1)
      {hit_same();println("same");}
      else
      {hit_diff();println("diff");}
      delay(150);
      if_answered = false;
      calculated = false;
      if_new = true;
    }
    
    // repeat the feedback of current trial
    if(mouseX>re_button_x && mouseX <re_button_x + re_button_width 
    && mouseY>re_button_y && mouseY <re_button_y + re_button_height && trial_count>=0)
    {
      println(trial_count);
      if (hit_array[trial_count] ==1)
      {hit_same();println("same");}
      else
      {hit_diff();println("diff");}
      delay(150);
    }
    
    // receiving answers
    // 0 -> cannot feel 1 or 2 cue(s), so this iteration should be terminated
    if(mouseX>res_0_x && mouseX <res_0_x + res_width 
    && mouseY>res_y && mouseY <res_y + res_width && if_new && trial_count>=0)
    {
      println("give up this iteration");
      for (int i =0; i< trial_total; i+=1)
      {send_to_python[i] = 0;} // give a very bad result (recognition rate = 0)
      if_answered = true;
      delay(150);
      ready_to_send_py = true;
    }
    
    // handling normal responses 
    // 1 -> only one parameter
    if(mouseX>res_1_x && mouseX <res_1_x + res_width 
    && mouseY>res_y && mouseY <res_y + res_width && if_new && trial_count>=0)
    {
      user_response[trial_count] = 1;
      if_answered = true;
      delay(150);
    }
    // 2 -> there are two parameters rendered
    if(mouseX>res_2_x && mouseX <res_2_x + res_width 
    && mouseY>res_y && mouseY <res_y + res_width && if_new && trial_count>=0)
    {
      user_response[trial_count] = 2;
      if_answered = true;
      delay(150);
    }
  }
  
  // Calculate the correctness
  if ((trial_count == trial_total-1) && if_answered && !calculated)
  {
    for (int i =0; i< trial_total; i+=1)
    {send_to_python[i] = xnor(hit_array[i], user_response[i]);}
    println(send_to_python);
    calculated = true;
    ready_to_send_py = true;
  }
  
  // Sending the correctness to python server
  if (ready_to_send_py && if_connect_python)
  {
    for (int count = 0; count < trial_total; count += 1)
    {
      println (str(send_to_python[count]));
      myClient.write(str(send_to_python[count]));
      delay(20);
    }
    ready_to_send_py = false;
  }
}

// Just for testing the haptic cues. Press key up: the same cue, press down: different cues
void keyPressed() {
  if (key == CODED) 
  {
    if (keyCode == UP) 
    {
      hit_same();
    } 
    else if (keyCode == DOWN) {
      hit_diff();
    } 
  } 
}

// Sending the parameters to arduino
void send_to_arduino (int num, int servo_target)
{
  if (servo_target == 1)
  {
    println("set motor 1");
    arduino.write('a');
  }
  else
  {
    println("set motor 2");
    arduino.write('b');
  }
  String str_num = str(num);
  for (int count = 0; count < str_num.length(); count+=1)
  {arduino.write(str_num.charAt(count));}
  arduino.write('e');
}

// Asking arduino to generate cues
void hit_same()
{
  arduino.write('c');
}
void hit_diff()
{
  arduino.write('d');
}

int[] RandomizeArray(int[] array)
{
  Random rgen = new Random();  // Random number generator      
 
  for (int i=0; i<array.length; i++) 
  {
    int randomPosition = rgen.nextInt(array.length);
    int temp = array[i];
    array[i] = array[randomPosition];
    array[randomPosition] = temp;
  }
  return array;
}

int xnor(int a, int b) 
{
  if (a == b)
  {return 1;}
  else
  {return 0;}
}
