import 'dart:math';

import 'package:flutter/material.dart';

class Joystick extends StatefulWidget {
  const Joystick({
    super.key,
    required this.onJoystickChanged,
    this.baseColor = const Color(0xFF111821),
    this.knobColor = const Color(0xFF00B0FF),
  });

  final void Function(double x, double y) onJoystickChanged;
  final Color baseColor;
  final Color knobColor;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _knobOffset = Offset.zero;
  double _normalizedX = 0;
  double _normalizedY = 0;

  void _updateOffset(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final radius = min(size.width, size.height) * 0.35;
    final clamped = delta.distance > radius
        ? Offset.fromDirection(delta.direction, radius)
        : delta;
    setState(() {
      _knobOffset = clamped;
      _normalizedX = (clamped.dx / radius).clamp(-1.0, 1.0);
      _normalizedY = (-clamped.dy / radius).clamp(-1.0, 1.0);
    });
    widget.onJoystickChanged(_normalizedX, _normalizedY);
  }

  void _reset() {
    setState(() {
      _knobOffset = Offset.zero;
      _normalizedX = 0;
      _normalizedY = 0;
    });
    widget.onJoystickChanged(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final baseSize = min(size.width, size.height);
        final knobSize = baseSize * 0.35;
        return GestureDetector(
          onPanStart: (details) => _updateOffset(details.localPosition, size),
          onPanUpdate: (details) => _updateOffset(details.localPosition, size),
          onPanEnd: (_) => _reset(),
          onPanCancel: _reset,
          child: Center(
            child: Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                color: widget.baseColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.knobColor.withOpacity(0.2),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Transform.translate(
                  offset: _knobOffset,
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: widget.knobColor.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.knobColor.withOpacity(0.6),
                          blurRadius: 20,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
