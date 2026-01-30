import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/control_state.dart';

class TelemetryPanel extends StatelessWidget {
  const TelemetryPanel({
    super.key,
    required this.controlState,
    required this.accentColor,
  });

  final ControlState controlState;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controlState,
      builder: (context, _) {
        final data = controlState.telemetryData;
        return LayoutBuilder(
          builder: (context, constraints) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F151D).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TelemetryCard(
                            label: 'Battery Voltage',
                            value: '${data.batteryVoltage.toStringAsFixed(2)} V',
                            accentColor: accentColor,
                          ),
                          _TelemetryCard(
                            label: 'Robot Speed',
                            value: '${data.speed.toStringAsFixed(0)} %',
                            accentColor: accentColor,
                          ),
                          _TelemetryCard(
                            label: 'Left Motor PWM',
                            value: '${data.leftMotor}',
                            accentColor: accentColor,
                          ),
                          _TelemetryCard(
                            label: 'Right Motor PWM',
                            value: '${data.rightMotor}',
                            accentColor: accentColor,
                          ),
                          _TelemetryCard(
                            label: 'Signal Strength',
                            value: '${data.signalStrength.toStringAsFixed(0)} dBm',
                            accentColor: accentColor,
                          ),
                          _TelemetryCard(
                            label: 'Sensor Status',
                            value: data.sensorStatus,
                            accentColor: data.sensorStatus == 'OK'
                                ? accentColor
                                : const Color(0xFFFFB300),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TelemetryCard extends StatelessWidget {
  const _TelemetryCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF111821).withOpacity(0.7),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(color: accentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
