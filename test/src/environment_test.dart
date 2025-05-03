import 'package:flutter_test/flutter_test.dart';
import 'package:environment_plus/src/environment.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  group('Environment', () {
    test('should handle all test cases', () {
      // Test 1: should throw exception when constructor is called without init
      expect(() => Environment(), throwsException);

      // Test 2: should have correct default values with manifest flavor
      final rawInfo = {'manifest.info.flavor': 'development'};
      final env = Environment.initFake(
        rawInfo: rawInfo,
        connection: [ConnectivityResult.wifi],
        batteryState: BatteryState.charging,
      );
      expect(env.isAndroid, isFalse);
      expect(env.isIOS, isFalse);
      expect(env.flavor, equals('development'));
      expect(Environment.session, isNotEmpty);
      expect(env.rawInfo, equals(rawInfo));

      // Test 3: should throw exception when initFake is called twice
      expect(() => Environment.initFake(), throwsException);

      // Test 4: should get correct connection state
      expect(Environment.connection, equals([ConnectivityResult.wifi]));

      // Test 5: should get correct battery state
      expect(Environment.batteryState, equals(BatteryState.charging));

      // Test 6: should get correct position
      expect(Environment.position, isNull);

      // Test 7: should have correct platform-specific values
      expect(Environment.isReleaseMode, isNotNull);
      expect(Environment.isDebugMode, isNotNull);
      expect(Environment.isInTestingEnv, isTrue);
      expect(Environment.statusBarHeight, isNotNull);
      expect(Environment.navigationBarHeight, isNotNull);
      expect(Environment.appBarHeight, isNotNull);
    });
  });
}
