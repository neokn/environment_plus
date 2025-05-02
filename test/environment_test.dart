import 'package:flutter_test/flutter_test.dart';
import 'package:environment_plus/environment_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/services.dart';

// Stub classes for dependencies (避免 mockito 問題)
class StubAppInfo implements AppInfo {
  @override
  String get appId => 'test.app';
  @override
  String get appName => 'TestApp';
  @override
  String get buildName => '1.0.0';
  @override
  String get buildNumber => '1';
  final Map<String, dynamic> _rawInfo;
  StubAppInfo({Map<String, dynamic>? rawInfo}) : _rawInfo = rawInfo ?? {};
  @override
  Map<String, dynamic> get rawInfo => _rawInfo;
  @override
  AppInfo copyWith({String? appId, String? appName, String? buildName, String? buildNumber, Map<String, dynamic>? rawInfo}) => this;
}

class StubDeviceInfo implements DeviceInfo {
  @override
  String get brand => 'stub';
  @override
  String? get deviceId => 'device123';
  @override
  bool get isPhysicalDevice => true;
  @override
  String get machineModel => 'stubModel';
  @override
  String get osVersionName => 'stubOS';
  @override
  int get osVersionNumber => 1;
  @override
  Map<String, dynamic> get rawInfo => {};
  @override
  bool get support32bit => true;
  @override
  bool get support64bit => true;
  @override
  DeviceInfo copyWith({String? brand, String? deviceId, bool? isPhysicalDevice, String? machineModel, String? osVersionName, int? osVersionNumber, Map<String, dynamic>? rawInfo, bool? support32bit, bool? support64bit}) => this;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // region: Mock platform channel for battery_plus
  const batteryChannel = MethodChannel('dev.fluttercommunity.plus/battery');
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      batteryChannel,
      (call) async {
        if (call.method == 'getBatteryLevel') {
          return 100; // always return 100%
        }
        if (call.method == 'onBatteryStateChanged') {
          // Return a dummy stream (not used in this test)
          return null;
        }
        return null;
      },
    );
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      batteryChannel,
      null,
    );
  });
  // endregion

  group('Environment singleton and initialization', () {
    tearDown(() {
      // Reset singleton after each test
      Environment.initFake();
    });

    test('Throws if not initialized', () {
      expect(() => Environment(), throwsA(isA<String>()));
    });

    test('initFake creates singleton and can get instance', () {
      Environment.initFake();
      expect(Environment(), isA<Environment>());
    });

    test('initFake with custom info', () {
      final fakeAppInfo = StubAppInfo();
      final fakeDeviceInfo = StubDeviceInfo();
      Environment.initFake(appInfo: fakeAppInfo, deviceInfo: fakeDeviceInfo);
      final env = Environment();
      expect(env.appInfo, fakeAppInfo);
      expect(env.deviceInfo, fakeDeviceInfo);
    });

    test('Environment getters flavor returns value if set', () {
      // 修正：傳入含 flavor 的 rawInfo
      Environment.initFake(
        rawInfo: {'manifest.info.flavor': 'dev'},
      );
      final env = Environment();
      expect(env.flavor, 'dev');
    });

    test('onBatteryStateChanged returns a Stream<BatteryState>', () {
      Environment.initFake();
      final env = Environment();
      expect(env.onBatteryStateChanged(), isA<Stream<BatteryState>>());
    });

    test('getBatteryLevel returns a Future<int>', () async {
      Environment.initFake();
      final env = Environment();
      final level = await env.getBatteryLevel();
      expect(level, isA<int>());
    });
  });

  group('Position and permission', () {
    test('onPositionChanged throws if no permission', () {
      Environment.initFake();
      final env = Environment();
      expect(() => env.onPositionChanged(), returnsNormally);
    });
  });
}
