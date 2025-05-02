# environment_plus

A Flutter plugin that provides comprehensive environment information for your Flutter applications.

## Features

- Device Information
  - Device ID
  - Device Model
  - Operating System Version
  - Android ID (for Android devices)
  - Device Brand
  - Physical Device Status
  - Architecture Support (32/64 bit)
- App Information
  - Package Name
  - Version
  - Build Number
  - App Name
- Environment Information
  - Release/Debug Mode
  - Testing Environment Status
  - Platform Status (Android/iOS)
  - Status Bar Height
  - Navigation Bar Height
  - App Bar Height
- Connectivity
  - Listen to connectivity changes (WiFi, mobile, none)
  - Get current network connection types
- Location
  - Get current device location (latitude, longitude, etc.)
  - Listen to position changes as a stream

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  environment_plus: ^0.0.1
```

## Usage

Before using any features, you need to initialize the plugin:

```dart
import 'package:environment_plus/environment_plus.dart';

// Initialize the plugin
await Environment.init();

// Now you can use the features
final environment = Environment();
```

### Available Methods

```dart
// Get environment information
final environment = Environment();

// --- Environment getters ---
print('isAndroid: ${environment.isAndroid}');
print('isIOS: ${environment.isIOS}');
print('session: ${environment.session}');
print('flavor: ${environment.flavor}');
print('batteryState: ${environment.batteryState}');
print('position: ${environment.position}');
print('connection: ${environment.connection}');

// --- DeviceInfo getters ---
final deviceInfo = environment.deviceInfo;
print('brand: ${deviceInfo.brand}');
print('deviceId: ${deviceInfo.deviceId}');
print('isPhysicalDevice: ${deviceInfo.isPhysicalDevice}');
print('machineModel: ${deviceInfo.machineModel}');
print('osVersionName: ${deviceInfo.osVersionName}');
print('osVersionNumber: ${deviceInfo.osVersionNumber}');
print('support64bit: ${deviceInfo.support64bit}');
print('support32bit: ${deviceInfo.support32bit}');

// --- AppInfo getters ---
final appInfo = environment.appInfo;
print('appName: ${appInfo.appName}');
print('appId: ${appInfo.appId}');
print('buildName: ${appInfo.buildName}');
print('buildNumber: ${appInfo.buildNumber}');

// Access device information
final deviceInfo = environment.deviceInfo;
print('Device Model: ${deviceInfo.machineModel}');
print('OS Version: ${deviceInfo.osVersionName}');

// Access app information
final appInfo = environment.appInfo;
print('App Name: ${appInfo.appName}');
print('Version: ${appInfo.buildName}');

// Access environment status
print('Is Debug Mode: ${environment.isDebugMode}');
print('Is Physical Device: ${environment.deviceInfo.isPhysicalDevice}');

// Connectivity: Listen to connectivity changes
environment.onConnectivityChanged().listen((List<ConnectivityResult> results) {
  print('Connectivity changed: $results');
});

// Location: Listen to position changes
environment.onPositionChanged().listen((position) {
  print('Position changed: $position');
});

// Battery: Get current battery level
final batteryLevel = await environment.getBatteryLevel();
print('Battery Level: ${batteryLevel}%');

// Battery: Listen to battery state changes
environment.onBatteryStateChanged().listen((state) {
  print('Battery State: $state');
});
```

### Testing

For testing purposes, you can use `initFake()`:

```dart
await Environment.initFake(
  appInfo: AppInfo.empty(),
  deviceInfo: DeviceInfo.empty(),
);
```

## Dependencies

This plugin depends on the following packages:

- device_info_plus
- package_info_plus
- android_id
- manifest_info_reader
- battery_plus

## Requirements

- Flutter >= 3.3.0
- Dart SDK >= 3.7.2

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
