# Line-Tracking Robot Remote Controller App

A Flutter mobile app to remotely control a line-tracking robot, monitor
telemetry, and switch modes in real time.

## Features
- Manual control with on-screen joystick
- Line sensor and telemetry display
- Mode toggle (manual/auto)
- Status indicators and connection info
- Cross-platform Flutter UI

## Screens
- Control screen
- Telemetry panel
- Line sensor widget
- Status bar

## Tech Stack
- Flutter / Dart
- Material UI

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio or VS Code with Flutter extension
- Android/iOS emulator or a physical device

### Install
```bash
flutter pub get
```

### Run (Android)
```bash
flutter run
```

### Build (Android APK)
```bash
flutter build apk --release
```

## Project Structure
```
lib/
  app.dart
  main.dart
  controllers/
  models/
  screens/
  widgets/
```

## Configuration
If your robot uses a specific IP or Bluetooth ID, update it in your
connection logic (e.g. `lib/controllers/control_state.dart`).

## Roadmap
- [ ] Add pairing screen for Bluetooth/Wi-Fi
- [ ] Save last-used robot address
- [ ] Telemetry logging
- [ ] PID tuning controls

## License
Add a license or remove this section.
