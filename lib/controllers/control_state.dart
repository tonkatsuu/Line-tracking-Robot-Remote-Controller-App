import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/telemetry_data.dart';

class ControlState extends ChangeNotifier {
  ControlState() {
    _startMockTelemetry();
  }

  double joystickX = 0;
  double joystickY = 0;
  bool isAutonomous = false;
  TelemetryData telemetryData = const TelemetryData(
    batteryVoltage: 12.4,
    speed: 0,
    leftMotor: 0,
    rightMotor: 0,
    sensorStatus: 'OK',
    irSensors: [false, false, false, false, false],
    isConnected: false,
    signalStrength: -60,
  );

  Timer? _telemetryTimer;
  Timer? _flashTimer;
  final Random _rng = Random();
  int _lastSentMillis = 0;
  bool emergencyFlash = false;

  void updateJoystick(double x, double y) {
    if (x == joystickX && y == joystickY) return;
    joystickX = x;
    joystickY = y;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMillis >= 50) {
      _lastSentMillis = now;
      // Mock outbound command throttled to 20 Hz max.
      debugPrint('Joystick update: x=${x.toStringAsFixed(2)}, y=${y.toStringAsFixed(2)}');
    }
    notifyListeners();
  }

  void setMode(bool autonomous) {
    if (autonomous == isAutonomous) return;
    isAutonomous = autonomous;
    notifyListeners();
  }

  void _startMockTelemetry() {
    // Mock data loop for UI-only telemetry updates.
    _telemetryTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final battery = 11.2 + _rng.nextDouble() * 1.6;
      final speed = _rng.nextDouble() * 100;
      final leftMotor = _rng.nextInt(511) - 255;
      final rightMotor = _rng.nextInt(511) - 255;
      final irSensors = List<bool>.generate(5, (_) => _rng.nextDouble() > 0.6);
      final sensorStatus = irSensors.contains(true) ? 'OK' : 'WARNING';
      final isConnected = _rng.nextDouble() > 0.1;
      final signalStrength = -90 + _rng.nextDouble() * 60;
      telemetryData = TelemetryData(
        batteryVoltage: battery,
        speed: speed,
        leftMotor: leftMotor,
        rightMotor: rightMotor,
        sensorStatus: sensorStatus,
        irSensors: irSensors,
        isConnected: isConnected,
        signalStrength: signalStrength,
      );
      notifyListeners();
    });
  }

  void triggerEmergencyStop() {
    joystickX = 0;
    joystickY = 0;
    emergencyFlash = true;
    notifyListeners();
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 500), () {
      emergencyFlash = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    _flashTimer?.cancel();
    super.dispose();
  }
}
