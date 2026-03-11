#include <ArduinoBLE.h>
#include <Servo.h>
 
static const char* SERVICE_UUID   = "19B10000-E8F2-537E-4F6C-D104768A1214";
static const char* CMD_UUID       = "19B10001-E8F2-537E-4F6C-D104768A1214";
static const char* TELEMETRY_UUID = "19B10002-E8F2-537E-4F6C-D104768A1214";
static const char* MODE_UUID      = "19B10003-E8F2-537E-4F6C-D104768A1214";
static const char* PICKUP_UUID    = "19B10004-E8F2-537E-4F6C-D104768A1214";
 
BLEService robotService(SERVICE_UUID);
BLECharacteristic commandChar(CMD_UUID, BLEWrite | BLEWriteWithoutResponse, 2);
BLECharacteristic telemetryChar(TELEMETRY_UUID, BLENotify, 6);
BLECharacteristic modeChar(MODE_UUID, BLEWrite, 1);
BLECharacteristic pickupChar(PICKUP_UUID, BLEWrite, 1);
 
const int M1A = 11;  // Right motor forward
const int M1B = 10;  // Right motor reverse
const int M2A = 9;   // Left motor forward
const int M2B = 8;   // Left motor reverse
const int midIR = 6;
const int leftIR = 5;
const int rightIR = 7;
const int servoPin = 4;
 
const unsigned long FAILSAFE_MS = 400;
unsigned long lastCmdTime = 0;
unsigned long lastTelemetryMs = 0;
 
const float DEADZONE = 0.10f;
const int MAX_SPEED = 170;
bool autoEnabled = false;
bool trailerPickupEngaged = false;
int currentLeftPwm = 0;
int currentRightPwm = 0;
Servo trailerServo;
const int trailerRaisedAngle = 150;
const int trailerPickupAngle = 120;
 
 void setup() {
  Serial.begin(115200);

  pinMode(M1A, OUTPUT);
  pinMode(M1B, OUTPUT);
  pinMode(M2A, OUTPUT);
  pinMode(M2B, OUTPUT);
  stopMotors();
  pinMode(midIR, INPUT_PULLUP);
  pinMode(leftIR, INPUT_PULLUP);
  pinMode(rightIR, INPUT_PULLUP);
  trailerServo.attach(servoPin);
  trailerServo.write(trailerRaisedAngle);
 
   if (!BLE.begin()) {
     Serial.println("BLE init failed.");
     while (true) {}
   }
  delay(300);
 
  BLE.setLocalName("Robot-Control-R4");
  BLE.setDeviceName("Robot-Control-R4");
   BLE.setAdvertisedService(robotService);
 
   robotService.addCharacteristic(commandChar);
   robotService.addCharacteristic(telemetryChar);
  robotService.addCharacteristic(modeChar);
  robotService.addCharacteristic(pickupChar);
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
  BLE.poll();
   BLEDevice central = BLE.central();
 
   if (central) {
     Serial.print("Connected to: ");
    Serial.println(central.address());
    lastCmdTime = millis();
    autoEnabled = false;
    trailerPickupEngaged = false;
    trailerServo.write(trailerRaisedAngle);
 
     while (central.connected()) {
      BLE.poll();

      if (modeChar.written()) {
        uint8_t modeValue = 0;
        modeChar.readValue(&modeValue, 1);
        autoEnabled = (modeValue == 1);
        stopMotors();
        Serial.print("Mode changed to: ");
        Serial.println(autoEnabled ? "AUTO" : "MANUAL");
      }

      if (pickupChar.written()) {
        uint8_t pickupValue = 0;
        pickupChar.readValue(&pickupValue, 1);
        trailerPickupEngaged = (pickupValue == 1);
        trailerServo.write(
          trailerPickupEngaged ? trailerPickupAngle : trailerRaisedAngle
        );
        Serial.print("Trailer pickup: ");
        Serial.println(trailerPickupEngaged ? "ENGAGED" : "RELEASED");
      }

      if (!autoEnabled && commandChar.written()) {
         uint8_t buffer[2];
         commandChar.readValue(buffer, 2);
         int8_t x = (int8_t)buffer[0];
         int8_t y = (int8_t)buffer[1];
 
         handleJoystick(x, y);
         lastCmdTime = millis();
       }
 
      if (!autoEnabled && millis() - lastCmdTime > FAILSAFE_MS) {
         stopMotors();
       }

      if (autoEnabled) {
        AutoMode();
      }
 
       if (millis() - lastTelemetryMs >= 500) {
         lastTelemetryMs = millis();
         sendTelemetry();
       }
     }
 
     Serial.println("Disconnected");
     stopMotors();
    BLE.advertise();
    Serial.println("Re-advertising");
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
  // Match firmware output limits with app presets (100/130/170).
  left  = constrain(left, -MAX_SPEED, MAX_SPEED);
  right = constrain(right, -MAX_SPEED, MAX_SPEED);
 
   // LEFT MOTOR (invert to fix reversed direction)
   left = -left;
  currentLeftPwm = left;
  currentRightPwm = right;
 
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
  currentLeftPwm = 0;
  currentRightPwm = 0;
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
  uint8_t speed = (uint8_t)((max(abs(currentLeftPwm), abs(currentRightPwm)) * 100) / MAX_SPEED);
  int8_t leftMotor = (int8_t)((currentLeftPwm * 100) / MAX_SPEED);
  int8_t rightMotor = (int8_t)((currentRightPwm * 100) / MAX_SPEED);
  uint8_t sensorBits = 0;
  if (digitalRead(leftIR) == LOW) sensorBits |= (1 << 0);
  if (digitalRead(midIR) == LOW) sensorBits |= (1 << 1);
  if (digitalRead(rightIR) == LOW) sensorBits |= (1 << 2);
 
   uint8_t payload[6];
   payload[0] = voltageCv & 0xFF;
   payload[1] = (voltageCv >> 8) & 0xFF;
   payload[2] = speed;
   payload[3] = (uint8_t)leftMotor;
   payload[4] = (uint8_t)rightMotor;
   payload[5] = sensorBits;
 
   telemetryChar.writeValue(payload, 6);
 }

void AutoMode() {
  // IR sensors are active-low with INPUT_PULLUP.
  bool leftDetected = (digitalRead(leftIR) == LOW);
  bool rightDetected = (digitalRead(rightIR) == LOW);
  bool midDetected = (digitalRead(midIR) == LOW);

  if (!leftDetected && midDetected && !rightDetected) {
    setMotor(70, 70); // forward
  } else if (leftDetected && midDetected && !rightDetected) {
    setMotor(50, 70); // slight left
  } else if (leftDetected && !midDetected && !rightDetected) {
    setMotor(-70, 70); // sharp left
  } else if (!leftDetected && midDetected && rightDetected) {
    setMotor(70, 50); // slight right
  } else if (!leftDetected && !midDetected && rightDetected) {
    setMotor(70, -70); // sharp right
  } else if (leftDetected && midDetected && rightDetected) {
    setMotor(0, 0); // stop
  } else {
    setMotor(0, 0);
  }
}