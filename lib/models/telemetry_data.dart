class TelemetryData {
  const TelemetryData({
    required this.batteryVoltage,
    required this.speed,
    required this.leftMotor,
    required this.rightMotor,
    required this.sensorStatus,
    required this.irSensors,
    required this.isConnected,
    required this.signalStrength,
  });

  final double batteryVoltage;
  final double speed;
  final int leftMotor;
  final int rightMotor;
  final String sensorStatus;
  final List<bool> irSensors;
  final bool isConnected;
  final double signalStrength;
}
