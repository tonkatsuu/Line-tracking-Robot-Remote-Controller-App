import 'package:flutter/material.dart';

import 'controllers/control_state.dart';
import 'screens/auto_page.dart';
import 'screens/connection_screen.dart';
import 'screens/manual_page.dart';

class RobotControlApp extends StatefulWidget {
  const RobotControlApp({super.key});

  @override
  State<RobotControlApp> createState() => _RobotControlAppState();
}

class _RobotControlAppState extends State<RobotControlApp> {
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
      initialRoute: '/',
      routes: {
        '/': (_) => ConnectionScreen(controlState: _controlState),
        '/manual': (_) => ManualPage(controlState: _controlState),
        '/auto': (_) => AutoPage(controlState: _controlState),
      },
    );
  }
}
