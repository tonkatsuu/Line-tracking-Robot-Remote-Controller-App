import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/control_state.dart';
import '../widgets/line_sensor_widget.dart';

class AutoPage extends StatefulWidget {
  const AutoPage({super.key, required this.controlState});

  final ControlState controlState;

  @override
  State<AutoPage> createState() => _AutoPageState();
}

class _AutoPageState extends State<AutoPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        onPressed: () => widget.controlState.triggerEmergencyStop(),
        label: const Text('E-STOP'),
        icon: const Icon(Icons.warning_amber_rounded),
      ),
      body: AnimatedBuilder(
        animation: widget.controlState,
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF07140B), Color(0xFF102018)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Autonomous Mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _GlassPanel(
                      borderColor: const Color(0x6600E676),
                      child: Column(
                        children: [
                          const Text(
                            'Line Following Status',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 14),
                          LineSensorWidget(
                            sensors: widget.controlState.telemetryData.irSensors,
                            activeColor: const Color(0xFF00E676),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _GlassPanel(
                              borderColor: const Color(0x6600E676),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      label: 'START MISSION',
                                      color: const Color(0xFF00E676),
                                      onTap: () =>
                                          widget.controlState.setMissionRunning(true),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: _ActionButton(
                                      label: 'STOP / ABORT',
                                      color: const Color(0xFFFF5252),
                                      onTap: () => widget.controlState
                                          .setMissionRunning(false),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: _GlassPanel(
                              borderColor: const Color(0x6600E676),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MetricRow(
                                    label: 'Mission State',
                                    value: widget.controlState.missionRunning
                                        ? 'RUNNING'
                                        : 'IDLE',
                                  ),
                                  _MetricRow(
                                    label: 'Robot Speed',
                                    value:
                                        '${widget.controlState.telemetryData.speed.toStringAsFixed(0)}%',
                                  ),
                                  _MetricRow(
                                    label: 'Distance to Object',
                                    value: widget.controlState.distanceToObjectCm ==
                                            null
                                        ? '--'
                                        : '${widget.controlState.distanceToObjectCm!.toStringAsFixed(0)} cm',
                                  ),
                                  const Divider(color: Colors.white24, height: 24),
                                  _MetricRow(
                                    label: 'Battery',
                                    value:
                                        '${widget.controlState.telemetryData.batteryVoltage.toStringAsFixed(2)} V',
                                  ),
                                  _MetricRow(
                                    label: 'RSSI',
                                    value:
                                        '${widget.controlState.telemetryData.signalStrength.toStringAsFixed(0)} dBm',
                                  ),
                                  _MetricRow(
                                    label: 'Sensor Health',
                                    value: widget.controlState.telemetryData.sensorStatus,
                                  ),
                                  _MetricRow(
                                    label: 'Left / Right PWM',
                                    value:
                                        '${widget.controlState.telemetryData.leftMotor} / ${widget.controlState.telemetryData.rightMotor}',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 18)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    required this.borderColor,
  });

  final Widget child;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }
}
