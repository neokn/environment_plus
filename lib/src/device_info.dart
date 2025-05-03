import 'dart:io';

import 'package:android_id/android_id.dart' show AndroidId;
import 'package:device_info_plus/device_info_plus.dart'
    show AndroidDeviceInfo, DeviceInfoPlugin, IosDeviceInfo;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_info.freezed.dart';
part 'device_info.g.dart';

@freezed
abstract class DeviceInfo with _$DeviceInfo {
  static DeviceInfo? _singleton;

  factory DeviceInfo() {
    if (_singleton == null) {
      throw Exception("Please run `await DeviceInfo.init()` first");
    }
    return _singleton!;
  }

  @visibleForTesting
  factory DeviceInfo.initFake({
    String brand = '',
    String? deviceId = '',
    bool isPhysicalDevice = false,
    String machineModel = '',
    String osVersionName = '',
    int osVersionNumber = 0,
    bool support64bit = false,
    bool support32bit = false,
    Map<String, dynamic> rawInfo = const {},
  }) =>
      _singleton ??= DeviceInfo._(
        brand: brand,
        deviceId: deviceId,
        isPhysicalDevice: isPhysicalDevice,
        machineModel: machineModel,
        osVersionName: osVersionName,
        osVersionNumber: osVersionNumber,
        support64bit: support64bit,
        support32bit: support32bit,
        rawInfo: rawInfo,
      );

  const factory DeviceInfo._({
    required String brand,
    required String? deviceId,
    required bool isPhysicalDevice,
    required String machineModel,
    required String osVersionName,
    required int osVersionNumber,
    required bool support64bit,
    required bool support32bit,
    required Map<String, dynamic> rawInfo,
  }) = _DeviceInfo;

  static Future<DeviceInfo> init() async {
    if (_singleton != null) {
      return _singleton!;
    }

    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await Future.wait([
        deviceInfoPlugin.androidInfo,
        AndroidId().getId(),
      ]);
      final androidDeviceInfo = info[0] as AndroidDeviceInfo;
      final androidId = info[1] as String;
      final rawInfo = _readAndroidDeviceInfoData(androidDeviceInfo);
      rawInfo.addAll(<String, dynamic>{'AndroidId.id': androidId});

      _singleton = DeviceInfo._(
        brand: androidDeviceInfo.brand,
        deviceId: androidId,
        isPhysicalDevice: androidDeviceInfo.isPhysicalDevice,
        machineModel: androidDeviceInfo.model,
        osVersionName: androidDeviceInfo.version.release,
        osVersionNumber: androidDeviceInfo.version.sdkInt,
        support64bit: androidDeviceInfo.supported64BitAbis.isNotEmpty,
        support32bit: androidDeviceInfo.supported32BitAbis.isNotEmpty,
        rawInfo: rawInfo,
      );
    }
    if (Platform.isIOS) {
      final info = await deviceInfoPlugin.iosInfo;
      _singleton = DeviceInfo._(
        brand: 'apple',
        deviceId: info.identifierForVendor,
        isPhysicalDevice: info.isPhysicalDevice,
        machineModel: info.utsname.machine,
        osVersionName: info.systemVersion,
        osVersionNumber: int.parse(info.systemVersion.split('.').first),
        support64bit: int.parse(info.systemVersion.split('.').first) >= 7,
        support32bit: int.parse(info.systemVersion.split('.').first) < 11,
        rawInfo: _readIosDeviceInfoData(info),
      );
    }
    return _singleton!;
  }

  static Map<String, dynamic> _readAndroidDeviceInfoData(
    AndroidDeviceInfo info,
  ) {
    return <String, dynamic>{
      'AndroidDeviceInfo.version.securityPatch': info.version.securityPatch,
      'AndroidDeviceInfo.version.sdkInt': info.version.sdkInt,
      'AndroidDeviceInfo.version.release': info.version.release,
      'AndroidDeviceInfo.version.previewSdkInt': info.version.previewSdkInt,
      'AndroidDeviceInfo.version.incremental': info.version.incremental,
      'AndroidDeviceInfo.version.codename': info.version.codename,
      'AndroidDeviceInfo.version.baseOS': info.version.baseOS,
      'AndroidDeviceInfo.board': info.board,
      'AndroidDeviceInfo.bootloader': info.bootloader,
      'AndroidDeviceInfo.brand': info.brand,
      'AndroidDeviceInfo.device': info.device,
      'AndroidDeviceInfo.display': info.display,
      'AndroidDeviceInfo.fingerprint': info.fingerprint,
      'AndroidDeviceInfo.hardware': info.hardware,
      'AndroidDeviceInfo.host': info.host,
      'AndroidDeviceInfo.id': info.id,
      'AndroidDeviceInfo.manufacturer': info.manufacturer,
      'AndroidDeviceInfo.model': info.model,
      'AndroidDeviceInfo.product': info.product,
      'AndroidDeviceInfo.supported32BitAbis': info.supported32BitAbis,
      'AndroidDeviceInfo.supported64BitAbis': info.supported64BitAbis,
      'AndroidDeviceInfo.supportedAbis': info.supportedAbis,
      'AndroidDeviceInfo.tags': info.tags,
      'AndroidDeviceInfo.type': info.type,
      'AndroidDeviceInfo.isPhysicalDevice': info.isPhysicalDevice,
      'AndroidDeviceInfo.systemFeatures': info.systemFeatures,
    };
  }

  static Map<String, dynamic> _readIosDeviceInfoData(IosDeviceInfo info) {
    return <String, dynamic>{
      'IosDeviceInfo.name': info.name,
      'IosDeviceInfo.systemName': info.systemName,
      'IosDeviceInfo.systemVersion': info.systemVersion,
      'IosDeviceInfo.model': info.model,
      'IosDeviceInfo.localizedModel': info.localizedModel,
      'IosDeviceInfo.identifierForVendor': info.identifierForVendor,
      'IosDeviceInfo.isPhysicalDevice': info.isPhysicalDevice,
      'IosDeviceInfo.utsname.sysname:': info.utsname.sysname,
      'IosDeviceInfo.utsname.nodename:': info.utsname.nodename,
      'IosDeviceInfo.utsname.release:': info.utsname.release,
      'IosDeviceInfo.utsname.version:': info.utsname.version,
      'IosDeviceInfo.utsname.machine:': info.utsname.machine,
    };
  }

  factory DeviceInfo.fromJson(Map<String, Object?> json) =>
      _$DeviceInfoFromJson(json);
}
