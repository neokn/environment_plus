import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:slugid/slugid.dart';
import 'package:manifest_info_reader/manifest_info_reader.dart'
    show ManifestInfoReader;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

import 'app_info.dart';
import 'device_info.dart';

class Environment {
  final AppInfo appInfo;

  final DeviceInfo deviceInfo;

  final Map<String, dynamic> rawInfo;

  final bool isAndroid;

  final bool isIOS;

  final String session;

  String? get flavor => rawInfo['manifest.info.flavor'] as String?;

  BatteryState get batteryState => _batteryState;

  Position? get position {
    if (_position == null) {
      _logger.warning('Position is null maybe permission is denied');
    }
    return _position;
  }

  List<ConnectivityResult> get connection => _connection;

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
  // endregion

  Environment._(
    this.appInfo,
    this.deviceInfo,
    this.session,
    Map<String, dynamic> rawInfo, {
    bool? isAndroid,
    bool? isIOS,
  }) : rawInfo = Map.unmodifiable(rawInfo),
       isAndroid = isAndroid ?? Platform.isAndroid,
       isIOS = isIOS ?? Platform.isIOS;

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
    ]);

    var appInfo = results[0] as AppInfo;
    var deviceInfo = results[1] as DeviceInfo;

    _rawInfo.addAll(appInfo.rawInfo);
    _rawInfo.addAll(deviceInfo.rawInfo);
    _rawInfo.addEntries(results[2] as Iterable<MapEntry<String, dynamic>>);

    _connection = results[3] as List<ConnectivityResult>;
    _batteryState = results[4] as BatteryState;
    _position = results[5] as Position?;

    _singleton = Environment._(
      appInfo,
      deviceInfo,
      Slugid.nice().toString(),
      _rawInfo,
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

  @visibleForTesting
  static Environment initFake({
    AppInfo? appInfo,
    DeviceInfo? deviceInfo,
    bool? isAndroid,
    bool? isIOS,
    Map<String, dynamic>? rawInfo,
  }) {
    _singleton = Environment._(
      appInfo ?? AppInfo.empty(),
      deviceInfo ?? DeviceInfo.empty(),
      Slugid.nice().toString(),
      (rawInfo
            ?..addAll(appInfo?.rawInfo ?? {})
            ..addAll(deviceInfo?.rawInfo ?? {})) ??
          <String, dynamic>{},
      isAndroid: isAndroid,
      isIOS: isIOS,
    );

    return _singleton!;
  }

  static const double _nativeAndroidStatusBarHeight = 24;

  double get _platformStatusBarPadding =>
      isAndroid ? (statusBarHeight - _nativeAndroidStatusBarHeight) / 2 : 0.0;

  bool get isReleaseMode => kReleaseMode;

  bool get isDebugMode => !isReleaseMode;

  bool get isInTestingEnv => Platform.environment.containsKey('FLUTTER_TEST');

  double get statusBarHeight =>
      ui.PlatformDispatcher.instance.views.first.padding.top /
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  double get navigationBarHeight =>
      ui.PlatformDispatcher.instance.views.first.padding.bottom /
      ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  double get appBarHeight => kToolbarHeight - _platformStatusBarPadding;

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
}
