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

  static int versionCompare(String newVersion, String currentVersion){
    List<String> currentV = currentVersion.split(".");
    List<String> newV = newVersion.split(".");
    bool deprecated = false;
    bool development = false;
    for (var i = 0 ; i <= 2; i++){
      deprecated = int.parse(newV[i]) > int.parse(currentV[i]);
      development = int.parse(newV[i]) < int.parse(currentV[i]);
      if(int.parse(newV[i]) != int.parse(currentV[i])) break;
    }
    if (deprecated) {
      return 1;
    }
    else if (development) {
      return 2;
    }
    else {
      return 0;
    }
  }
}

class Log {
  static late Logger logger;
  Log();

  Future<void> init() async {
    Directory appDocsDir = await getApplicationSupportDirectory();
    logger = Logger(
      filter: AppLogFilter(),
      printer: AppLogPrinter(),
      output: FileOutput(
        file: File("${appDocsDir.path}/app-${DateTime.now().toIso8601String().replaceAll(":", "-")}.log"),
      )
    );
  }
}

class AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (event.level.value >= Level.debug.value || event.level.name == "trace") {
      return true;
    }
    else {
      return false;
    }
  }
}

class AppLogPrinter extends PrettyPrinter {
  AppLogPrinter() 
  : super(
    excludeBox: {Level.info : true},
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 120,
    colors: true, 
    printEmojis: true
  );
}