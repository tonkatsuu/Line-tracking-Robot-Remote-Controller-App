import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ModeToggle extends StatelessWidget {
  const ModeToggle({
    super.key,
    required this.isAutonomous,
    required this.onModeChanged,
    required this.accentColor,
  });

  final bool isAutonomous;
  final void Function(bool isAutonomous) onModeChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final label = isAutonomous ? 'AUTONOMOUS' : 'MANUAL';
    return InkWell(
      onTap: () {
        HapticFeedback.heavyImpact();
        onModeChanged(!isAutonomous);
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.35),
              blurRadius: 14,
            ),
          ],
        ),
        child: Text(
          label,
          style: textTheme.headlineSmall?.copyWith(color: accentColor),
        ),
      ),
    );
  }
}
