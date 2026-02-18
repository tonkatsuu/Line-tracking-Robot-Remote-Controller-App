import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/control_state.dart';
import '../widgets/joystick.dart';
import '../widgets/line_sensor_widget.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/status_bar.dart';
import '../widgets/telemetry_panel.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late final ControlState _controlState;

  @override
  void initState() {
    super.initState();
    _controlState = ControlState();
  }

  @override
  void dispose() {
    _controlState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controlState,
        builder: (context, _) {
          final accentColor =
              _controlState.isAutonomous ? const Color(0xFF00E676) : const Color(0xFF00B0FF);
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _controlState.emergencyFlash
                    ? [const Color(0xFF3B0A0A), const Color(0xFF1A0B0B)]
                    : [const Color(0xFF0B0E12), const Color(0xFF0F151D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 52, 12, 18),
                        child: Joystick(
                          onJoystickChanged: _controlState.updateJoystick,
                          knobColor: accentColor,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 52, 12, 18),
                        child: Column(
                          children: [
                            Expanded(
                              child: TelemetryPanel(
                                controlState: _controlState,
                                accentColor: accentColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LineSensorWidget(
                              sensors: _controlState.telemetryData.irSensors,
                              activeColor: accentColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 52, 18, 18),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            _ConnectButton(
                              isConnected: _controlState.telemetryData.isConnected,
                              isConnecting: _controlState.isConnecting,
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                _controlState.connectToDevice();
                              },
                            ),
                            const SizedBox(height: 12),
                            ModeToggle(
                              isAutonomous: _controlState.isAutonomous,
                              onModeChanged: _controlState.setMode,
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 16),
                            _EmergencyStopButton(
                              onPressed: () {
                                HapticFeedback.heavyImpact();
                                _controlState.triggerEmergencyStop();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: StatusBar(
                    accentColor: accentColor,
                    isConnected: _controlState.telemetryData.isConnected,
                    isConnecting: _controlState.isConnecting,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _EmergencyStopButton extends StatelessWidget {
  const _EmergencyStopButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF5252), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5252).withOpacity(0.6),
              blurRadius: 14,
            ),
          ],
        ),
        child: Text(
          'STOP',
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.isConnected,
    required this.isConnecting,
    required this.onPressed,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = isConnected
        ? 'CONNECTED'
        : isConnecting
            ? 'CONNECTING...'
            : 'CONNECT';
    final color = isConnected
        ? const Color(0xFF00C853)
        : isConnecting
            ? const Color(0xFFFFC107)
            : const Color(0xFF00B0FF);
    return InkWell(
      onTap: (isConnected || isConnecting) ? null : onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: Text(
          label,
          style: textTheme.titleLarge?.copyWith(color: color),
        ),
      ),
    );
  }
}
