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
                    const Text(
                      'Robot Remote Controller by May',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 290,
                      height: 70,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: connected
                                ? const [Color(0xFFFF6B6B), Color(0xFFFF3D3D)]
                                : const [Color(0xFF29B6F6), Color(0xFF0277BD)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (connected
                                      ? const Color(0xFFFF5252)
                                      : const Color(0xFF00B0FF))
                                  .withOpacity(0.4),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: connecting
                              ? null
                              : connected
                                  ? controlState.disconnectFromDevice
                                  : controlState.connectToDevice,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: Icon(
                            connected ? Icons.bluetooth_disabled : Icons.bluetooth,
                            size: 24,
                          ),
                          label: Text(
                            connecting
                                ? 'CONNECTING...'
                                : connected
                                    ? 'DISCONNECT'
                                    : 'CONNECT TO ROBOT',
                          ),
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
