import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/telemetry_data.dart';

class ControlState extends ChangeNotifier {
  ControlState() {
    // Connection is triggered manually via the UI.
  }

  static const String _deviceName = 'Robot-Control-R4';
  static final Guid _serviceUuid = Guid('19B10000-E8F2-537E-4F6C-D104768A1214');
  static final Guid _writeCharacteristicUuid =
      Guid('19B10001-E8F2-537E-4F6C-D104768A1214');
  static final Guid _notifyCharacteristicUuid =
      Guid('19B10002-E8F2-537E-4F6C-D104768A1214');

  double joystickX = 0;
  double joystickY = 0;
  bool isAutonomous = false;
  bool isConnecting = false;
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

  Timer? _flashTimer;
  int _lastSentMillis = 0;
  bool emergencyFlash = false;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  void updateJoystick(double x, double y) {
    if (x == joystickX && y == joystickY) return;
    joystickX = x;
    joystickY = y;
    sendCommand(x, y);
    notifyListeners();
  }

  void setMode(bool autonomous) {
    if (autonomous == isAutonomous) return;
    isAutonomous = autonomous;
    notifyListeners();
  }

  Future<bool> requestBlePermissions() async {
    if (!Platform.isAndroid) return true;
    final results = <Permission, PermissionStatus>{};
    final permissions = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ];
    for (final permission in permissions) {
      results[permission] = await permission.request();
    }
    final denied = results.values.any((status) => !status.isGranted);
    if (denied) {
      debugPrint('BLE permissions denied: $results');
    }
    return !denied;
  }

  Future<void> connectToDevice() async {
    if (isConnecting || telemetryData.isConnected) return;
    isConnecting = true;
    notifyListeners();
    await _cleanupBle();

    final hasPermissions = await requestBlePermissions();
    if (!hasPermissions) {
      _setDisconnected();
      return;
    }

    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        if (_device != null) return;
        for (final result in results) {
          final advName = result.advertisementData.advName;
          final deviceName =
              advName.isNotEmpty ? advName : result.device.platformName;
          if (deviceName == _deviceName) {
            _device = result.device;
            await FlutterBluePlus.stopScan();
            await _scanSubscription?.cancel();
            _scanSubscription = null;
            await _connectToDevice(result.device);
            break;
          }
        }
      },
      onError: (error) {
        debugPrint('BLE scan error: $error');
        _setDisconnected();
      },
    );

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 8),
      withServices: [_serviceUuid],
    );
    if (_device == null && isConnecting) {
      _setDisconnected();
    }
  }

  Future<void> disconnectFromDevice() async {
    if (!telemetryData.isConnected && !isConnecting) return;
    await _cleanupBle();
    _setDisconnected();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
    } catch (error) {
      // Ignore if already connected; otherwise treat as failure.
      if (!error.toString().contains('already connected')) {
        debugPrint('BLE connect error: $error');
      }
    }

    // Ensure the connection is fully established before discovery.
    await _waitForConnected(device);
    if (!await _isConnected(device)) {
      _setDisconnected();
      return;
    }

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _setDisconnected();
      }
    });

    // Give the peripheral a moment to finish setting up GATT, then retry.
    await Future.delayed(const Duration(milliseconds: 250));
    if (Platform.isAndroid) {
      try {
        await device.requestMtu(64);
      } catch (_) {}
    }
    var services = await _discoverServicesWithRetry(device);
    for (final service in services) {
      if (service.uuid != _serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _writeCharacteristicUuid) {
          _writeCharacteristic = characteristic;
        } else if (characteristic.uuid == _notifyCharacteristicUuid) {
          _notifyCharacteristic = characteristic;
        }
      }
    }

    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      debugPrint('BLE characteristics not found.');
      // Retry once after a short reconnect (Android GATT flakiness).
      try {
        await device.disconnect();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        await device.connect(
          timeout: const Duration(seconds: 10),
          autoConnect: false,
        );
      } catch (_) {}
      await _waitForConnected(device);
      services = await _discoverServicesWithRetry(device);
      for (final service in services) {
        if (service.uuid != _serviceUuid) continue;
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == _writeCharacteristicUuid) {
            _writeCharacteristic = characteristic;
          } else if (characteristic.uuid == _notifyCharacteristicUuid) {
            _notifyCharacteristic = characteristic;
          }
        }
      }
      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        await device.disconnect();
        _setDisconnected();
        return;
      }
    }

    await _notifyCharacteristic!.setNotifyValue(true);
    _notifySubscription?.cancel();
    _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(
      _handleTelemetry,
      onError: (error) => debugPrint('Notify error: $error'),
    );

    isConnecting = false;
    telemetryData = _copyTelemetry(
      isConnected: true,
      signalStrength: telemetryData.signalStrength,
    );
    notifyListeners();
  }

  Future<void> sendCommand(double x, double y) async {
    if (_writeCharacteristic == null || !telemetryData.isConnected) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastSentMillis < 50) return;
    _lastSentMillis = now;

    // Add a response curve so small joystick moves are gentler.
    const double expo = 0.55;
    const double maxScale = 0.85;

    double applyCurve(double value) {
      final clamped = value.clamp(-1.0, 1.0);
      final curved = clamped * (1 - expo) + clamped * clamped * clamped * expo;
      return (curved * maxScale).clamp(-1.0, 1.0);
    }

    final scaledX = (applyCurve(x) * 127).round();
    final scaledY = (applyCurve(y) * 127).round();
    final payload = Uint8List.fromList([
      scaledX & 0xFF,
      scaledY & 0xFF,
    ]);

    try {
      await _writeCharacteristic!.write(
        payload,
        withoutResponse: true,
      );
    } catch (error) {
      debugPrint('BLE write error: $error');
    }
  }

  void _handleTelemetry(List<int> data) {
    if (data.length < 6) return;
    final voltageRaw = data[0] | (data[1] << 8);
    final voltage = voltageRaw / 100.0;
    final speed = data[2].toDouble();
    final leftMotor = _toSignedInt8(data[3]);
    final rightMotor = _toSignedInt8(data[4]);
    final sensorBits = data[5];
    final irSensors = List<bool>.generate(
      5,
      (index) => (sensorBits & (1 << index)) != 0,
    );
    final sensorStatus = irSensors.contains(true) ? 'OK' : 'WARNING';

    telemetryData = TelemetryData(
      batteryVoltage: voltage,
      speed: speed,
      leftMotor: leftMotor,
      rightMotor: rightMotor,
      sensorStatus: sensorStatus,
      irSensors: irSensors,
      isConnected: true,
      signalStrength: telemetryData.signalStrength,
    );
    notifyListeners();
  }

  int _toSignedInt8(int value) {
    return value > 127 ? value - 256 : value;
  }

  Future<bool> _isConnected(BluetoothDevice device) async {
    try {
      final state = await device.connectionState.first;
      return state == BluetoothConnectionState.connected;
    } catch (_) {
      return false;
    }
  }

  Future<void> _waitForConnected(BluetoothDevice device) async {
    try {
      await device.connectionState
          .firstWhere(
            (state) => state == BluetoothConnectionState.connected,
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort: proceed even if the stream didn't emit in time.
    }
  }

  Future<List<BluetoothService>> _discoverServicesWithRetry(
    BluetoothDevice device,
  ) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final services = await device.discoverServices();
        if (services.isNotEmpty) return services;
      } catch (error) {
        debugPrint('BLE discover services error: $error');
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
    return device.discoverServices();
  }

  TelemetryData _copyTelemetry({
    double? batteryVoltage,
    double? speed,
    int? leftMotor,
    int? rightMotor,
    String? sensorStatus,
    List<bool>? irSensors,
    bool? isConnected,
    double? signalStrength,
  }) {
    return TelemetryData(
      batteryVoltage: batteryVoltage ?? telemetryData.batteryVoltage,
      speed: speed ?? telemetryData.speed,
      leftMotor: leftMotor ?? telemetryData.leftMotor,
      rightMotor: rightMotor ?? telemetryData.rightMotor,
      sensorStatus: sensorStatus ?? telemetryData.sensorStatus,
      irSensors: irSensors ?? telemetryData.irSensors,
      isConnected: isConnected ?? telemetryData.isConnected,
      signalStrength: signalStrength ?? telemetryData.signalStrength,
    );
  }

  Future<void> _cleanupBle() async {
    await _notifySubscription?.cancel();
    _notifySubscription = null;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();

    if (_notifyCharacteristic != null) {
      try {
        await _notifyCharacteristic!.setNotifyValue(false);
      } catch (_) {}
    }

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }

    _notifyCharacteristic = null;
    _writeCharacteristic = null;
    _device = null;
  }

  void _setDisconnected() {
    isConnecting = false;
    telemetryData = _copyTelemetry(isConnected: false);
    notifyListeners();
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
    _flashTimer?.cancel();
    _connectionSubscription?.cancel();
    _cleanupBle();
    super.dispose();
  }
}
