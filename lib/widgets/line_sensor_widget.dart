import 'package:flutter/material.dart';

class LineSensorWidget extends StatelessWidget {
  const LineSensorWidget({
    super.key,
    required this.sensors,
    required this.activeColor,
  });

  final List<bool> sensors;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final items = sensors.length >= 5 ? sensors.sublist(0, 5) : [
      ...sensors,
      ...List<bool>.filled(5 - sensors.length, false),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111821).withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: activeColor.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _SensorDot(
              isActive: items[i],
              activeColor: activeColor,
            ),
            if (i != items.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _SensorDot extends StatelessWidget {
  const _SensorDot({
    required this.isActive,
    required this.activeColor,
  });

  final bool isActive;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : const Color(0xFF6B7280);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: activeColor.withOpacity(0.6),
              blurRadius: 6,
            ),
        ],
      ),
    );
  }
}
