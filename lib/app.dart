import 'package:flutter/material.dart';

import 'screens/control_screen.dart';

class RobotControlApp extends StatelessWidget {
  const RobotControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00B0FF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Robotics Control',
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E12),
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent,
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const ControlScreen(),
    );
  }
}
