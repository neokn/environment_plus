import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;

class AppInfo {
  /// Name of the application
  final String appName;

  /// Application identifier (package name)
  final String appId;

  /// Application version name
  final String buildName;

  /// Application version code
  final String buildNumber;

  /// Raw application data
  final Map<String, dynamic> rawInfo;

  static AppInfo? _instance;

  /// Creates a new AppInfo instance
  AppInfo._({
    required this.appName,
    required this.appId,
    required this.buildName,
    required this.buildNumber,
    required this.rawInfo,
  });

  factory AppInfo.fromPlatform() {
    if (_instance == null) {
      throw "Please run `await AppInfo.init()` first";
    }
    return _instance!;
  }

  static Future<AppInfo> init() async {
    if (_instance != null) {
      return _instance!;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfo._(
      appName: packageInfo.appName,
      appId: packageInfo.packageName,
      buildName: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      rawInfo: _readPackageInfoData(packageInfo),
    );
  }

  static Map<String, dynamic> _readPackageInfoData(PackageInfo info) {
    return <String, dynamic>{
      'PackageInfo.version': info.version,
      'PackageInfo.buildNumber': info.buildNumber,
      'PackageInfo.packageName': info.packageName,
      'PackageInfo.appName': info.appName,
    };
  }

  /// Creates an AppInfo with default values
  AppInfo.empty()
    : appName = '',
      appId = '',
      buildName = '',
      buildNumber = '',
      rawInfo = const <String, dynamic>{};

  /// Creates a copy of this AppInfo with the given fields replaced
  AppInfo copyWith({
    String? appName,
    String? appId,
    String? buildName,
    String? buildNumber,
    Map<String, dynamic>? rawInfo,
  }) {
    return AppInfo._(
      appName: appName ?? this.appName,
      appId: appId ?? this.appId,
      buildName: buildName ?? this.buildName,
      buildNumber: buildNumber ?? this.buildNumber,
      rawInfo: rawInfo ?? this.rawInfo,
    );
  }
}
