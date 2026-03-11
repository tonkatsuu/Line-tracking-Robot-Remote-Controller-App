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

  static const String serviceUuidString =
      '19B10000-E8F2-537E-4F6C-D104768A1214';
  static const String cmdUuidString =
      '19B10001-E8F2-537E-4F6C-D104768A1214';
  static const String telemetryUuidString =
      '19B10002-E8F2-537E-4F6C-D104768A1214';
  static const String modeUuidString =
      '19B10003-E8F2-537E-4F6C-D104768A1214';
  static const String pickupUuidString =
      '19B10004-E8F2-537E-4F6C-D104768A1214';
  static const String _deviceName = 'Robot-Control-R4';
  static final Guid _serviceUuid = Guid(serviceUuidString);
  static final Guid _writeCharacteristicUuid = Guid(cmdUuidString);
  static final Guid _notifyCharacteristicUuid = Guid(telemetryUuidString);
  static final Guid _modeCharacteristicUuid = Guid(modeUuidString);
  static final Guid _pickupCharacteristicUuid = Guid(pickupUuidString);

  double joystickX = 0;
  double joystickY = 0;
  bool isAutonomous = false;
  bool missionRunning = false;
  bool trailerPickupEngaged = false;
  bool isConnecting = false;
  int speedLimitPwm = 130;
  double? distanceToObjectCm;
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
  Timer? _keepAliveTimer;
  int _lastSentMillis = 0;
  bool emergencyFlash = false;
  final List<String> _debugLogs = <String>[];

  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  BluetoothCharacteristic? _modeCharacteristic;
  BluetoothCharacteristic? _pickupCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  List<String> get debugLogs => List.unmodifiable(_debugLogs);

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
    missionRunning = autonomous;
    unawaited(_sendModeToRobot(autonomous));
    notifyListeners();
  }

  void setSpeedPreset(int pwm) {
    final clamped = pwm.clamp(70, 130);
    if (clamped == speedLimitPwm) return;
    speedLimitPwm = clamped;
    _log('Speed preset set to $speedLimitPwm');
    notifyListeners();
  }

  void toggleTrailerPickup() {
    trailerPickupEngaged = !trailerPickupEngaged;
    unawaited(_sendTrailerToRobot(trailerPickupEngaged));
    _log('Trailer action: ${trailerPickupEngaged ? 'PICKUP' : 'RELEASE'}');
    notifyListeners();
  }

  void setMissionRunning(bool running) {
    if (missionRunning == running && isAutonomous == running) return;
    missionRunning = running;
    isAutonomous = running;
    unawaited(_sendModeToRobot(running));
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
      _log('Permissions denied: $results');
    }
    return !denied;
  }

  Future<void> connectToDevice() async {
    if (isConnecting || telemetryData.isConnected) return;
    _log('Connect requested');
    isConnecting = true;
    notifyListeners();
    await _cleanupBle();

    final hasPermissions = await requestBlePermissions();
    if (!hasPermissions) {
      _log('Connect aborted: permissions missing');
      _setDisconnected();
      return;
    }

    _log('Scanning for $_deviceName');
    final foundDevice = Completer<BluetoothDevice?>();
    final seenDuringScan = <String>{};
    final targetServiceUuid = _serviceUuid.toString().toLowerCase();
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      (results) async {
        if (_device != null || foundDevice.isCompleted) return;
        for (final result in results) {
          final advName = result.advertisementData.advName;
          final deviceName =
              advName.isNotEmpty ? advName : result.device.platformName;
          final advertisedServices = result.advertisementData.serviceUuids
              .map((uuid) => uuid.toString().toLowerCase())
              .toList();
          final hasTargetService = advertisedServices.contains(targetServiceUuid);
          final remoteId = result.device.remoteId.toString();

          if (seenDuringScan.add(remoteId)) {
            _log(
              'Seen device: name="${deviceName.isEmpty ? '(empty)' : deviceName}" '
              'id=$remoteId rssi=${result.rssi} services=${advertisedServices.length}',
            );
          }

          if (_matchesTargetDevice(deviceName) || hasTargetService) {
            _device = result.device;
            _log(
              'Found target: name="${deviceName.isEmpty ? '(empty)' : deviceName}" '
              'id=$remoteId by ${hasTargetService ? 'service' : 'name'}',
            );
            foundDevice.complete(result.device);
            break;
          }
        }
      },
      onError: (error) {
        _log('Scan error: $error');
        if (!foundDevice.isCompleted) foundDevice.complete(null);
        _setDisconnected();
      },
    );

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 12));
    final device = await foundDevice.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => null,
    );
    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    if (device == null) {
      if (isConnecting) {
        _log('Scan timeout: target device not found');
        _setDisconnected();
      }
      return;
    }

    await _connectToDevice(device);
  }

  Future<void> disconnectFromDevice() async {
    if (!telemetryData.isConnected && !isConnecting) return;
    _log('Manual disconnect requested');
    await _cleanupBle();
    _setDisconnected();
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    var canProceed = true;
    try {
      _log('Connecting to ${device.remoteId}');
      await device.connect(
        timeout: const Duration(seconds: 10),
        autoConnect: false,
      );
    } catch (error) {
      // Ignore if already connected; otherwise treat as failure.
      if (!error.toString().contains('already connected')) {
        _log('Connect error: $error');
        canProceed = false;
      }
    }
    if (!canProceed) {
      _setDisconnected();
      return;
    }

    // Ensure the connection is fully established before discovery.
    await _waitForConnected(device);
    if (!await _isConnected(device)) {
      _log('Connect failed: device did not reach connected state');
      _setDisconnected();
      return;
    }
    _log('Connected at transport layer');

    _connectionSubscription?.cancel();
    _connectionSubscription = device.connectionState.listen((state) {
      _log('Connection state: $state');
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
    _log('Service discovery returned ${services.length} services');
    for (final service in services) {
      if (service.uuid != _serviceUuid) continue;
      for (final characteristic in service.characteristics) {
        if (characteristic.uuid == _writeCharacteristicUuid) {
          _writeCharacteristic = characteristic;
        } else if (characteristic.uuid == _notifyCharacteristicUuid) {
          _notifyCharacteristic = characteristic;
        } else if (characteristic.uuid == _modeCharacteristicUuid) {
          _modeCharacteristic = characteristic;
        } else if (characteristic.uuid == _pickupCharacteristicUuid) {
          _pickupCharacteristic = characteristic;
        }
      }
    }

    if (_writeCharacteristic == null || _notifyCharacteristic == null) {
      _log('Required characteristics not found. Retrying connect...');
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
      _log('Retry discovery returned ${services.length} services');
      for (final service in services) {
        if (service.uuid != _serviceUuid) continue;
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid == _writeCharacteristicUuid) {
            _writeCharacteristic = characteristic;
          } else if (characteristic.uuid == _notifyCharacteristicUuid) {
            _notifyCharacteristic = characteristic;
          } else if (characteristic.uuid == _modeCharacteristicUuid) {
            _modeCharacteristic = characteristic;
          } else if (characteristic.uuid == _pickupCharacteristicUuid) {
            _pickupCharacteristic = characteristic;
          }
        }
      }
      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        _log('Retry failed: still missing required characteristics');
        await device.disconnect();
        _setDisconnected();
        return;
      }
    }

    await _notifyCharacteristic!.setNotifyValue(true);
    _log('Notifications enabled');
    _notifySubscription?.cancel();
    _notifySubscription = _notifyCharacteristic!.onValueReceived.listen(
      _handleTelemetry,
      onError: (error) => _log('Notify error: $error'),
    );
    _startKeepAlive();
    await _sendModeToRobot(isAutonomous);
    await _sendTrailerToRobot(trailerPickupEngaged);
    await sendCommand(joystickX, joystickY);
    _log('Connection ready');

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

    final speedScale = speedLimitPwm / 170.0;
    final scaledX = (applyCurve(x * speedScale) * 127).round();
    final scaledY = (applyCurve(y * speedScale) * 127).round();
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
      _log('Write error: $error');
    }
  }

  Future<void> _sendModeToRobot(bool autonomous) async {
    if (_modeCharacteristic == null || !telemetryData.isConnected) return;
    final payload = Uint8List.fromList([autonomous ? 1 : 0]);
    try {
      await _modeCharacteristic!.write(payload, withoutResponse: false);
      _log('Mode write: ${autonomous ? 'AUTO' : 'MANUAL'}');
    } catch (error) {
      _log('Mode write error: $error');
    }
  }

  Future<void> _sendTrailerToRobot(bool pickup) async {
    if (_pickupCharacteristic == null || !telemetryData.isConnected) return;
    final payload = Uint8List.fromList([pickup ? 1 : 0]);
    try {
      await _pickupCharacteristic!.write(payload, withoutResponse: false);
      _log('Trailer write: ${pickup ? 'PICKUP' : 'RELEASE'}');
    } catch (error) {
      _log('Trailer write error: $error');
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
    if (data.length >= 8) {
      final distanceRaw = data[6] | (data[7] << 8);
      distanceToObjectCm = distanceRaw.toDouble();
    }
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
        _log('Discover services error: $error');
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
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;
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
    _modeCharacteristic = null;
    _pickupCharacteristic = null;
    _device = null;
  }

  void _startKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => sendCommand(joystickX, joystickY),
    );
  }

  bool _matchesTargetDevice(String scannedName) {
    final normalizedScanned = scannedName.trim().toLowerCase();
    final normalizedTarget = _deviceName.trim().toLowerCase();
    if (normalizedScanned == normalizedTarget) return true;
    return normalizedScanned.contains(normalizedTarget);
  }

  void _setDisconnected() {
    isConnecting = false;
    missionRunning = false;
    isAutonomous = false;
    telemetryData = _copyTelemetry(isConnected: false);
    _log('Disconnected');
    notifyListeners();
  }

  void clearDebugLogs() {
    _debugLogs.clear();
    notifyListeners();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final line = '[$timestamp] BLE: $message';
    _debugLogs.add(line);
    if (_debugLogs.length > 120) {
      _debugLogs.removeRange(0, _debugLogs.length - 120);
    }
    debugPrint(line);
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
    _keepAliveTimer?.cancel();
    _connectionSubscription?.cancel();
    _cleanupBle();
    super.dispose();
  }
}
