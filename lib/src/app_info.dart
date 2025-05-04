import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;

part 'app_info.freezed.dart';
part 'app_info.g.dart';

@freezed
abstract class AppInfo with _$AppInfo {
  static AppInfo? _singleton;

  factory AppInfo() {
    if (_singleton == null) {
      throw Exception("Please run `await AppInfo.init()` first");
    }
    return _singleton!;
  }

  @visibleForTesting
  factory AppInfo.initFake({
    String appName = '',
    String appId = '',
    String buildName = '',
    String buildNumber = '',
    Map<String, dynamic> rawInfo = const {},
  }) =>
      _singleton ??= AppInfo._(
        appName: appName,
        appId: appId,
        buildName: buildName,
        buildNumber: buildNumber,
        rawInfo: rawInfo,
      );

  const factory AppInfo._({
    required String appName,
    required String appId,
    required String buildName,
    required String buildNumber,
    required Map<String, dynamic> rawInfo,
  }) = _AppInfo;

  static Future<AppInfo> init() async {
    if (_singleton != null) {
      return _singleton!;
    }
    final packageInfo = await PackageInfo.fromPlatform();
    _singleton = AppInfo._(
      appName: packageInfo.appName,
      appId: packageInfo.packageName,
      buildName: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      rawInfo: _readPackageInfoData(packageInfo),
    );
    return _singleton!;
  }

  static Map<String, dynamic> _readPackageInfoData(PackageInfo info) {
    return <String, dynamic>{
      'PackageInfo.version': info.version,
      'PackageInfo.buildNumber': info.buildNumber,
      'PackageInfo.packageName': info.packageName,
      'PackageInfo.appName': info.appName,
    };
  }

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      _$AppInfoFromJson(json);
}
