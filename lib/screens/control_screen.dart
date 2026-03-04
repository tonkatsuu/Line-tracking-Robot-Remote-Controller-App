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
  bool _showDebugPanel = false;

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
                              onConnect: () {
                                HapticFeedback.mediumImpact();
                                _controlState.connectToDevice();
                              },
                              onDisconnect: () {
                                HapticFeedback.mediumImpact();
                                _controlState.disconnectFromDevice();
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
                            const SizedBox(height: 12),
                            _DebugToggleButton(
                              enabled: _showDebugPanel,
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _showDebugPanel = !_showDebugPanel;
                                });
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
                if (_showDebugPanel)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _BleDebugPanel(controlState: _controlState),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BleDebugPanel extends StatelessWidget {
  const _BleDebugPanel({required this.controlState});

  final ControlState controlState;

  @override
  Widget build(BuildContext context) {
    final logs = controlState.debugLogs;
    final visibleLogs = logs.length > 8 ? logs.sublist(logs.length - 8) : logs;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x6600B0FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'BLE Debug Log',
                  style: TextStyle(
                    color: Color(0xFF90CAF9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: controlState.clearDebugLogs,
                child: const Text('Clear'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (visibleLogs.isEmpty)
            const Text(
              'No logs yet. Tap CONNECT.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            )
          else
            ...visibleLogs.map(
              (line) => Text(
                line,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugToggleButton extends StatelessWidget {
  const _DebugToggleButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF90CAF9) : const Color(0xFF607D8B);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.8),
        ),
        child: Text(
          enabled ? 'HIDE DEBUG' : 'SHOW DEBUG',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    required this.onConnect,
    required this.onDisconnect,
  });

  final bool isConnected;
  final bool isConnecting;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = isConnected
        ? 'DISCONNECT'
        : isConnecting
            ? 'CONNECTING...'
            : 'CONNECT';
    final color = isConnected
        ? const Color(0xFFFF5252)
        : isConnecting
            ? const Color(0xFFFFC107)
            : const Color(0xFF00B0FF);
    return InkWell(
      onTap: isConnecting ? null : (isConnected ? onDisconnect : onConnect),
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
