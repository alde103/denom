#include <Arduino.h>

#define PI 3.1415926535897932384626433832795

double time = 0;

void setup() {
 // initialize serial:
  Serial.begin(9600);
  
}

void loop() {
  // Mocking a sensor with the sin() function.
  double Fs = 1000;
  double T = 1 / Fs;
  double sim_sine_sensor = 10*sin(2*PI*50*time*T);

  // Mocking a sensor as a randome noise response.
  double sim_random_noise_sensor = random(-5, 5);
  
  String json = "{\"OPC_UA\":" + String(sim_sine_sensor) +", \"MODBUS_TCP\":" + String(sim_random_noise_sensor) + "}\r\n";

  Serial.println(json);

  delay(Fs);

  time +=1;

}