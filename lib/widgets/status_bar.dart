import 'package:flutter/material.dart';

class StatusBar extends StatefulWidget {
  const StatusBar({
    super.key,
    required this.accentColor,
    required this.isConnected,
    required this.isConnecting,
  });

  final Color accentColor;
  final bool isConnected;
  final bool isConnecting;

  @override
  State<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends State<StatusBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _pulse =
      Tween<double>(begin: 0.55, end: 1).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusText = widget.isConnected
        ? 'CONNECTED'
        : widget.isConnecting
            ? 'CONNECTING...'
            : 'DISCONNECTED';
    final statusColor = widget.isConnected
        ? widget.accentColor
        : widget.isConnecting
            ? const Color(0xFFFFC107)
            : const Color(0xFFFF4D4D);
    final statusIcon = widget.isConnected
        ? Icons.bluetooth
        : widget.isConnecting
            ? Icons.bluetooth_searching
            : Icons.bluetooth_disabled;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E12).withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: widget.accentColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MECHATRONICS REMOTE CONTROL by May Myint Mo',
              style: textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
              const SizedBox(width: 6),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Opacity(
                    opacity: widget.isConnected ? _pulse.value : 1,
                    child: Text(
                      statusText,
                      style: textTheme.bodyLarge?.copyWith(color: statusColor),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Icon(Icons.battery_full, color: widget.accentColor, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}
