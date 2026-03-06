import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/control_state.dart';
import '../widgets/joystick.dart';

class ManualPage extends StatefulWidget {
  const ManualPage({super.key, required this.controlState});

  final ControlState controlState;

  @override
  State<ManualPage> createState() => _ManualPageState();
}

class _ManualPageState extends State<ManualPage> {
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
                colors: [Color(0xFF070C14), Color(0xFF0A1B2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                          'Manual Control',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _GlassPanel(
                              child: Joystick(
                                onJoystickChanged: widget.controlState.updateJoystick,
                                knobColor: const Color(0xFF00B0FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 4,
                            child: _GlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Speed Limit',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${(widget.controlState.maxSpeed * 100).round()}%',
                                    style: const TextStyle(
                                      color: Color(0xFF00B0FF),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 28,
                                    ),
                                  ),
                                  Slider(
                                    min: 0.0,
                                    max: 1.0,
                                    value: widget.controlState.maxSpeed,
                                    onChanged: widget.controlState.setMaxSpeed,
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 68,
                                    child: ElevatedButton(
                                      onPressed: widget.controlState.toggleTrailerPickup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            widget.controlState.trailerPickupEngaged
                                                ? const Color(0xFF00B0FF)
                                                : const Color(0xFF455A64),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: Text(
                                        widget.controlState.trailerPickupEngaged
                                            ? 'PICKUP TRAILER: ON'
                                            : 'PICKUP TRAILER',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Connection: ${widget.controlState.telemetryData.isConnected ? 'Connected' : 'Disconnected'}',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GlassPanel(
                      child: _TelemetryGrid(controlState: widget.controlState),
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

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x6600B0FF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _TelemetryGrid extends StatelessWidget {
  const _TelemetryGrid({required this.controlState});

  final ControlState controlState;

  @override
  Widget build(BuildContext context) {
    final telemetry = controlState.telemetryData;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 3.2,
      children: [
        _MetricTile(
          label: 'Battery',
          value: '${telemetry.batteryVoltage.toStringAsFixed(2)} V',
        ),
        _MetricTile(
          label: 'RSSI',
          value: '${telemetry.signalStrength.toStringAsFixed(0)} dBm',
        ),
        _MetricTile(label: 'Health', value: telemetry.sensorStatus),
        _MetricTile(label: 'Speed', value: '${telemetry.speed.toStringAsFixed(0)}%'),
        _MetricTile(label: 'Left PWM', value: '${telemetry.leftMotor}'),
        _MetricTile(label: 'Right PWM', value: '${telemetry.rightMotor}'),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
