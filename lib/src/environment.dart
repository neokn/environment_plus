import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:manifest_info_reader/manifest_info_reader.dart'
    show ManifestInfoReader;
import 'package:slugid/slugid.dart';

import 'app_info.dart';
import 'device_info.dart';
import 'system_directories.dart';

part 'environment.freezed.dart';
part 'environment.g.dart';

@freezed
abstract class Environment with _$Environment {
  static BatteryState get batteryState => _batteryState;

  static Position? get position {
    if (_position == null) {
      _logger.warning('Position is null maybe permission is denied');
    }
    return _position;
  }

  static List<ConnectivityResult> get connection => _connection;

  static final Logger _logger = Logger('Environment');
  static final Map<String, dynamic> _rawInfo = <String, dynamic>{};
  static Environment? _singleton;

  // Cache a single Connectivity instance to avoid memory issues.
  static final Connectivity _connectivity = Connectivity();
  static final Battery _battery = Battery();

  static late List<ConnectivityResult> _connection;
  static late BatteryState _batteryState;
  static Position? _position;
  // region: Singleton instance getter
  factory Environment() {
    if (_singleton == null) {
      throw "Please run `await Environment.init()` or `await Environment.initFake()` for testing first";
    }
    return _singleton!;
  }

  @visibleForTesting
  factory Environment.initFake({
    AppInfo? appInfo,
    DeviceInfo? deviceInfo,
    Map<String, dynamic> rawInfo = const {},
    String session = "",
    SystemDirectories? systemDirectories,
    bool isAndroid = false,
    bool isIOS = false,
    String? flavor,
  }) =>
      _singleton ??= Environment._(
        // ignore: invalid_use_of_visible_for_testing_member
        appInfo: appInfo ?? AppInfo.initFake(),
        // ignore: invalid_use_of_visible_for_testing_member
        deviceInfo: deviceInfo ?? DeviceInfo.initFake(),
        rawInfo: rawInfo,
        session: session,
        // ignore: invalid_use_of_visible_for_testing_member
        systemDirectories: systemDirectories ?? SystemDirectories.initFake(),
        isAndroid: isAndroid,
        isIOS: isIOS,
        flavor: flavor,
      );

  const factory Environment._({
    required AppInfo appInfo,
    required DeviceInfo deviceInfo,
    required Map<String, dynamic> rawInfo,
    required String session,
    required SystemDirectories systemDirectories,
    required bool isAndroid,
    required bool isIOS,
    required String? flavor,
  }) = _Environment;

  static Future<Environment> init() async {
    if (_singleton != null) {
      return _singleton!;
    }

    final results = await Future.wait([
      AppInfo.init(),
      DeviceInfo.init(),
      ManifestInfoReader.getValues().then((values) {
        return values?.entries.map(
              (entry) => MapEntry("manifest.info.${entry.key}", entry.value),
            ) ??
            {};
      }),
      _connectivity.checkConnectivity(),
      _battery.batteryState,
      Geolocator.checkPermission().then(
        (permission) =>
            permission != LocationPermission.denied &&
                    permission != LocationPermission.deniedForever &&
                    permission != LocationPermission.unableToDetermine
                ? Geolocator.getCurrentPosition()
                : Future.value(null),
      ),
      SystemDirectories.init(),
    ]);

    var appInfo = results[0] as AppInfo;
    var deviceInfo = results[1] as DeviceInfo;
    var systemDirectories = results[6] as SystemDirectories;

    _rawInfo.addAll(appInfo.rawInfo);
    _rawInfo.addAll(deviceInfo.rawInfo);
    _rawInfo.addEntries(results[2] as Iterable<MapEntry<String, dynamic>>);

    _connection = results[3] as List<ConnectivityResult>;
    _batteryState = results[4] as BatteryState;
    _position = results[5] as Position?;

    _singleton = Environment._(
      appInfo: appInfo,
      deviceInfo: deviceInfo,
      session: Slugid.nice().toString(),
      rawInfo: _rawInfo,
      systemDirectories: systemDirectories,
      isAndroid: Platform.isAndroid,
      isIOS: Platform.isIOS,
      flavor: _rawInfo['manifest.info.flavor'] as String?,
    );

    _battery.onBatteryStateChanged.listen((state) async {
      _batteryState = state;
    });

    _connectivity.onConnectivityChanged.listen((result) {
      _connection = result;
    });

    Geolocator.getPositionStream().listen((pos) {
      _position = pos;
    });

    return _singleton!;
  }

  static const double _nativeAndroidStatusBarHeight = 24;

  static double get _platformStatusBarPadding =>
      Platform.isAndroid
          ? (statusBarHeight - _nativeAndroidStatusBarHeight) / 2
          : 0.0;

  static bool get isReleaseMode => kReleaseMode;

  static bool get isDebugMode => !isReleaseMode || kDebugMode;

  static bool get isInTestingEnv =>
      Platform.environment.containsKey('FLUTTER_TEST');

  static double get statusBarHeight =>
      ui.PlatformDispatcher.instance.views.first.padding.top /
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  static double get navigationBarHeight =>
      ui.PlatformDispatcher.instance.views.first.padding.bottom /
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  static double get appBarHeight => kToolbarHeight - _platformStatusBarPadding;

  /// Listen to connectivity changes as a stream using connectivity_plus.
  ///
  /// Example usage:
  ///   Environment.instance.onConnectivityChanged().listen((ConnectivityResult result) { ... });
  Stream<List<ConnectivityResult>> onConnectivityChanged() {
    return _connectivity.onConnectivityChanged;
  }

  /// region: Internal helper to check and request location permission.
  /// Throws [PermissionDeniedException] if permission is denied.
  static Future<void> _ensureLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw PermissionDeniedException('Location permission denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw PermissionDeniedException('Location permission permanently denied');
    }
  }

  /// Listen to the device's position changes as a stream using geolocator.
  ///
  /// Example usage:
  ///   Environment.instance.onPositionChanged().listen((Position position) { ... });
  Stream<Position> onPositionChanged({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async* {
    await _ensureLocationPermission();
    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(accuracy: accuracy),
    );
  }

  /// Get the current battery level as a percentage (0-100).
  /// Example usage:
  ///   final level = await Environment.instance.getBatteryLevel();
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  /// Listen to battery state changes (charging, discharging, full, unknown).
  /// Example usage:
  ///   Environment.instance.onBatteryStateChanged().listen((BatteryState state) { ... });
  Stream<BatteryState> onBatteryStateChanged() {
    return _battery.onBatteryStateChanged;
  }

  factory Environment.fromJson(Map<String, Object?> json) =>
      _$EnvironmentFromJson(json);
}
