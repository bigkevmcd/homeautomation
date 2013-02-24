/*
  Read LDR
  
  Reads an LDR and emits a JSON message to the Serial port containing the current value if it differs
  by a certain percent from the previously recorded value.

*/
#include <EEPROM.h>
#define LDR_PORT         0 // Pin Settings
#define NODEID           1 // Should be unique on the network
#define DELAY_PERIOD     5000 // 5 seconds
#define RANGE_VALUE       10   // 10%

int previousValue = 0;   // records the previous value we've seen
long counter = 0;        // long count of packets sent

void setup()
{
  Serial.begin(9600);
}

/*
 * Returns true if n1 is within percentage% of n2
 */
bool isWithinRange(float n1, float n2, float percentage) {
if (n2 == 0.0)
   return false;
else
   return (percentage > abs(abs(n2 - n1)/n2)*100.0);
}


void loop() {
  int data;
  data = getLDRSensorValue(LDR_PORT);
  if (!(isWithinRange(data, previousValue, RANGE_VALUE))) {
    printSensorData(data);
    previousValue = data;
    counter++;
  }
  delay(DELAY_PERIOD);
}

int getLDRSensorValue(int port) {
  return analogRead(port);
}

void printSensorData(int data)
{
  Serial.print("{\"nodeid\":");
  Serial.print(NODEID);
  Serial.print(",\"light\":");
  Serial.print(data);
  Serial.print(",\"counter\":");
  Serial.print(counter);
  Serial.println("}");
}
