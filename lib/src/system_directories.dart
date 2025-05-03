import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

part 'system_directories.freezed.dart';
part 'system_directories.g.dart';

@freezed
abstract class SystemDirectories with _$SystemDirectories {
  static SystemDirectories? _singleton;
  static final Logger _logger = Logger('SystemDirectories');
  static final Directory emptyDirectory = Directory('');

  const SystemDirectories._();

  factory SystemDirectories() {
    if (_singleton == null) {
      throw "Please run `await SystemDirectories.init()` first";
    }
    return _singleton!;
  }

  @visibleForTesting
  factory SystemDirectories.initFake({
    Directory? temporaryDirectory,
    Directory? applicationSupportDirectory,
    Directory? applicationDocumentsDirectory,
    Directory? applicationCacheDirectory,
    Directory? downloadsDirectory,
  }) =>
      _singleton ??= SystemDirectories._freezed(
        temporaryDirectory: temporaryDirectory ?? emptyDirectory,
        applicationSupportDirectory:
            applicationSupportDirectory ?? emptyDirectory,
        applicationDocumentsDirectory:
            applicationDocumentsDirectory ?? emptyDirectory,
        applicationCacheDirectory: applicationCacheDirectory ?? emptyDirectory,
        downloadsDirectory: downloadsDirectory,
      );

  const factory SystemDirectories._freezed({
    @DirectoryConverter() required Directory temporaryDirectory,
    @DirectoryConverter() required Directory applicationSupportDirectory,
    @DirectoryConverter() required Directory applicationDocumentsDirectory,
    @DirectoryConverter() required Directory applicationCacheDirectory,
    @DirectoryConverter() required Directory? downloadsDirectory,
  }) = _SystemDirectories;

  File getTemporaryFile(String filename) =>
      File('${temporaryDirectory.path}/$filename');
  File getApplicationSupportFile(String filename) =>
      File('${applicationSupportDirectory.path}/$filename');
  File getApplicationDocumentsFile(String filename) =>
      File('${applicationDocumentsDirectory.path}/$filename');
  File getApplicationCacheFile(String filename) =>
      File('${applicationCacheDirectory.path}/$filename');
  File? getDownloadsFile(String filename) =>
      downloadsDirectory != null
          ? File('${downloadsDirectory!.path}/$filename')
          : null;

  static Future<SystemDirectories> init() async {
    if (_singleton != null) {
      return _singleton!;
    }
    final results = await Future.wait([
      getTemporaryDirectory(),
      getApplicationSupportDirectory(),
      getApplicationDocumentsDirectory(),
      getDownloadsDirectory().catchError((e, st) {
        _logger.warning('Failed to get downloads directory', e, st);
        return null;
      }),
    ]);
    _singleton = SystemDirectories._freezed(
      temporaryDirectory: results[0] as Directory,
      applicationSupportDirectory: results[1] as Directory,
      applicationDocumentsDirectory: results[2] as Directory,
      applicationCacheDirectory: results[0] as Directory,
      downloadsDirectory: results[3] != null ? results[3] as Directory : null,
    );
    return _singleton!;
  }

  factory SystemDirectories.fromJson(Map<String, Object?> json) =>
      _$SystemDirectoriesFromJson(json);
}

// Custom converter for your component
class DirectoryConverter
    implements JsonConverter<Directory, Map<String, dynamic>> {
  const DirectoryConverter();

  @override
  Directory fromJson(Map<String, dynamic> json) {
    return Directory(json['path'] as String);
  }

  @override
  Map<String, dynamic> toJson(Directory object) {
    return {'path': object.path};
  }
}
