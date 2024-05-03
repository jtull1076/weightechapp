import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'dart:core';
import 'dart:ui';

class AppInfo {
  static late PackageInfo packageInfo;
  AppInfo();
  
  Future<void> init() async {
    packageInfo = await PackageInfo.fromPlatform();
  }
}

class Log {
  static late Logger logger;
  Log();

  Future<void> init() async {
    Directory appDocsDir = await getApplicationDocumentsDirectory();
    logger = Logger(
      filter: AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        lineLength: 120,
        printTime: true,
        colors: true, 
        printEmojis: true
      ),
      output: FileOutput(
        file: File("${appDocsDir.path}/app-${DateTime.now().toIso8601String().replaceAll(":", "-")}.log"),
      )
    );
  }
}

class AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.value >= Level.debug.value) {
      return true;
    }
    else {
      return false;
    }
  }
}