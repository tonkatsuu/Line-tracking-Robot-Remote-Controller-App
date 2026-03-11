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
          final telemetry = widget.controlState.telemetryData;
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
                    const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: _GlassPanel(
                              child: Joystick(
                                onJoystickChanged:
                                    widget.controlState.updateJoystick,
                                knobColor: const Color(0xFF00B0FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                Expanded(
                                  child: _GlassPanel(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Telemetry',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.95),
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: GridView.count(
                                            crossAxisCount: 2,
                                            mainAxisSpacing: 8,
                                            crossAxisSpacing: 8,
                                            childAspectRatio: 2.6,
                                            children: [
                                              _MetricTile(
                                                label: 'Battery',
                                                value:
                                                    '${telemetry.batteryVoltage.toStringAsFixed(2)} V',
                                              ),
                                              _MetricTile(
                                                label: 'RSSI',
                                                value:
                                                    '${telemetry.signalStrength.toStringAsFixed(0)} dBm',
                                              ),
                                              _MetricTile(
                                                label: 'Health',
                                                value: telemetry.sensorStatus,
                                              ),
                                              _MetricTile(
                                                label: 'Speed',
                                                value:
                                                    '${telemetry.speed.toStringAsFixed(0)}%',
                                              ),
                                              _MetricTile(
                                                label: 'Left PWM',
                                                value: '${telemetry.leftMotor}',
                                              ),
                                              _MetricTile(
                                                label: 'Right PWM',
                                                value: '${telemetry.rightMotor}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _GlassPanel(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _SpeedPresetButton(
                                          label: 'SLOW',
                                          pwm: 70,
                                          selected:
                                              widget.controlState.speedLimitPwm == 70,
                                          onTap: () => widget.controlState
                                              .setSpeedPreset(70),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _SpeedPresetButton(
                                          label: 'MED',
                                          pwm: 100,
                                          selected:
                                              widget.controlState.speedLimitPwm == 100,
                                          onTap: () => widget.controlState
                                              .setSpeedPreset(100),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _SpeedPresetButton(
                                          label: 'FAST',
                                          pwm: 130,
                                          selected:
                                              widget.controlState.speedLimitPwm == 130,
                                          onTap: () => widget.controlState
                                              .setSpeedPreset(130),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedPresetButton extends StatelessWidget {
  const _SpeedPresetButton({
    required this.label,
    required this.pwm,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int pwm;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF00B0FF) : const Color(0xFF4A6070);
    return SizedBox(
      height: 64,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: selected ? 8 : 1,
          shadowColor: selected
              ? const Color(0xFF00B0FF).withOpacity(0.7)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF81D4FA)
                  : Colors.white.withOpacity(0.15),
              width: selected ? 2.2 : 1,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              '$pwm',
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
