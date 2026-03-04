 #include <ArduinoBLE.h>
 
 static const char* SERVICE_UUID   = "19B10000-E8F2-537E-4F6C-D104768A1214";
 static const char* CMD_UUID       = "19B10001-E8F2-537E-4F6C-D104768A1214";
 static const char* TELEMETRY_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";
 
 BLEService robotService(SERVICE_UUID);
 BLECharacteristic commandChar(CMD_UUID, BLEWrite | BLEWriteWithoutResponse, 2);
 BLECharacteristic telemetryChar(TELEMETRY_UUID, BLENotify, 6);
 
 const int M1A = 11;  // Right motor forward
 const int M1B = 10;  // Right motor reverse
 const int M2A = 9;   // Left motor forward
 const int M2B = 8;   // Left motor reverse
 
 const unsigned long FAILSAFE_MS = 400;
 unsigned long lastCmdTime = 0;
 unsigned long lastTelemetryMs = 0;
 
 const float DEADZONE = 0.10f;
 const int MAX_SPEED = 220;
 
 void setup() {
   Serial.begin(115200);
 
   pinMode(M1A, OUTPUT);
   pinMode(M1B, OUTPUT);
   pinMode(M2A, OUTPUT);
   pinMode(M2B, OUTPUT);
   stopMotors();
 
   if (!BLE.begin()) {
     Serial.println("BLE init failed.");
     while (true) {}
   }
  delay(300);
 
   BLE.setLocalName("Robot-Control-R4");
   BLE.setAdvertisedService(robotService);
 
   robotService.addCharacteristic(commandChar);
   robotService.addCharacteristic(telemetryChar);
   BLE.addService(robotService);
 
   uint8_t zeroCmd[2] = {0, 0};
   commandChar.writeValue(zeroCmd, 2);
 
   uint8_t zeroTelemetry[6] = {0, 0, 0, 0, 0, 0};
   telemetryChar.writeValue(zeroTelemetry, 6);
 
   BLE.advertise();
  delay(300);
   Serial.println("BLE Robot Ready");
 }
 
 void loop() {
   BLEDevice central = BLE.central();
 
   if (central) {
     Serial.print("Connected to: ");
     Serial.println(central.address());
 
     while (central.connected()) {
       if (commandChar.written()) {
         uint8_t buffer[2];
         commandChar.readValue(buffer, 2);
         int8_t x = (int8_t)buffer[0];
         int8_t y = (int8_t)buffer[1];
 
         handleJoystick(x, y);
         lastCmdTime = millis();
       }
 
       if (millis() - lastCmdTime > FAILSAFE_MS) {
         stopMotors();
       }
 
       if (millis() - lastTelemetryMs >= 500) {
         lastTelemetryMs = millis();
         sendTelemetry();
       }
     }
 
     Serial.println("Disconnected");
     stopMotors();
   }
 }
 
void handleJoystick(int8_t x, int8_t y) {
  float fx = x / 127.0f;
   float fy = y / 127.0f;
 
   if (abs(fx) < DEADZONE) fx = 0;
   if (abs(fy) < DEADZONE) fy = 0;
 
   float left  = constrain(fy + fx, -1.0f, 1.0f);
   float right = constrain(fy - fx, -1.0f, 1.0f);
 
   setMotor(left * MAX_SPEED, right * MAX_SPEED);
 }
 
 void setMotor(int left, int right) {
   left  = constrain(left, -255, 255);
   right = constrain(right, -255, 255);
 
   // LEFT MOTOR (invert to fix reversed direction)
   left = -left;
 
   // RIGHT MOTOR
   if (right > 0) {
     analogWrite(M1A, right);
     analogWrite(M1B, 0);
   } else if (right < 0) {
     analogWrite(M1A, 0);
     analogWrite(M1B, -right);
   } else {
     stopRight();
   }
 
   // LEFT MOTOR
   if (left > 0) {
     analogWrite(M2A, left);
     analogWrite(M2B, 0);
   } else if (left < 0) {
     analogWrite(M2A, 0);
     analogWrite(M2B, -left);
   } else {
     stopLeft();
   }
 }
 
 void stopMotors() {
   stopLeft();
   stopRight();
 }
 
 void stopLeft() {
   analogWrite(M2A, 0);
   analogWrite(M2B, 0);
 }
 
 void stopRight() {
   analogWrite(M1A, 0);
   analogWrite(M1B, 0);
 }
 
 void sendTelemetry() {
   uint16_t voltageCv = 740; // 7.40V
   uint8_t speed = 42;       // mock
   int8_t leftMotor = 40;
   int8_t rightMotor = 45;
   uint8_t sensorBits = 0b00011;
 
   uint8_t payload[6];
   payload[0] = voltageCv & 0xFF;
   payload[1] = (voltageCv >> 8) & 0xFF;
   payload[2] = speed;
   payload[3] = (uint8_t)leftMotor;
   payload[4] = (uint8_t)rightMotor;
   payload[5] = sensorBits;
 
   telemetryChar.writeValue(payload, 6);
 }
