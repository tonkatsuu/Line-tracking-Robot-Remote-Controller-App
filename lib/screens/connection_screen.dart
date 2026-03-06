import 'dart:ui';

import 'package:flutter/material.dart';

import '../controllers/control_state.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({super.key, required this.controlState});

  final ControlState controlState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controlState,
        builder: (context, _) {
          final connected = controlState.telemetryData.isConnected;
          final connecting = controlState.isConnecting;
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF080B12), Color(0xFF0D1421)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'BLE UUID HUD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'SERVICE: 19B10000-E8F2-537E-4F6C-D104768A1214',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Text(
                            'CMD: 19B10001-E8F2-537E-4F6C-D104768A1214',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 320,
                      height: 84,
                      child: ElevatedButton(
                        onPressed: connecting
                            ? null
                            : connected
                                ? controlState.disconnectFromDevice
                                : controlState.connectToDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: connected
                              ? const Color(0xFFFF5252)
                              : const Color(0xFF00B0FF),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          connecting
                              ? 'CONNECTING...'
                              : connected
                                  ? 'DISCONNECT'
                                  : 'CONNECT TO ROBOT',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (connected)
                      Row(
                        children: [
                          Expanded(
                            child: _ModeCard(
                              label: 'MANUAL MODE',
                              color: const Color(0xFF00B0FF),
                              onTap: () => Navigator.pushNamed(context, '/manual'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _ModeCard(
                              label: 'AUTOMATED MODE',
                              color: const Color(0xFF00E676),
                              onTap: () => Navigator.pushNamed(context, '/auto'),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    _GlassPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Telemetry',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 2.8,
                            children: [
                              _MetricTile(
                                label: 'Battery Voltage',
                                value:
                                    '${controlState.telemetryData.batteryVoltage.toStringAsFixed(2)} V',
                              ),
                              _MetricTile(
                                label: 'RSSI',
                                value:
                                    '${controlState.telemetryData.signalStrength.toStringAsFixed(0)} dBm',
                              ),
                              _MetricTile(
                                label: 'Sensor Health',
                                value: controlState.telemetryData.sensorStatus,
                              ),
                            ],
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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: _GlassPanel(
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
