import 'dart:async';

import 'package:environment_plus/environment_plus.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.init();
  final environment = Environment();
  runApp(MyApp(environment: environment));
}

class MyApp extends StatefulWidget {
  final Environment environment;
  const MyApp({super.key, required this.environment});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Position? _currentPosition;
  String _connection = '';
  int? _batteryLevel;
  BatteryState? _batteryState;
  StreamSubscription<BatteryState>? _batterySub;

  @override
  void initState() {
    super.initState();
    // 監聽定位變化
    _positionSub = widget.environment.onPositionChanged().listen((pos) {
      setState(() {
        _currentPosition = pos;
      });
    });

    _connectivitySub = widget.environment.onConnectivityChanged().listen((
      result,
    ) {
      setState(() {
        _connection = result.join(', ');
      });
    });

    widget.environment.getBatteryLevel().then((level) {
      setState(() {
        _batteryLevel = level;
      });
    });

    _batterySub = widget.environment.onBatteryStateChanged().listen((
      state,
    ) async {
      setState(() {
        _batteryState = state;
      });

      final level = await widget.environment.getBatteryLevel();
      setState(() {
        _batteryLevel = level;
      });
    });

    // 初始化 system directories
    _initSystemDirectories();
  }

  void _initSystemDirectories() {
    final directories = widget.environment.systemDirectories;
    // 創建臨時文件
    final tempFile = directories.getTemporaryFile('temp.txt');
    tempFile.writeAsStringSync('This is a temporary file');

    // 創建應用支持文件
    final supportFile = directories.getApplicationSupportFile('support.txt');
    supportFile.writeAsStringSync('This is a support file');

    // 創建應用文檔文件
    final docFile = directories.getApplicationDocumentsFile('document.txt');
    docFile.writeAsStringSync('This is a document file');

    // 創建應用緩存文件
    final cacheFile = directories.getApplicationCacheFile('cache.txt');
    cacheFile.writeAsStringSync('This is a cache file');

    // 創建下載文件（如果可用）
    final downloadFile = directories.getDownloadsFile('download.txt');
    if (downloadFile != null) {
      downloadFile.writeAsStringSync('This is a download file');
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _connectivitySub?.cancel();
    _batterySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final env = widget.environment;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('environment_plus Example')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Device Model: ${env.deviceInfo.machineModel}'),
              Text('OS Version: ${env.deviceInfo.osVersionName}'),
              Text('App Name: ${env.appInfo.appName}'),
              Text('Version: ${env.appInfo.buildName}'),
              Text('Is Debug Mode: ${Environment.isDebugMode}'),
              Text('Is Physical Device: ${env.deviceInfo.isPhysicalDevice}'),
              Text('Flavor: ${env.flavor ?? 'unknown'}'),
              const Divider(),
              Text('Current Position:'),
              Text(
                _currentPosition == null
                    ? 'Unknown'
                    : '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
              ),
              const Divider(),
              Text('Connectivity:'),
              Text(_connection.isEmpty ? 'Unknown' : _connection),
              const Divider(),
              Text('Battery Level: ${_batteryLevel?.toString() ?? 'Unknown'}%'),
              Text('Battery State: ${_batteryState?.toString() ?? 'Unknown'}'),
              const Divider(),
              const Text('System Directories:'),
              Text(
                'Temporary Directory: ${env.systemDirectories.temporaryDirectory.path}',
              ),
              Text(
                'Application Support Directory: ${env.systemDirectories.applicationSupportDirectory.path}',
              ),
              Text(
                'Application Documents Directory: ${env.systemDirectories.applicationDocumentsDirectory.path}',
              ),
              Text(
                'Application Cache Directory: ${env.systemDirectories.applicationCacheDirectory.path}',
              ),
              if (env.systemDirectories.downloadsDirectory != null)
                Text(
                  'Downloads Directory: ${env.systemDirectories.downloadsDirectory!.path}',
                ),
            ],
          ),
        ),
      ),
    );
  }
}
